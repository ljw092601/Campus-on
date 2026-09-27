# -*- coding: utf-8 -*-
"""Sorts every room name in the floor guide into what should happen to it.

  python tool/i18n/classify_rooms.py [--scope N]

Three outcomes, counted separately so that 'kept as the sign reads' is never
reported as 'translated':

  generic   a kind of space (lecture room, corridor, boiler room). Translate.
  proper    a tenant company, a named person's office, a brand. The Korean is
            what the door says, so it stays — in every language.
  unsure    something the rules cannot place. Left Korean and listed, so a
            person can decide rather than a regex.

The scope argument picks how many of the generic names to ask for this round,
most-placed first; the rest keep their Korean until a later batch.
"""
import argparse
import io
import json
import os
import re
import sys

APP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SEED = os.path.join(APP, 'tool', 'firestore_seed', 'building_floors.seed.json')
OUT = os.path.join(APP, 'tool', 'i18n', 'room_classification.json')
# Names a person has already placed by hand. Read before the rules, because a
# regex should never overrule a decision someone made and wrote down.
DECISIONS = os.path.join(APP, 'tool', 'i18n', 'room_decisions.json')


def load_decisions():
    if not os.path.exists(DECISIONS):
        return {}
    with open(DECISIONS, encoding='utf-8') as f:
        return json.load(f).get('decisions', {})

# A tenant, a body, or a person's own room: the sign is the name itself.
COMPANY = re.compile(r'\((주|사|재)\)')
PERSON_ROOM = re.compile(r'연구실\s*\([^)]*[가-힣][^)]*\)')
# Latin/brand-only names (BOOK GALLERY, DNW, Coffee Heaven, BJ Instrument…)
LATIN_ONLY = re.compile(r'^[A-Za-z0-9][A-Za-z0-9 .,&\-/+()]*$')
# A room number or code carried inside the name (P1-101, 3Ex, A동)
HAS_CODE = re.compile(r'[A-Za-z]?\d{2,}')

# Words that make a name a kind of space even when something else is attached.
GENERIC_WORDS = (
    '강의실', '실습실', '세미나실', '회의실', '휴게실', '연구실', '실험실', '창고',
    '복도', '홀', '전기실', '기계실', '보일러실', '펌프실', '화장실', '샤워',
    '탈의실', '주방', '식당', '매점', '카페', '서고', '자료실', '열람실', '사무실',
    '행정실', '경비실', '방송실', '준비실', '대기실', '숙직실', '탕비실', '세탁실',
    '창고', '기자재실', '전산실', '서버실', '통신실', '전시실', '동아리', '체력단련',
    '샤워실', '수장고', '정독실', '학생회실', '사감실', '분석실', '암실', '조정실',
    '영사실', '생활실', '스터디', '라운지', '보건', '상담실', '인쇄실', '복사실',
)


def classify(name, decided=None):
    n = name.strip()
    hand = (decided or {}).get(n)
    if hand:
        return hand['decision'], 'hand:' + hand['why']
    if COMPANY.search(n):
        return 'proper', 'company'
    if PERSON_ROOM.search(n):
        return 'proper', 'person'
    if LATIN_ONLY.match(n):
        return 'proper', 'latin'
    generic = any(w in n for w in GENERIC_WORDS)
    if generic:
        # A kind of space, possibly with a code or a department in front. The
        # code is preserved by the translator; the words around it are what get
        # translated.
        return 'generic', 'code' if HAS_CODE.search(n) else 'plain'
    # 감사 05/042 SF-3 sampled the leftovers and found roughly five in six were
    # ordinary rooms that the word list simply did not name. Two shapes cover
    # most of them, and both are safe because a person's name inside brackets
    # has already been excluded above.
    if re.search(r'(실|룸|관|과|부|처|센터|장실|사무실)\s*\d*$', n):
        return 'generic', 'suffix'
    if re.search(r'(학회|동아리|부실|단실)$', n):
        return 'generic', 'club'
    if HAS_CODE.search(n):
        return 'unsure', 'code-only'
    if re.search(r'[A-Za-z]', n) and re.search(r'[가-힣]', n):
        return 'unsure', 'mixed'
    return 'unsure', 'other'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scope', type=int, default=0,
                    help='how many generic names to put in this round (0 = all)')
    a = ap.parse_args()

    with open(SEED, encoding='utf-8') as f:
        data = json.load(f)
    counts = {}
    for b in data.values():
        for fl in b['floors']:
            for r in fl['rooms']:
                counts[r] = counts.get(r, 0) + 1

    decided = load_decisions()
    buckets = {'generic': {}, 'proper': {}, 'unsure': {}}
    why = {}
    for name, n in counts.items():
        kind, reason = classify(name, decided)
        buckets[kind][name] = n
        why[name] = reason

    order = sorted(buckets['generic'].items(), key=lambda e: (-e[1], e[0]))
    scope = order if a.scope <= 0 else order[:a.scope]
    placements = sum(counts.values())

    doc = {
        '_what': '층별 안내 공간명 분류. generic만 번역 대상이고, proper는 문 앞 표지판대로 한국어를 유지한다.',
        '_generated_by': 'python tool/i18n/classify_rooms.py',
        'totals': {
            'distinct': len(counts),
            'placements': placements,
            'generic': len(buckets['generic']),
            'proper': len(buckets['proper']),
            'unsure': len(buckets['unsure']),
            'generic_placements': sum(buckets['generic'].values()),
            'proper_placements': sum(buckets['proper'].values()),
            'unsure_placements': sum(buckets['unsure'].values()),
            'by_hand': sum(1 for r in why.values() if r.startswith('hand:')),
        },
        'scope_this_round': {
            'count': len(scope),
            'placements': sum(n for _, n in scope),
            'names': {k: v for k, v in scope},
        },
        # The full list, not a sample: a test reads it to check that a name on
        # a door is still on the door in every language (감사 05/042 NIT-6).
        'proper': dict(sorted(buckets['proper'].items(),
                              key=lambda e: (-e[1], e[0]))),
        'proper_sample': dict(sorted(buckets['proper'].items(),
                                     key=lambda e: -e[1])[:30]),
        'unsure': dict(sorted(buckets['unsure'].items(), key=lambda e: -e[1])),
        'reasons': {k: why[k] for k in list(buckets['unsure'])[:200]},
    }
    io.open(OUT, 'w', encoding='utf-8', newline='').write(
        json.dumps(doc, ensure_ascii=False, indent=2) + '\n')
    t = doc['totals']
    print(f"distinct {t['distinct']} / placements {t['placements']}")
    print(f"  generic {t['generic']} ({t['generic_placements']} placements)")
    print(f"  proper  {t['proper']} ({t['proper_placements']} placements)")
    print(f"  unsure  {t['unsure']} ({t['unsure_placements']} placements)")
    print(f"scope this round: {len(scope)} names, "
          f"{sum(n for _, n in scope)} placements")
    print('wrote', os.path.relpath(OUT, APP))
    return 0


if __name__ == '__main__':
    sys.exit(main())
