# -*- coding: utf-8 -*-
"""동아대 공식 캠퍼스맵 페이지에서 건물 좌표를 추출해 building_coords.csv를 생성한다.

페이지의 `campusArr` JS 배열에 건물명·좌표·캠퍼스구분(gubun)이 임베드되어 있어
이를 파싱하고, 층별안내 md의 목차와 순서·이름을 대조 검증한 뒤 CSV로 쓴다.

사용법:  python fetch_building_coords.py [--offline campusmap.html]
  --offline 없이 실행하면 페이지를 직접 내려받는다.

⚠️ building_coords.csv는 이 스크립트로만 재생성한다(수동 편집 금지).
"""
import argparse
import csv
import io
import re
import sys
import urllib.request
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

CAMPUS_MAP_URL = "https://www.donga.ac.kr/kor/CMS/CampusMgr/list.do?mCode=MN032"
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]  # Campus-on/
MD_PATH = REPO_ROOT / "동아대학교_캠퍼스_건물층별안내.md"
OUT_CSV = SCRIPT_DIR / "building_coords.csv"

# 사이트의 캠퍼스 구분 코드 → 앱 campus id
GUBUN_TO_CAMPUS = {
    "CDE_000091": "seunghak",
    "CDE_000092": "gudeok",
    "CDE_000093": "bumin",
}

ENTRY_RE = re.compile(
    r'name\s*:\s*"(?P<name>[^"]*)"\s*'
    r',\s*gubun\s*:\s*"(?P<gubun>[^"]*)"\s*'
    r',\s*code\s*:\s*"(?P<code>[^"]*)"\s*'
    r',\s*lat\s*:\s*(?P<lat>[\d.]+)\s*'
    r',\s*lng\s*:\s*(?P<lng>[\d.]+)',
)


def fetch_html(offline: str | None) -> str:
    if offline:
        return Path(offline).read_text(encoding="utf-8")
    req = urllib.request.Request(
        CAMPUS_MAP_URL, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    )
    with urllib.request.urlopen(req, timeout=30) as res:
        return res.read().decode("utf-8")


def parse_site(html: str) -> list[dict]:
    entries = [m.groupdict() for m in ENTRY_RE.finditer(html)]
    if not entries:
        raise SystemExit("campusArr 엔트리를 찾지 못함 — 페이지 구조 변경 여부 확인 필요")
    return entries


def parse_md_toc(md: str) -> list[dict]:
    """md 목차에서 (campus, 건물코드, 이름)을 문서 순서대로 추출."""
    campus_map = {"승학캠퍼스": "seunghak", "구덕캠퍼스": "gudeok", "부민캠퍼스": "bumin"}
    buildings, current_campus, in_toc = [], None, False
    for line in md.splitlines():
        if line.startswith("## 목차"):
            in_toc = True
            continue
        if in_toc and line.startswith("---"):
            break
        if not in_toc:
            continue
        m = re.match(r"- \*\*(\S+캠퍼스)\*\*", line.strip())
        if m:
            current_campus = campus_map[m.group(1)]
            continue
        m = re.match(r"- \[(.+?)\]\(#", line.strip())
        if m and current_campus:
            title = m.group(1)
            code_m = re.match(r"([SGBP]\d{1,2})\s+(.+)", title)
            if code_m:
                code, name = code_m.group(1), code_m.group(2)
            else:
                code, name = "", re.sub(r"\s*·\s*\S+캠퍼스$", "", title)
            buildings.append({"campus": current_campus, "bcode": code, "md_name": name})
    return buildings


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--offline", help="이미 내려받은 HTML 파일 경로(재현/테스트용)")
    args = ap.parse_args()

    site = parse_site(fetch_html(args.offline))
    md_buildings = parse_md_toc(MD_PATH.read_text(encoding="utf-8"))
    print(f"사이트 {len(site)}건 / md 목차 {len(md_buildings)}건")
    if len(site) != len(md_buildings):
        raise SystemExit("개수 불일치 — 사이트 갱신 시 md도 다시 정리 필요")

    norm = lambda s: re.sub(r"\s+", "", s)
    rows, mismatches = [], []
    for s, m in zip(site, md_buildings):
        campus = GUBUN_TO_CAMPUS.get(s["gubun"])
        if campus != m["campus"]:
            raise SystemExit(f"캠퍼스 불일치: {s['name']} gubun={s['gubun']} vs md={m['campus']}")
        sname, mname = norm(s["name"]), norm(m["md_name"])
        if not (sname == mname or sname in mname or mname in sname):
            mismatches.append((m["bcode"], s["name"], m["md_name"]))
        rows.append({
            "campus": campus,
            "code": m["bcode"],          # md의 건물코드(S01…); 코드 없는 시설은 빈 값
            "name": s["name"].strip(),
            "site_code": s["code"],      # 사이트 내부 코드(LOC…) — 추적용
            "lat": s["lat"],
            "lng": s["lng"],
        })

    if mismatches:
        for c, sn, mn in mismatches:
            print(f"  MISMATCH [{c}] 사이트='{sn}' vs md='{mn}'")
        raise SystemExit("이름 대조 실패 — 순서 기반 매칭을 신뢰할 수 없음")

    with OUT_CSV.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["campus", "code", "name", "site_code", "lat", "lng"])
        w.writeheader()
        w.writerows(rows)
    for campus in ("seunghak", "gudeok", "bumin"):
        n = sum(1 for r in rows if r["campus"] == campus)
        print(f"  {campus}: {n}건")
    print(f"저장: {OUT_CSV} ({len(rows)}건, 이름 대조 전부 일치)")


if __name__ == "__main__":
    main()
