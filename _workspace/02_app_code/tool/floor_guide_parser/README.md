# Floor guide parser

동아대 공식 캠퍼스맵 → 앱 데이터 파이프라인 (plan.md §9).

```
캠퍼스맵 페이지 ──(fetch_building_coords.py)──▶ building_coords.csv
층별안내 md + CSV ──(parse_floor_guide.py)──▶ lib/data/mock/building_data.g.dart
                                              └▶ buildings_seed.json (검수용)
```

```bash
# 이 디렉터리에서 (Python 3.10+)
python fetch_building_coords.py   # 사이트에서 좌표 재수집 (건물 이동/신축 시)
python parse_floor_guide.py       # md·CSV → Dart 데이터 재생성
```

- 검증 실패(건물 48 · 층 보유 34 · 층 249 · 이름/캠퍼스 대조) 시 생성 없이 즉시 중단.
- `building_coords.csv`·`building_data.g.dart`는 **생성물 — 수동 편집 금지**.
- 층·실 명칭은 한국어 전용(소스가 한국어). 타 언어는 추후 단계.
- 이후 Firestore 반영은 `tool/firestore_seed/README.md` 절차를 따른다.
