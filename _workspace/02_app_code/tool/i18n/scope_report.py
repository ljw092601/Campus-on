# -*- coding: utf-8 -*-
"""Counts what is translated, what keeps its Korean on purpose, and what is
neither — from the files, not from memory.

  python tool/i18n/scope_report.py [--out <path>]

Written because 'translated' and 'left in Korean because the door sign is in
Korean' are different things, and adding them together would overstate the
work. Every number here is derived; nothing is typed in.
"""
import argparse
import io
import json
import os
import re
import sys

APP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
I18N = os.path.join(APP, 'tool', 'i18n')
SEED = os.path.join(APP, 'tool', 'firestore_seed')
LANGS = ('en', 'zh', 'vi')

# A Hangul syllable and a Latin letter with nothing between them: what a
# substring replacement leaves behind when it runs over a Korean word instead
# of translating it.
GLUED = re.compile(r'(?<=[가-힣])[A-Za-zÀ-ỹ]|[A-Za-zÀ-ỹ](?=[가-힣])')


def squashed(s):
    """The string with every run of whitespace removed, for comparing against
    the Korean key: respacing is not translating."""
    return re.sub(r'\s+', '', str(s))


def load(p):
    with open(p, encoding='utf-8') as f:
        return json.load(f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(I18N, 'TRANSLATION_SCOPE.md'))
    a = ap.parse_args()

    src = load(os.path.join(I18N, 'place_source.json'))
    cls = load(os.path.join(I18N, 'room_classification.json'))
    tr = {l: load(os.path.join(I18N, f'place_{l}.json')) for l in LANGS}
    guides = load(os.path.join(SEED, 'guide_items.seed.json'))
    events = load(os.path.join(SEED, 'academic_events.seed.json'))
    cal = {l: load(os.path.join(I18N, f'calendar_{l}.json'))
           for l in ('zh', 'vi')}

    def filled(section, keys):
        """Counts filled cells minus the shapes known not to be translations.

        It is not a quality measure: `foo` counts, and so does Korean left
        inside a Chinese value with a space around it (B 03/078 SF-03). What it
        does exclude are the three shapes that have actually shipped here.

        A value identical to the Korean key is the Korean, not a translation —
        counting it would have reported 882 Vietnamese room names when 730 of
        them were still Korean (조사 04/030).

        Two more shapes are not translations either, both found in the
        Vietnamese room names on 2026-09-27:

          * the same Korean with the spacing changed (`A/B` → `A / B`): 54 rows
            passed the equality test above while saying nothing new;
          * Korean glued to Latin letters inside one word
            (`건설tòa nhà리phòng trưởng trụ sở`): 154 rows where a substring
            replacement had run over the Korean instead of translating it.
        """
        out = {}
        for l in LANGS:
            n = 0
            for k in keys:
                v = str(tr[l][section].get(k, '')).strip()
                if v and squashed(v) == squashed(k):
                    continue
                if v and GLUED.search(v):
                    continue
                if v and v != k.strip():
                    n += 1
            out[l] = n
        return out

    def left_korean(section, keys):
        return {l: sum(1 for k in keys
                       if str(tr[l][section].get(k, '')).strip() == k.strip())
                for l in LANGS}

    rooms_scope = list(src['rooms']['in_scope'])
    totals = cls['totals']
    rows = []

    # guides: every guide carries zh/vi in the generated overlay
    guide_i18n = sum(1 for g in guides.values() if g.get('i18n'))
    rows.append(('행정 가이드', len(guides),
                 f'{guide_i18n}/{len(guides)} (zh·vi)', '—', '—'))

    ev = sum(1 for e in events.values()
             if (e.get('i18n') or {}).get('zh') and (e.get('i18n') or {}).get('vi'))
    rows.append(('학사일정 행사명', len(events),
                 f'{ev}/{len(events)} (zh·vi)', '—',
                 f"원문 {len(cal['zh']['titles'])}건"))

    fac = load(os.path.join(SEED, 'facilities.seed.json'))
    fac_i18n = sum(1 for f in fac.values()
                   if (f.get('i18n') or {}).get('zh') and (f.get('i18n') or {}).get('vi'))
    rows.append(('시설 이름', len(fac), f'{fac_i18n}/{len(fac)} (zh·vi)', '—', '—'))

    caf = load(os.path.join(SEED, 'cafeterias.seed.json'))
    caf_i18n = sum(1 for c in caf.values()
                   if (c.get('i18n') or {}).get('zh') and (c.get('i18n') or {}).get('vi'))
    rows.append(('식당 이름·운영시간', len(caf), f'{caf_i18n}/{len(caf)} (zh·vi)', '—', '—'))

    menu_keys = list(src['menu_items'])
    m = filled('menu_items', menu_keys)
    rows.append(('학식 메뉴 줄(샘플 식단)', len(menu_keys),
                 ' · '.join(f'{l} {m[l]}' for l in LANGS), '—',
                 '매일 새 메뉴는 번역 전까지 한국어'))

    fl = filled('floor_labels', list(src['floor_labels']))
    rows.append(('층 라벨', len(src['floor_labels']),
                 ' · '.join(f'{l} {fl[l]}' for l in LANGS), '—', '—'))

    rm = filled('rooms', rooms_scope)
    rk = left_korean('rooms', rooms_scope)
    rows.append(('층별 안내 공간명', totals['distinct'],
                 ' · '.join(f'{l} {rm[l]}' for l in LANGS),
                 f"{totals['proper']}건(업체·사람 이름) + 미번역 "
                 + ' · '.join(f'{l} {rk[l]}' for l in LANGS if rk[l]),
                 f"확인 필요 {totals['unsure']}건 / 번역 대상 {totals['generic']}건"))

    lines = [
        '# 번역 범위 집계',
        '',
        '> `python tool/i18n/scope_report.py`가 파일에서 세어 만든다. 손으로 고치지 마라.',
        '> **「원명 유지」는 번역 완료가 아니다** — 문 앞 표지판이 한국어라 일부러 남긴 것이고 따로 센다.',
        '> 한국어 원문과 **같은 값**도 번역으로 세지 않는다(조사 04/030이 잡은 베트남어 730건).',
        '',
        '| 대상 | 전체 | 번역됨 | 원명 유지(의도) | 비고 |',
        '|---|---:|---|---|---|',
    ]
    for name, total, done, kept, note in rows:
        lines.append(f'| {name} | {total} | {done} | {kept} | {note} |')

    lines += [
        '',
        '## 층별 안내 공간명 분류',
        '',
        f"- 고유 이름 **{totals['distinct']}개**, 화면 표시 **{totals['placements']}건**",
        f"- 번역 대상(일반 공간명): **{totals['generic']}개** / 표시 {totals['generic_placements']}건",
        f"- 원명 유지(업체·사람 이름·영문 브랜드): **{totals['proper']}개** / 표시 {totals['proper_placements']}건",
        f"- 확인 필요(규칙으로 판정 못 함): **{totals['unsure']}개** / 표시 {totals['unsure_placements']}건",
        '',
        '이번 묶음에서 번역을 요청한 범위: '
        f"**{len(rooms_scope)}개** / 표시 {src['rooms']['_placements_in_scope']}건",
        '',
        '## 학식 메뉴에 대해',
        '',
        '지금 번역된 메뉴 줄은 **샘플 식단**의 것이다(화면에도 예시라고 안내한다). '
        '학교 API가 붙은 뒤의 실제 식단은 번역돼 있지 않으며, 번역이 없는 줄은 한국어로 표시된다. '
        '새 메뉴를 찾아 번역까지 잇는 절차는 `tool/i18n/menu_scan_test.dart` 주석에 적혀 있다.',
        '',
    ]
    io.open(a.out, 'w', encoding='utf-8', newline='').write('\n'.join(lines))
    print('wrote', os.path.relpath(a.out, APP))
    for name, total, done, kept, note in rows:
        print(f'  {name}: {total} | {done} | kept {kept}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
