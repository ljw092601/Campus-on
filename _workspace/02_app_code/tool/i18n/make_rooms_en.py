# -*- coding: utf-8 -*-
"""Builds the English room names from the term dictionary.

  python tool/i18n/make_rooms_en.py [--write]

Room names are compositional — `<department or body><kind of space>` — so the
English is built by matching the longest known term first and leaving
everything else (people, companies, codes, numbers) exactly as it is. Names
that still carry untranslated Korean after that are listed rather than guessed
at; a person fills those in.

Only English is generated this way. Chinese and Vietnamese are written by the
translators, who can judge word order and register; this file exists because
English had no source text at all and the names are highly regular.
"""
import argparse
import io
import json
import os
import re
import sys

APP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(APP, 'tool', 'i18n', 'place_source.json')
TERMS = os.path.join(APP, 'tool', 'i18n', 'rooms_en_terms.json')
EN = os.path.join(APP, 'tool', 'i18n', 'place_en.json')

KOREAN = re.compile(r'[가-힣]')


def build(name, terms):
    """Replace known terms, longest first; keep everything else verbatim."""
    out = name
    for term, english in terms:
        if term in out:
            out = out.replace(term, f' {english} ')
    out = re.sub(r'\s+', ' ', out).strip()
    out = re.sub(r'\s+([)\],])', r'\1', out)
    out = re.sub(r'([(\[])\s+', r'\1', out)
    if not out:
        return name
    # Sentence case, but leave anything that is already capitalised or a code.
    if out[0].islower():
        out = out[0].upper() + out[1:]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', action='store_true')
    a = ap.parse_args()

    src = json.load(open(SRC, encoding='utf-8'))
    doc = json.load(open(TERMS, encoding='utf-8'))
    terms = sorted(
        [(k, v) for k, v in {**doc['unit'], **doc['space']}.items()],
        key=lambda e: -len(e[0]))
    en = json.load(open(EN, encoding='utf-8'))

    todo = [k for k in src['rooms']['in_scope']
            if not str(en['rooms'].get(k, '')).strip()]
    made, leftover = {}, []
    for name in todo:
        built = build(name, terms)
        made[name] = built
        if KOREAN.search(built):
            leftover.append((name, built))

    print(f'{len(todo)} names without English')
    print(f'  built: {len(made) - len(leftover)}')
    print(f'  still carrying Korean: {len(leftover)}')
    for name, built in leftover[:25]:
        print(f'    {name}  ->  {built}')
    if len(leftover) > 25:
        print(f'    ... and {len(leftover) - 25} more')

    if a.write:
        for k, v in made.items():
            en['rooms'][k] = v
        io.open(EN, 'w', encoding='utf-8', newline='').write(
            json.dumps(en, ensure_ascii=False, indent=2) + '\n')
        print('wrote', os.path.relpath(EN, APP))
    else:
        print('(dry run — pass --write to apply)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
