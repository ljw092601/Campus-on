"""Guide translation tooling (Chinese / Vietnamese).

Korean and English live in the Dart catalogue. A translation is a flat JSON
file per language — guide id -> field path -> text — so translators never touch
Dart and two translators never touch the same file.

    python tool/i18n/i18n_tool.py source     # write tool/i18n/source/<id>.json
    python tool/i18n/i18n_tool.py validate   # check guides_zh.json / guides_vi.json
    python tool/i18n/i18n_tool.py gen        # -> lib/data/i18n/guide_translations.g.dart
    python tool/i18n/i18n_tool.py status     # per-guide progress

Run from _workspace/02_app_code. `source` reads the exported seed
(tool/firestore_seed/guide_items.seed.json), which is generated from the
catalogue, so the source text is always what the app actually ships.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APP = os.path.join(ROOT, '02_app_code') if os.path.basename(ROOT) != '02_app_code' else ROOT
SEED = os.path.join(APP, 'tool', 'firestore_seed', 'guide_items.seed.json')
SRC_DIR = os.path.join(APP, 'tool', 'i18n', 'source')
OUT_DART = os.path.join(APP, 'lib', 'data', 'i18n', 'guide_translations.g.dart')
LANGS = ('zh', 'vi')


def worker_file(lang):
    return os.path.join(APP, 'lib', 'data', 'i18n', f'guides_{lang}.json')


# field key in the seed doc -> translation path, for the guide itself
ITEM_FIELDS = {
    'title_ko': 'title',
    'detail_title_ko': 'detail_title',
    'summary_ko': 'summary',
    'overview_ko': 'overview',
    'checklist_title_ko': 'checklist_title',
    'checklist_ko': 'checklist',
    'checklist_optional_title_ko': 'checklist_optional_title',
    'checklist_optional_ko': 'checklist_optional',
    'checklist_note_ko': 'checklist_note',
    'steps_ko': 'steps',
    'tips_ko': 'tips',
    'search_aliases_ko': 'search_aliases',
}
SECTION_FIELDS = {
    'title_ko': 'title',
    'body_ko': 'body',
    'steps_ko': 'steps',
    'notice_ko': 'notice',
    'footnote_ko': 'footnote',
}
NOTE_FIELDS = {'title_ko': 'title', 'lines_ko': 'lines'}
LINK_FIELDS = {'label_ko': 'label', 'description_ko': 'description'}


def _en_key(ko_key):
    return ko_key[:-3] + '_en'


def _pairs(doc, fields, prefix=''):
    """[(path, ko, en)] for one object."""
    out = []
    for ko_key, name in fields.items():
        ko = doc.get(ko_key)
        if ko in (None, '', []):
            continue
        out.append((prefix + name, ko, doc.get(_en_key(ko_key))))
    return out


def source_entries(doc):
    """Every translatable path of one guide, in reading order."""
    out = _pairs(doc, ITEM_FIELDS)
    # The duration chip lives under meta in the seed shape.
    meta = doc.get('meta') or {}
    if meta.get('durationText_ko'):
        out.append(('duration', meta['durationText_ko'], meta.get('durationText_en')))
    for coll in ('top_sections', 'sections'):
        for i, s in enumerate(doc.get(coll) or []):
            p = f'{coll}[{i}].'
            out += _pairs(s, SECTION_FIELDS, p)
            for j, n in enumerate(s.get('notes') or []):
                out += _pairs(n, NOTE_FIELDS, f'{p}notes[{j}].')
            for j, l in enumerate(s.get('links') or []):
                out += _pairs(l, LINK_FIELDS, f'{p}links[{j}].')
    for i, l in enumerate(doc.get('links') or []):
        out += _pairs(l, LINK_FIELDS, f'links[{i}].')
    for i, p in enumerate(doc.get('phrases') or []):
        # The Korean sentence stays on screen; only its meaning is translated.
        out.append((f'phrases[{i}].text', p.get('ko', ''), p.get('en', '')))
    return out


def load_seed():
    with open(SEED, encoding='utf-8') as f:
        return json.load(f)


def cmd_source():
    seed = load_seed()
    os.makedirs(SRC_DIR, exist_ok=True)
    index = []
    for gid, doc in seed.items():
        entries = source_entries(doc)
        payload = {
            'id': gid,
            'category': doc.get('categoryId'),
            'note': 'Translate every "ko" value. Keep list lengths, numbers, '
                    'deadlines, conditions, phone numbers and URLs exactly. '
                    '"en" is a reference translation, not the source of truth.',
            'fields': {
                path: ({'ko': ko, 'en': en} if not isinstance(ko, list)
                       else {'ko': ko, 'en': en, 'count': len(ko)})
                for path, ko, en in entries
            },
        }
        with open(os.path.join(SRC_DIR, f'{gid}.json'), 'w', encoding='utf-8') as f:
            json.dump(payload, f, ensure_ascii=False, indent=1)
        index.append({'id': gid, 'category': doc.get('categoryId'),
                      'title_ko': doc.get('title_ko'), 'fields': len(entries)})
    with open(os.path.join(SRC_DIR, '_index.json'), 'w', encoding='utf-8') as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
    print(f'wrote {len(index)} source files to tool/i18n/source/')
    print('total translatable fields:', sum(i['fields'] for i in index))


NUM = re.compile(r'\d[\d,.]*')
URL = re.compile(r'(?:https?://[^\s)\'"]+|tel:[\d+\-]+|/guide/item/[a-z0-9-]+)')


def _digits(s):
    return re.sub(r'[^0-9]', '', s)


# A number may be written with its units spelled out in Korean or Chinese —
# 3만5천원, 6천만원, 1억 3,500만원, 1000万韩元 — while the other language writes the
# same value in plain digits. So compare values, not digit strings: a source
# 35,000 must match a translated 35.000 but not 350,000.
#
# 조/兆 is deliberately absent: no amount in these guides reaches it, and
# treating it as a multiplier turned the law article 「제46조」 into 46 × 10¹²
# (감사 05/035 SF-3).
SMALL = {'천': 10 ** 3, '백': 10 ** 2, '십': 10,
         '千': 10 ** 3, '百': 10 ** 2, '十': 10}
BIG = {'만': 10 ** 4, '억': 10 ** 8,
       '万': 10 ** 4, '亿': 10 ** 8}

# 35,000 and 10.000.000 group thousands; 1.5 and 2,0 are decimals. Two or more
# three-digit groups can only be grouping. One group of three is ambiguous —
# 3.500 is three and a half thousand in Korean and three-point-five-hundred
# nowhere, but 0.375 is a fraction — so both readings are accepted for it rather
# than silently choosing one (감사 05/036 NIT-4).
# NUM has no space in its class, so a space-separated group never reaches here.
GROUPED = re.compile(r'^\d{1,3}([.,]\d{3}){2,}$')
AMBIGUOUS = re.compile(r'^(\d{1,3})[.,](\d{3})$')
DECIMAL = re.compile(r'^\d+[.,]\d{1,2}$')


# An amount unit right after a number settles the reading: 3.500원 is three and
# a half thousand won, never 3.5 (B 03/057).
MONEY = re.compile(r'^\s{0,2}(원|won|WON|韓元|元|đồng|VND|USD|＄|\$|₩)', re.I)


def _values_of(token, money=False):
    """Every value a written number may stand for (usually one).

    A single three-digit group is ambiguous — 3.500 is 3500 in Korean and 3.5 in
    English — so both readings are kept, unless the notation decides it:
      * a leading zero means a fraction (0.375 is never 375), and
      * an amount unit right after means digit grouping (3.500원 is 3500).
    """
    # NUM swallows a trailing separator in 「IELTS 5.5, CEFR B2」; leaving it on
    # would read 5.5 as 55.
    t = token.strip().strip('.,')
    if GROUPED.match(t):
        return {float(re.sub(r'[^0-9]', '', t))}
    m = AMBIGUOUS.match(t)
    if m:
        grouped = float(m.group(1) + m.group(2))
        decimal = float(f'{m.group(1)}.{m.group(2)}')
        if m.group(1).startswith('0'):
            return {decimal}
        if money:
            return {grouped}
        return {grouped, decimal}
    if DECIMAL.match(t):
        whole, frac = re.split(r'[.,]', t)
        return {float(f'{whole}.{frac}')}
    d = re.sub(r'[^0-9]', '', t)
    return {float(d)} if d else set()


def _value(token, money=False):
    """The single value a written number stands for, or None if unclear."""
    vs = _values_of(token, money=money)
    return min(vs) if len(vs) == 1 else (max(vs) if vs else None)


def _number_exprs(text):
    """Every number expression in [text] as (written form, possible values).

    A number with a unit contributes only what it adds up to: 1,600만원 is
    16,000,000 and not also 1,600, so a translation that keeps the digits but
    drops the unit no longer passes. A bare number contributes its own value,
    and a leading zero is written or dropped freely (2025-06-01 vs 6월 1일).
    """
    out = []
    i = 0
    while i < len(text):
        m = NUM.match(text, i)
        if not m:
            i += 1
            continue
        total = section = 0.0
        raw = set()
        united = False
        end = m.end()
        while True:
            readings = _values_of(
                m.group(), money=bool(MONEY.match(text[m.end():m.end() + 6])))
            if not readings:
                break
            v = max(readings)
            raw |= readings
            j = m.end()
            unit = text[j:j + 1]
            chained = False
            if unit in SMALL:
                section += v * SMALL[unit]
                j += 1
                united = True
                # 6천만원: a big unit right after scales the whole section.
                if text[j:j + 1] in BIG:
                    total += section * BIG[text[j]]
                    section = 0.0
                    j += 1
                chained = True
            elif unit in BIG:
                total += (section + v) * BIG[unit]
                section = 0.0
                j += 1
                united = True
                chained = True
            else:
                section += v
            end = j
            if not chained:
                break
            # 1억 3,500만원: the next part may follow a single space.
            nxt = NUM.match(text, j)
            if nxt is None and text[j:j + 1] == ' ':
                nxt = NUM.match(text, j + 1)
            if nxt is None:
                break
            m = nxt
        total += section
        if united:
            values = {total}
        else:
            values = raw | {total}
            # 06 and 6 are the same month.
            values |= {float(int(v)) for v in raw if v == int(v)}
        out.append((text[i:end], values))
        i = max(end, i + 1)
    return out


def _num_values(text):
    """Every value the numbers in [text] express, units included."""
    out = set()
    for _, vals in _number_exprs(text):
        out |= vals
    return out


def _texts(v):
    return v if isinstance(v, list) else [v]


# A question mark wedged inside a word is not punctuation: it is what is left
# when text that carried diacritics went through something that could not hold
# them. Vietnamese loses the most this way (`ứng phó khẩn cấp` → `?ng ph? kh?n
# c?p`), and the result is unreadable rather than merely wrong, so it is an
# error and not a warning.
MOJIBAKE = re.compile(r'[A-Za-zÀ-ỹ]\?|\?[A-Za-zÀ-ỹ]')


def mojibake_hits(value):
    if isinstance(value, str):
        return len(MOJIBAKE.findall(value))
    if isinstance(value, list):
        return sum(mojibake_hits(v) for v in value)
    if isinstance(value, dict):
        return sum(mojibake_hits(v) for v in value.values())
    return 0


def validate_lang(lang, seed, strict_numbers=True):
    path = worker_file(lang)
    if not os.path.exists(path):
        return [f'{lang}: missing {path}'], {}
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    errs = []
    done = {}
    for gid, fields in data.items():
        if gid not in seed:
            errs.append(f'{lang}: unknown guide id "{gid}"')
            continue
        src = {p: (ko, en) for p, ko, en in source_entries(seed[gid])}
        for p, val in fields.items():
            if p not in src:
                errs.append(f'{lang}/{gid}: unknown field path "{p}"')
                continue
            ko = src[p][0]
            if isinstance(ko, list) != isinstance(val, list):
                errs.append(f'{lang}/{gid}/{p}: expected '
                            f'{"list" if isinstance(ko, list) else "string"}')
                continue
            if isinstance(ko, list) and len(ko) != len(val):
                errs.append(f'{lang}/{gid}/{p}: {len(val)} items, source has {len(ko)}')
                continue
            for a, b in zip(_texts(ko), _texts(val)):
                if not isinstance(b, str) or not b.strip():
                    errs.append(f'{lang}/{gid}/{p}: empty translation')
                    continue
                for u in set(URL.findall(a)):
                    if u not in b:
                        errs.append(f'{lang}/{gid}/{p}: url/phone "{u}" missing')
                if strict_numbers:
                    # Compare values, not digit substrings: a translation may
                    # write 35.000 or 35 000 for a source 35,000 (the separator
                    # style is the target language's own), and 100만원 may become
                    # 1.000.000 won. But a source 35,000 must not pass as
                    # 350,000 — one wrong digit is a wrong fee (감사 05/034 S-5).
                    have = _num_values(b)
                    miss = [w for w, vals in _number_exprs(a)
                            if vals and not (vals & have)]
                    if miss:
                        errs.append(f'{lang}/{gid}/{p}: numbers {miss} missing')
        done[gid] = len([p for p in fields if p in src])
    return errs, done


def cmd_check_encoding():
    """Text that lost its diacritics on the way into a file."""
    problems = 0
    for lang in LANGS:
        path = worker_file(lang)
        if not os.path.exists(path):
            continue
        with open(path, encoding='utf-8') as f:
            data = json.load(f)
        hits = {gid: mojibake_hits(fields) for gid, fields in data.items()}
        bad = {gid: n for gid, n in hits.items() if n >= 5}
        for gid, n in sorted(bad.items(), key=lambda e: -e[1]):
            print(f'--- {lang}/{gid}: {n} question marks inside words — the '
                  f'text lost its diacritics somewhere between the translator '
                  f'and the file')
        problems += len(bad)
        print(f'--- {lang}: {len(bad)} guides look damaged')
    return 1 if problems else 0


def cmd_validate(strict_numbers=True):
    seed = load_seed()
    bad = 0
    for lang in LANGS:
        errs, done = validate_lang(lang, seed, strict_numbers)
        print(f'--- {lang}: {len(done)} guides with translations, {len(errs)} problems')
        for e in errs[:60]:
            print('   ', e)
        bad += len(errs)
    return 1 if bad else 0


def _nest(flat):
    """Flat 'sections[1].notes[0].lines' paths -> nested tree."""
    tree = {}
    for path, val in flat.items():
        node = tree
        parts = path.split('.')
        for k, part in enumerate(parts):
            m = re.fullmatch(r'([a-z_]+)\[(\d+)\]', part)
            last = k == len(parts) - 1
            if m:
                name, idx = m.group(1), int(m.group(2))
                lst = node.setdefault(name, [])
                while len(lst) <= idx:
                    lst.append({})
                node = lst[idx]
            elif last:
                node[part] = val
            else:
                node = node.setdefault(part, {})
    return tree


def _dart(v, indent):
    pad = ' ' * indent
    if isinstance(v, str):
        return "'" + v.replace('\\', r'\\').replace("'", r"\'").replace('$', r'\$').replace('\n', r'\n') + "'"
    if isinstance(v, list):
        if not v:
            return '[]'
        inner = ',\n'.join(pad + '  ' + _dart(x, indent + 2) for x in v)
        return '[\n' + inner + ',\n' + pad + ']'
    if isinstance(v, dict):
        if not v:
            return '{}'
        inner = ',\n'.join(f"{pad}  '{k}': {_dart(x, indent + 2)}" for k, x in v.items())
        return '{\n' + inner + ',\n' + pad + '}'
    raise TypeError(type(v))


def cmd_check():
    """Generated Dart must match the translation JSON (no stale overlay)."""
    on_disk = open(OUT_DART, encoding='utf-8').read() if os.path.exists(OUT_DART) else ''
    rc = cmd_gen(write=False)
    if rc:
        return rc
    fresh = cmd_gen.last_output
    if fresh != on_disk:
        print('guide_translations.g.dart is stale — run: python tool/i18n/i18n_tool.py gen')
        return 1
    print('guide_translations.g.dart matches the translation files')
    return 0


def cmd_gen(write=True):
    seed = load_seed()
    trees = {}
    total = {}
    for lang in LANGS:
        path = worker_file(lang)
        data = {}
        if os.path.exists(path):
            with open(path, encoding='utf-8') as f:
                data = json.load(f)
        errs, _ = validate_lang(lang, seed) if data else ([], {})
        if errs:
            print(f'refusing to generate: {lang} has {len(errs)} problems '
                  f'(run validate)')
            return 1
        trees[lang] = {gid: _nest(fields) for gid, fields in data.items()
                       if gid in seed}
        total[lang] = sum(len(v) for v in data.values())
    header = (
        '// GENERATED — do not edit by hand.\n'
        '// Source: lib/data/i18n/guides_zh.json, lib/data/i18n/guides_vi.json\n'
        '// Regenerate: python tool/i18n/i18n_tool.py gen\n'
        '//\n'
        '// Guide id → translated tree, mirroring the guide\'s shape. A guide or\n'
        '// field that is absent falls back to English, then Korean.\n\n')
    body = ''
    for lang in LANGS:
        name = 'guideTranslations' + lang.capitalize()
        body += f'const Map<String, Object?> {name} = ' + _dart(trees[lang], 0) + ';\n\n'
    body += ('const Map<String, Map<String, Object?>> guideTranslationsByLanguage = {\n'
             "  'zh': guideTranslationsZh,\n  'vi': guideTranslationsVi,\n};\n")
    cmd_gen.last_output = header + body
    if write:
        with open(OUT_DART, 'w', encoding='utf-8', newline='') as f:
            f.write(header + body)
    print(('wrote ' if write else 'generated (not written) ') + os.path.relpath(OUT_DART, APP),
          '- guides:', {l: len(trees[l]) for l in LANGS},
          'fields:', total)
    return 0


def arb_coverage():
    """(translated, total) UI string keys per language."""
    def keys(path):
        with open(path, encoding='utf-8') as f:
            d = json.load(f)
        return {k for k in d if not k.startswith('@')}
    en = keys(os.path.join(APP, 'lib', 'l10n', 'app_en.arb'))
    out = {}
    for lang in ('ko',) + LANGS:
        p = os.path.join(APP, 'lib', 'l10n', f'app_{lang}.arb')
        got = keys(p) & en if os.path.exists(p) else set()
        out[lang] = (len(got), len(en), sorted(en - got))
    return out


def cmd_status():
    seed = load_seed()
    print('UI strings (app_*.arb):')
    for lang, (got, total, missing) in arb_coverage().items():
        print(f'  {lang}: {got}/{total}' + (f'  missing e.g. {missing[:5]}' if missing else ''))
    print()
    print(f'{"guide":34} {"fields":>6} {"zh":>6} {"vi":>6}')
    data = {}
    for lang in LANGS:
        p = worker_file(lang)
        data[lang] = json.load(open(p, encoding='utf-8')) if os.path.exists(p) else {}
    tz = tv = tf = 0
    for gid, doc in seed.items():
        n = len(source_entries(doc))
        z = len(data['zh'].get(gid, {}))
        v = len(data['vi'].get(gid, {}))
        tz, tv, tf = tz + z, tv + v, tf + n
        print(f'{gid:34} {n:6} {z:6} {v:6}')
    print(f'{"TOTAL":34} {tf:6} {tz:6} {tv:6}')
    return 0



# --- academic-calendar event titles ------------------------------------------
# Same idea as the guide overlay, one field wide: the calendar's Korean and
# English names stay in the mock/Firestore document and the other languages ride
# along in an `i18n` map.

CAL_SOURCE = os.path.join(APP, 'tool', 'i18n', 'calendar_source.json')
CAL_OUT_DART = os.path.join(APP, 'lib', 'data', 'i18n', 'calendar_translations.g.dart')


def cal_worker_file(lang):
    return os.path.join(APP, 'tool', 'i18n', f'calendar_{lang}.json')


def load_calendar_source():
    with open(CAL_SOURCE, encoding='utf-8') as f:
        return json.load(f)['events']


def cmd_calendar_validate():
    """Every event translated, no stray ids, nothing blank."""
    src = load_calendar_source()
    problems = 0
    for lang in LANGS:
        path = cal_worker_file(lang)
        if not os.path.exists(path):
            print(f'--- {lang}: no file yet ({os.path.relpath(path, APP)})')
            problems += 1
            continue
        with open(path, encoding='utf-8') as f:
            titles = json.load(f).get('titles', {})
        missing = [k for k in src if not str(titles.get(k, '')).strip()]
        unknown = [k for k in titles if k not in src]
        for k in missing:
            print(f'--- {lang}: {k} has no title')
        for k in unknown:
            print(f'--- {lang}: {k} is not an event id')
        problems += len(missing) + len(unknown)
        print(f'--- {lang}: {len(src) - len(missing)}/{len(src)} events translated')
    return 1 if problems else 0


def cmd_calendar_gen(write=True):
    src = load_calendar_source()
    trees = {}
    for lang in LANGS:
        path = cal_worker_file(lang)
        titles = {}
        if os.path.exists(path):
            with open(path, encoding='utf-8') as f:
                titles = json.load(f).get('titles', {})
        trees[lang] = {eid: {'title': t} for eid, t in titles.items()
                       if eid in src and str(t).strip()}
    # event id -> language -> field -> text, ready to hand to the entity
    by_event = {}
    for eid in src:
        per_lang = {lang: trees[lang][eid] for lang in LANGS if eid in trees[lang]}
        if per_lang:
            by_event[eid] = per_lang
    header = (
        '// GENERATED — do not edit by hand.\n'
        '// Source: tool/i18n/calendar_zh.json, tool/i18n/calendar_vi.json\n'
        '// Regenerate: python tool/i18n/i18n_tool.py calendar-gen\n'
        '//\n'
        '// Academic-calendar event id -> language -> field -> text. The Korean and\n'
        '// English names stay on the event itself; an event that is missing here\n'
        '// falls back to English, then Korean.\n\n')
    body = ('const Map<String, Map<String, Map<String, Object?>>> '
            'calendarTitleI18n = ' + _dart(by_event, 0) + ';\n')
    cmd_calendar_gen.last_output = header + body
    if write:
        with open(CAL_OUT_DART, 'w', encoding='utf-8', newline='') as f:
            f.write(header + body)
    print(('wrote ' if write else 'generated (not written) ')
          + os.path.relpath(CAL_OUT_DART, APP),
          '- events:', {l: len(trees[l]) for l in LANGS})
    return 0


def cmd_calendar_check():
    on_disk = (open(CAL_OUT_DART, encoding='utf-8').read()
               if os.path.exists(CAL_OUT_DART) else '')
    rc = cmd_calendar_gen(write=False)
    if rc:
        return rc
    if cmd_calendar_gen.last_output != on_disk:
        print('calendar_translations.g.dart is stale — run: '
              'python tool/i18n/i18n_tool.py calendar-gen')
        return 1
    print('calendar_translations.g.dart matches the translation files')
    return 0



# --- facilities, cafeterias, floor guides -------------------------------------

PLACE_SOURCE = os.path.join(APP, 'tool', 'i18n', 'place_source.json')
PLACE_OUT_DART = os.path.join(APP, 'lib', 'data', 'i18n', 'place_translations.g.dart')
PLACE_LANGS = ['en', 'zh', 'vi']      # English too: rooms and menus had none

# A Hangul syllable next to a Latin letter with nothing between them. That is
# what a substring replacement leaves when it runs over a Korean word instead
# of translating it, and the result is unreadable in every language.
GLUED_SCRIPTS = re.compile(r'(?<=[가-힣])[A-Za-zÀ-ỹ]|[A-Za-zÀ-ỹ](?=[가-힣])')


def squash_spaces(s):
    """The string with every run of whitespace removed: respacing the Korean
    is not translating it."""
    return re.sub(r'\s+', '', str(s))


def place_worker_file(lang):
    return os.path.join(APP, 'tool', 'i18n', f'place_{lang}.json')


def load_place_source():
    with open(PLACE_SOURCE, encoding='utf-8') as f:
        return json.load(f)


def _place_expected(src):
    """Every key a translation file must carry, per section."""
    fac = {}
    for fid, f in src['facilities'].items():
        keys = [k for k in ('name', 'building', 'hours', 'description')
                if f.get(k + '_ko') or f.get(k + '_en')]
        if keys:
            fac[fid] = keys
    caf = {cid: [k for k in ('name', 'hours') if c.get(k + '_ko')]
           for cid, c in src['cafeterias'].items()}
    return {
        'facilities': fac,
        'cafeterias': caf,
        'menu_items': list(src['menu_items']),
        'floor_labels': list(src['floor_labels']),
        'rooms': list(src['rooms']['in_scope']),
    }


def cmd_place_validate():
    src = load_place_source()
    want = _place_expected(src)
    problems = 0
    for lang in PLACE_LANGS:
        path = place_worker_file(lang)
        if not os.path.exists(path):
            print(f'--- {lang}: no file yet ({os.path.relpath(path, APP)})')
            problems += 1
            continue
        with open(path, encoding='utf-8') as f:
            doc = json.load(f)
        missing = []
        unknown = []
        filled = 0
        for section in ('facilities', 'cafeterias'):
            have = doc.get(section, {})
            for oid, keys in want[section].items():
                for k in keys:
                    v = str(have.get(oid, {}).get(k, '')).strip()
                    if v:
                        filled += 1
                    else:
                        missing.append(f'{section}.{oid}.{k}')
            for oid in have:
                if oid not in want[section]:
                    unknown.append(f'{section}.{oid}')
        for section in ('menu_items', 'floor_labels', 'rooms'):
            have = doc.get(section, {})
            for key in want[section]:
                v = str(have.get(key, '')).strip()
                if v:
                    filled += 1
                else:
                    missing.append(f'{section}.{key}')
            for key in have:
                # A name that has left the translation scope (reclassified as a
                # company or a person's office) keeps its text: the screen shows
                # the Korean on the door, and the translation still feeds
                # search. place-gen keeps these for the same reason.
                if key not in want[section] and not str(have[key]).strip():
                    unknown.append(f'{section}.{key}')
        total = filled + len(missing)
        # A filled cell is not automatically a translation. Two shapes were
        # counted as done on 2026-09-26 and were not (리드 2026-09-27):
        #   glued   a substring replacement ran over the Korean and left the
        #           two scripts stuck together: 건설tòa nhà리phòng trưởng trụ sở
        #   respaced the same Korean with the spaces moved: 「A/B」 → 「A / B」
        glued, respaced = [], []
        for section in ('menu_items', 'floor_labels', 'rooms'):
            have = doc.get(section, {})
            for key in want[section]:
                v = str(have.get(key, '')).strip()
                if not v or v == key.strip():
                    # An untranslated cell is counted elsewhere; a kept sign
                    # name may legitimately mix scripts ((주)대성FNT).
                    continue
                if GLUED_SCRIPTS.search(v):
                    glued.append(f'{section}.{key} = {v}')
                elif (v != key.strip()
                      and squash_spaces(v) == squash_spaces(key)):
                    # Only the pretend change is a problem here. A value that is
                    # exactly the Korean (an English floor label, a kept sign
                    # name) is honest, and the scope table already counts it as
                    # untranslated rather than as work done.
                    respaced.append(f'{section}.{key} = {v}')
        for m in missing[:10]:
            print(f'--- {lang}: {m} is empty')
        if len(missing) > 10:
            print(f'--- {lang}: ... and {len(missing) - 10} more empty')
        for u in unknown[:10]:
            print(f'--- {lang}: {u} is not in the source')
        for g in glued[:5]:
            print(f'--- {lang}: Korean glued to letters: {g}')
        if len(glued) > 5:
            print(f'--- {lang}: ... and {len(glued) - 5} more glued')
        for r in respaced[:5]:
            print(f'--- {lang}: only the spacing changed: {r}')
        if len(respaced) > 5:
            print(f'--- {lang}: ... and {len(respaced) - 5} more respaced')
        print(f'--- {lang}: {filled}/{total} strings'
              + (f' | not translations: {len(glued)} glued,'
                 f' {len(respaced)} respaced' if glued or respaced else ''))
        problems += len(missing) + len(unknown) + len(glued) + len(respaced)
    return 1 if problems else 0


def cmd_place_gen(write=True):
    src = load_place_source()
    want = _place_expected(src)

    # id -> language -> field -> text
    by_object = {}
    for section in ('facilities', 'cafeterias'):
        out = {}
        for oid, keys in want[section].items():
            per_lang = {}
            for lang in PLACE_LANGS:
                path = place_worker_file(lang)
                if not os.path.exists(path):
                    continue
                with open(path, encoding='utf-8') as f:
                    doc = json.load(f)
                fields = {k: doc.get(section, {}).get(oid, {}).get(k, '')
                          for k in keys}
                fields = {k: v for k, v in fields.items() if str(v).strip()}
                if fields:
                    per_lang[lang] = fields
            if per_lang:
                out[oid] = per_lang
        by_object[section] = out

    # Korean text -> language -> text
    by_text = {}
    for section in ('menu_items', 'floor_labels', 'rooms'):
        out = {}
        keys = list(want[section])
        if section == 'rooms':
            # Names that fell out of the translation scope (companies, named
            # offices) but already have a translation stay in the table: the
            # screen still shows the Korean on the door, and this is what lets
            # a Vietnamese reader find the place by typing its Vietnamese name.
            for lang in PLACE_LANGS:
                path = place_worker_file(lang)
                if not os.path.exists(path):
                    continue
                with open(path, encoding='utf-8') as f:
                    extra = json.load(f).get(section, {})
                for k, v in extra.items():
                    if k not in keys and str(v).strip():
                        keys.append(k)
        for key in keys:
            per_lang = {}
            for lang in PLACE_LANGS:
                path = place_worker_file(lang)
                if not os.path.exists(path):
                    continue
                with open(path, encoding='utf-8') as f:
                    doc = json.load(f)
                v = str(doc.get(section, {}).get(key, '')).strip()
                if v:
                    per_lang[lang] = v
            if per_lang:
                out[key] = per_lang
        by_text[section] = out

    header = (
        '// GENERATED — do not edit by hand.\n'
        '// Source: tool/i18n/place_en.json, place_zh.json, place_vi.json\n'
        '// Regenerate: python tool/i18n/i18n_tool.py place-gen\n'
        '//\n'
        '// Facilities and cafeterias are keyed by id; menu lines, floor labels and\n'
        '// room names are keyed by their Korean text, because they have no id and\n'
        '// the source is rewritten (daily, for menus). A key that stops matching\n'
        '// simply falls back to Korean instead of mislabelling something else.\n\n')
    body = ''
    body += ('const Map<String, Map<String, Map<String, Object?>>> facilityI18n = '
             + _dart(by_object['facilities'], 0) + ';\n\n')
    body += ('const Map<String, Map<String, Map<String, Object?>>> cafeteriaI18n = '
             + _dart(by_object['cafeterias'], 0) + ';\n\n')
    for name, section in (('menuItemI18n', 'menu_items'),
                          ('floorLabelI18n', 'floor_labels'),
                          ('roomNameI18n', 'rooms')):
        body += (f'const Map<String, Map<String, String>> {name} = '
                 + _dart(by_text[section], 0) + ';\n\n')
    # Which room names this round asked to have translated. The table above is
    # wider on purpose (search), so the screen needs to know the difference
    # (감사 05/042 SF-2).
    body += ('const Set<String> roomNamesInScope = {\n'
             + ''.join(f'  {_dart(k, 2)},\n' for k in want['rooms'])
             + '};\n\n')
    cmd_place_gen.last_output = header + body
    if write:
        with open(PLACE_OUT_DART, 'w', encoding='utf-8', newline='') as f:
            f.write(header + body)
    print(('wrote ' if write else 'generated (not written) ')
          + os.path.relpath(PLACE_OUT_DART, APP),
          '- facilities:', len(by_object['facilities']),
          'cafeterias:', len(by_object['cafeterias']),
          'menu:', len(by_text['menu_items']),
          'floors:', len(by_text['floor_labels']),
          'rooms:', len(by_text['rooms']))
    return 0


def cmd_place_check():
    on_disk = (open(PLACE_OUT_DART, encoding='utf-8').read()
               if os.path.exists(PLACE_OUT_DART) else '')
    rc = cmd_place_gen(write=False)
    if rc:
        return rc
    if cmd_place_gen.last_output != on_disk:
        print('place_translations.g.dart is stale — run: '
              'python tool/i18n/i18n_tool.py place-gen')
        return 1
    print('place_translations.g.dart matches the translation files')
    return 0


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'status'
    fn = {'source': cmd_source, 'validate': cmd_validate, 'gen': cmd_gen,
          'check': cmd_check, 'status': cmd_status,
          'check-encoding': cmd_check_encoding,
          'calendar-validate': cmd_calendar_validate,
          'calendar-gen': cmd_calendar_gen,
          'calendar-check': cmd_calendar_check,
          'place-validate': cmd_place_validate,
          'place-gen': cmd_place_gen,
          'place-check': cmd_place_check}[cmd]
    sys.exit(fn() or 0)
