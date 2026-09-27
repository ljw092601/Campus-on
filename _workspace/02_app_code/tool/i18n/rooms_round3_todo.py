# -*- coding: utf-8 -*-
"""Lists the room names that are in scope but have no translation yet.

  python tool/i18n/rooms_round3_todo.py

Works the scope out from the floor seed and the hand decisions directly, rather
than trusting `room_classification.json` to have been regenerated first: running
the two out of order used to drop the names whose decision had just changed
(B 03/078 SF-02). The classification file is still read, but only to be compared
— a mismatch is reported, not hidden.
"""
import io
import json
import os

import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import classify_rooms as cr  # noqa: E402  (path set above)

APP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLASS = os.path.join(APP, 'tool', 'i18n', 'room_classification.json')
DEC = os.path.join(APP, 'tool', 'i18n', 'room_decisions.json')
SEED = os.path.join(APP, 'tool', 'firestore_seed', 'building_floors.seed.json')
OUT = os.path.join(APP, 'tool', 'i18n', 'rooms_round3_todo.json')


def main():
    dec = json.load(io.open(DEC, encoding='utf-8'))['decisions']
    decided = cr.load_decisions()

    counts = {}
    for b in json.load(io.open(SEED, encoding='utf-8')).values():
        for fl in b['floors']:
            for r in fl['rooms']:
                counts[r] = counts.get(r, 0) + 1
    scope = {name: n for name, n in counts.items()
             if cr.classify(name, decided)[0] == 'generic'}

    c = json.load(io.open(CLASS, encoding='utf-8'))
    stale = sorted(set(scope) ^ set(c['scope_this_round']['names']))
    if stale:
        print('room_classification.json is out of date by %d name(s) — run '
              'classify_rooms.py' % len(stale))
        for name in stale[:5]:
            print('   ', name)
    have = {}
    for lang in ('en', 'zh', 'vi'):
        p = os.path.join(APP, 'tool', 'i18n', 'place_%s.json' % lang)
        rows = json.load(io.open(p, encoding='utf-8')).get('rooms', {})
        have[lang] = {k for k, v in rows.items()
                      if v and v.strip() and v.strip() != k.strip()}

    todo = {}
    for name, n in sorted(scope.items(), key=lambda e: (-e[1], e[0])):
        missing = [l for l in ('en', 'zh', 'vi') if name not in have[l]]
        if missing:
            todo[name] = {
                'placements': n,
                'missing': missing,
                'why': dec.get(name, {}).get('why',
                                             cr.classify(name, decided)[1]),
            }

    doc = {
        '_what': '번역 대상인데 아직 번역이 없는 층별 안내 공간명. '
                 'place_{en,zh,vi}.json의 rooms에 채운다.',
        '_generated_by': 'python tool/i18n/rooms_round3_todo.py',
        '_rules': [
            '호실 번호·건물 코드·층 표기·영문 브랜드·사람 이름은 그대로 둔다.',
            '한국어 원문에 없는 기능·용도·대상을 덧붙이지 않는다.',
            '한국어와 같은 값을 넣으면 번역으로 세지 않는다.',
        ],
        '_after_filling': 'python tool/i18n/i18n_tool.py place-gen && place-validate',
        'counts': {
            'in_scope': len(scope),
            'todo': len(todo),
            'by_language': {l: sum(1 for v in todo.values() if l in v['missing'])
                            for l in ('en', 'zh', 'vi')},
        },
        'todo': todo,
    }
    io.open(OUT, 'w', encoding='utf-8', newline='').write(
        json.dumps(doc, ensure_ascii=False, indent=2) + '\n')
    print('in scope', len(scope), '| todo', len(todo), doc['counts']['by_language'])
    print('wrote', os.path.relpath(OUT, APP))


main()
