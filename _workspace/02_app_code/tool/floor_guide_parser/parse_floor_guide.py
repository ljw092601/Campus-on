# -*- coding: utf-8 -*-
"""층별안내 md + building_coords.csv → lib/data/mock/building_data.g.dart 생성.

- 입력 1: 동아대학교_캠퍼스_건물층별안내.md (repo 루트) — 건물 48 · 층 249
- 입력 2: building_coords.csv (fetch_building_coords.py 로 생성)
- 출력 1: lib/data/mock/building_data.g.dart — 앱 단일 소스(mock/시드 공용)
- 출력 2: buildings_seed.json — 검수용 스냅샷(앱은 읽지 않음)

검증: 건물 48건 · 층 보유 34건 · 층 합계 249건 · CSV와 캠퍼스/코드 정렬 일치.
하나라도 어긋나면 생성 없이 즉시 실패한다.

사용법(이 디렉터리에서):  python parse_floor_guide.py
⚠️ building_data.g.dart 는 이 스크립트로만 재생성한다(수동 편집 금지).
"""
import csv
import io
import json
import re
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

SCRIPT_DIR = Path(__file__).resolve().parent
APP_ROOT = SCRIPT_DIR.parents[1]  # _workspace/02_app_code/
REPO_ROOT = SCRIPT_DIR.parents[3]  # Campus-on/
MD_PATH = REPO_ROOT / "동아대학교_캠퍼스_건물층별안내.md"
CSV_PATH = SCRIPT_DIR / "building_coords.csv"
OUT_DART = APP_ROOT / "lib" / "data" / "mock" / "building_data.g.dart"
OUT_JSON = SCRIPT_DIR / "buildings_seed.json"

EXPECT_BUILDINGS = 48
EXPECT_WITH_FLOORS = 34
EXPECT_FLOORS = 249

CAMPUS_MAP = {"승학캠퍼스": "seunghak", "구덕캠퍼스": "gudeok", "부민캠퍼스": "bumin"}

# 영어 건물명 — id 기준, 앱 EN 모드 표기용 서술형 번역(공식 영문 표기가
# 확인되는 건물은 그 표기로 갱신할 것). 누락 시 생성이 즉시 실패한다.
EN_NAMES = {
    "s01": "University Administration & College of Humanities (A)",
    "s02": "Student Union Building (Q)",
    "s03": "Engineering Building 1 (P1)",
    "s04": "Engineering Building 2 (P2)",
    "s05": "Engineering Building 3 (P3)",
    "s06": "Engineering Building 5 (RS)",
    "s07": "Arts & Sports Building 1",
    "s08": "Faculty Hall (W)",
    "s09": "Colleges of Life Resource Science & Health Sciences",
    "s10": "Hanlim Library (B)",
    "s11": "College of Natural Sciences (E)",
    "p4": "Engineering Building 4 (P4)",
    "s13": "Startup Hall",
    "s14": "Industry-Academic Cooperation Building (SM)",
    "s15": "Hanlim Dormitory Seunghak Hall 1",
    "s16": "ROTC Building (DE)",
    "s17": "Arts & Sports Building 2",
    "s18": "Arts & Sports Practice Building",
    "s19": "Hanlim Dormitory Seunghak Hall 2",
    "s20": "Hanlim Dormitory Seunghak Hall 2",
    "s31": "Security Office",
    "loc059": "Main Gate",
    "s22": "L2M Platform (S22)",
    "s21": "High-Pressure Hydrogen Test Building (S21)",
    "g03": "Seokdang Memorial Hall",
    "g01": "Gudeok Research Building 1",
    "loc062": "College of Medicine (S2)",
    "g02": "College of Medicine",
    "g04": "Gudeok Education Building 1",
    "g05": "Gudeok Education Buildings 2 & 3",
    "g06": "Gudeok Research Building 2",
    "g11": "Gudeok Education Building 4",
    "g12": "Gudeok Student Union Building",
    "loc068": "Dong-A University Hospital (Main)",
    "loc069": "Dong-A University Hospital (West Wing)",
    "loc070": "Dong-A University Hospital (East Wing)",
    "loc071": "Dong-A University Hospital (Central Wing)",
    "loc072": "Dong-A University Daesin Long-term Care Hospital",
    "loc073": "Main Gate",
    "b01": "Seokdang Museum (BM)",
    "b02": "Law School (LS)",
    "b03": "Global Leadership Hall",
    "b04": "General Lecture Building (BA-BD)",
    "b05": "International Hall",
    "b31": "Security Office",
    "b32": "Dong-A Korean Language Institute",
    "loc082": "Hanlim Dormitory Bumin Hall",
    "loc083": "Main Gate",
}


def parse_md(md: str) -> list[dict]:
    """본문 h1(캠퍼스)/h2(건물) 구조를 순서대로 파싱."""
    buildings: list[dict] = []
    campus = None
    cur: dict | None = None
    for line in md.splitlines():
        h1 = re.match(r"^# (\S+캠퍼스)\s*$", line)
        if h1:
            campus = CAMPUS_MAP[h1.group(1)]
            continue
        h2 = re.match(r"^## (.+)$", line)
        if h2:
            title = h2.group(1).strip()
            if title in ("목차", "통계 요약") or campus is None:
                cur = None
                continue
            code_m = re.match(r"([SGBP]\d{1,2})\s+(.+)", title)
            if code_m:
                code, name = code_m.group(1), code_m.group(2).strip()
            else:
                code = ""
                name = re.sub(r"\s*·\s*\S+캠퍼스$", "", title).strip()
            cur = {"campus": campus, "code": code, "name": name,
                   "description": "", "floors": []}
            buildings.append(cur)
            continue
        if cur is None:
            continue
        desc_m = re.match(r"^\*(.+)\*\s*$", line.strip())
        if desc_m and not cur["floors"]:
            cur["description"] = desc_m.group(1).strip()
            continue
        row_m = re.match(r"^\|\s*\*\*(.+?)\*\*\s*\|(.+)\|\s*$", line)
        if row_m:
            floor = row_m.group(1).strip()
            cur["floors"].append(
                {"floor": floor, "rooms": split_rooms(row_m.group(2))})
    return buildings


def split_rooms(cell: str) -> list[str]:
    """괄호 밖의 쉼표로만 분리 — '교수연구실(김혜숙, 이근애)'는 한 항목."""
    rooms, buf, depth = [], [], 0
    for ch in cell:
        if ch in "(（[":
            depth += 1
        elif ch in ")）]":
            depth = max(0, depth - 1)
        if ch == "," and depth == 0:
            rooms.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    rooms.append("".join(buf).strip())
    return [r for r in rooms if r]


def category_for(name: str) -> str:
    if "도서관" in name:
        return "library"
    if name in ("정문", "수위실"):
        return "etc"
    return "building"


def merge_coords(buildings: list[dict]) -> None:
    with CSV_PATH.open(encoding="utf-8-sig") as f:
        coords = list(csv.DictReader(f))
    if len(coords) != len(buildings):
        raise SystemExit(f"CSV {len(coords)}건 vs md 본문 {len(buildings)}건 — 개수 불일치")
    norm = lambda s: re.sub(r"\s+", "", s)
    for b, c in zip(buildings, coords):
        if (b["campus"], b["code"]) != (c["campus"], c["code"]):
            raise SystemExit(
                f"정렬 불일치: md({b['campus']},{b['code']},{b['name']}) vs "
                f"csv({c['campus']},{c['code']},{c['name']})")
        bn, cn = norm(b["name"]), norm(c["name"])
        if not (bn == cn or bn in cn or cn in bn):
            raise SystemExit(f"이름 불일치: md='{b['name']}' vs csv='{c['name']}'")
        b["lat"] = float(c["lat"])
        b["lng"] = float(c["lng"])
        # id: 건물코드(s01…) 우선, 없으면 사이트 내부코드(loc060…) — 둘 다 안정적.
        b["id"] = (b["code"] or c["site_code"]).lower()


def validate(buildings: list[dict]) -> None:
    n = len(buildings)
    with_floors = sum(1 for b in buildings if b["floors"])
    floors = sum(len(b["floors"]) for b in buildings)
    ids = [b["id"] for b in buildings]
    print(f"건물 {n}건 · 층 보유 {with_floors}건 · 층 합계 {floors}건")
    if n != EXPECT_BUILDINGS:
        raise SystemExit(f"건물 수 {n} ≠ {EXPECT_BUILDINGS}")
    if with_floors != EXPECT_WITH_FLOORS:
        raise SystemExit(f"층 보유 건물 수 {with_floors} ≠ {EXPECT_WITH_FLOORS}")
    if floors != EXPECT_FLOORS:
        raise SystemExit(f"층 수 합계 {floors} ≠ {EXPECT_FLOORS}")
    if len(set(ids)) != len(ids):
        dupes = sorted({i for i in ids if ids.count(i) > 1})
        raise SystemExit(f"id 중복: {dupes}")
    missing_en = [i for i in ids if i not in EN_NAMES]
    if missing_en:
        raise SystemExit(f"EN_NAMES 누락: {missing_en}")


def dstr(s: str) -> str:
    """Dart 단일따옴표 문자열 리터럴로 이스케이프."""
    return "'" + s.replace("\\", r"\\").replace("'", r"\'").replace("$", r"\$") + "'"


def emit_dart(buildings: list[dict]) -> str:
    out = []
    w = out.append
    w("// GENERATED by tool/floor_guide_parser/parse_floor_guide.py — DO NOT EDIT.")
    w("// Source: 동아대학교_캠퍼스_건물층별안내.md + building_coords.csv (공식 캠퍼스맵).")
    w("// Regenerate:  python tool/floor_guide_parser/parse_floor_guide.py")
    w("// ignore_for_file: lines_longer_than_80_chars")
    w("")
    w("import '../../domain/entities/building_floors.dart';")
    w("import '../../domain/entities/facility.dart';")
    w("")
    w("/// Real Dong-A campus buildings (48) + floor guides (34) generated from")
    w("/// the official campus map. Single source of truth for mock repositories")
    w("/// and the Firestore seed export.")
    w("abstract final class BuildingData {")
    w("  static const List<Facility> facilities = [")
    for b in buildings:
        w("    Facility(")
        w(f"      id: {dstr(b['id'])},")
        w(f"      nameKo: {dstr(b['name'])},")
        w(f"      nameEn: {dstr(EN_NAMES[b['id']])},")
        w(f"      category: FacilityCategory.{category_for(b['name'])},")
        w(f"      lat: {b['lat']},")
        w(f"      lng: {b['lng']},")
        w(f"      campus: Campus.{b['campus']},")
        if b["code"]:
            w(f"      buildingCode: {dstr(b['code'])},")
        if b["floors"]:
            w("      hasFloorInfo: true,")
        if b["description"]:
            w(f"      descriptionKo: {dstr(b['description'])},")
        w("    ),")
    w("  ];")
    w("")
    w("  static const List<BuildingFloors> floors = [")
    for b in buildings:
        if not b["floors"]:
            continue
        w("    BuildingFloors(")
        w(f"      facilityId: {dstr(b['id'])},")
        w("      floors: [")
        for fl in b["floors"]:
            rooms = ", ".join(dstr(r) for r in fl["rooms"])
            w(f"        FloorInfo(floor: {dstr(fl['floor'])}, rooms: [{rooms}]),")
        w("      ],")
        w("    ),")
    w("  ];")
    w("}")
    w("")
    return "\n".join(out)


def main() -> None:
    buildings = parse_md(MD_PATH.read_text(encoding="utf-8"))
    merge_coords(buildings)
    validate(buildings)
    for b in buildings:
        b["name_en"] = EN_NAMES[b["id"]]

    OUT_DART.write_text(emit_dart(buildings), encoding="utf-8")
    print(f"생성: {OUT_DART.relative_to(APP_ROOT)}")

    OUT_JSON.write_text(
        json.dumps(buildings, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print(f"생성: {OUT_JSON.name} (검수용)")


if __name__ == "__main__":
    main()
