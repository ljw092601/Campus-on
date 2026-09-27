# -*- coding: utf-8 -*-
"""extract_rooms.py 결과(raw_rooms.json) + 수동 보정(overrides.json)으로 앱 에셋을 만든다.

출력:
  assets/floorplans/<건물>_<층>.webp   — 도면 (가로 최대 2400px, 무손실 WebP)
  assets/floorplans/floorplans.json    — {건물코드: {층: {image, w, h, rooms: {호수: [x, y, (rx, ry, rw, rh)]}}}}
                                          좌표는 모두 이미지 크기 대비 비율(0..1)

사용법:  python build_floorplans.py <도면화 폴더> <raw_rooms.json>
  예)    python build_floorplans.py ../../../../도면화 raw_rooms.json

규칙:
  - 파일명은 <건물>_<층>: S04_3F, B02_B1(지하 1층), B04A_10F(동이 나뉜 건물은 동 문자까지 건물코드).
  - 호수는 0301 / 0306-1 / 0101-A (앞 2자리 = 층), 지하는 B101 / B110-1 (B + 지하층 + 2자리).
    층과 어긋나면 경고 후 제외한다 (도면 오타 가능성 — overrides.json의 rename으로 바로잡고,
    059-1처럼 형식 밖이지만 실제 호수인 것은 allow에 넣는다).
  - 한 방 영역에서 여러 호수가 읽힌 경우(영역이 붙어 있음) 사각형은 빼고 점만 남긴다.
  - 호수가 하나도 없는 층(도서관 열람실 등)은 에셋에서 뺀다.

⚠️ floorplans.json은 이 스크립트로만 재생성한다(수동 편집 금지 — 보정은 overrides.json).
"""
import io
import json
import re
import sys
from pathlib import Path

from PIL import Image

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

SCRIPT_DIR = Path(__file__).resolve().parent
APP_ROOT = SCRIPT_DIR.parents[1]  # 02_app_code/
OUT_DIR = APP_ROOT / "assets" / "floorplans"
OVERRIDES = SCRIPT_DIR / "overrides.json"
MAX_WIDTH = 2400
# group(1) = 지상층 2자리, group(2) = 지하층 1자리
CODE = re.compile(r"^(?:(\d{2})\d{2}|B(\d)\d{2})(?:-(?:\d{1,2}|[A-Z]))?$")
KEY = re.compile(r"^([SGB]\d{2}[AB]?)_(B?)(\d+)F?$", re.I)


def code_on_floor(code: str, basement: bool, floor_no: int) -> bool:
    m = CODE.match(code)
    if m is None:
        return False
    if basement:
        return m.group(2) is not None and int(m.group(2)) == floor_no
    return m.group(1) is not None and int(m.group(1)) == floor_no


def main(src_dir: Path, raw_path: Path) -> None:
    raw = json.loads(raw_path.read_text(encoding="utf-8"))
    overrides = json.loads(OVERRIDES.read_text(encoding="utf-8")) if OVERRIDES.exists() else {}
    # 파일명 → 경로 (B04/A동/B04A_3F.png처럼 하위 폴더 포함)
    images = {p.stem.upper(): p for p in sorted(src_dir.glob("**/*.png"))}

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for old in OUT_DIR.glob("*.webp"):
        old.unlink()

    index: dict = {}
    warnings = []
    for key in sorted(raw):
        m = KEY.match(key)
        if not m:
            warnings.append(f"{key}: 파일명 형식 아님 — 건너뜀")
            continue
        building = m.group(1).upper()
        basement = bool(m.group(2))
        floor_no = int(m.group(3))
        floor = f"B{floor_no}F" if basement else f"{floor_no}F"
        ov = overrides.get(key, {})
        rename = ov.get("rename", {})
        drop = set(ov.get("drop", []))
        allow = set(ov.get("allow", []))

        rooms: dict = {}
        for r in raw[key]["rooms"]:
            code = r.get("code")
            if not code:
                continue
            code = rename.get(code, code)
            if code in drop:
                continue
            if not code_on_floor(code, basement, floor_no) and code not in allow:
                warnings.append(f"{key}: '{code}' 층/형식 불일치 — 제외")
                continue
            if code in rooms:
                warnings.append(f"{key}: '{code}' 중복 — 첫 번째만 사용")
                continue
            entry = [r["x"], r["y"]]
            if r.get("n", 1) == 1:
                entry += r["rect"]
            rooms[code] = entry
        for code, xy in ov.get("add", {}).items():
            rooms[code] = xy

        if not rooms:
            continue
        src = images.get(key.upper())
        if src is None:
            warnings.append(f"{key}: 원본 이미지 없음 — 건너뜀")
            continue
        im = Image.open(src).convert("RGB")
        if im.width > MAX_WIDTH:
            im = im.resize((MAX_WIDTH, round(im.height * MAX_WIDTH / im.width)), Image.LANCZOS)
        name = f"{building}_{floor}.webp"
        im.save(OUT_DIR / name, "WEBP", lossless=True, method=6)

        index.setdefault(building, {})[floor] = {
            "image": f"assets/floorplans/{name}",
            "w": im.width,
            "h": im.height,
            "rooms": dict(sorted(rooms.items())),
        }
        print(f"{key}: {len(rooms)}실")

    (OUT_DIR / "floorplans.json").write_text(
        json.dumps(index, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    total = sum(len(f["rooms"]) for b in index.values() for f in b.values())
    print(f"\n건물 {len(index)}개, 층 {sum(len(b) for b in index.values())}개, 호실 {total}개")
    if warnings:
        print("\n[경고]")
        for w in warnings:
            print(" -", w)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    main(Path(sys.argv[1]), Path(sys.argv[2]))
