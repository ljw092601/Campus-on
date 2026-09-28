# -*- coding: utf-8 -*-
"""extract_rooms.py 결과(raw_rooms.json) + 수동 보정(overrides.json)으로 앱 에셋을 만든다.

출력:
  assets/floorplans/<건물>_<층>.webp   — 도면 (가로 최대 2400px, 무손실 WebP)
  assets/floorplans/floorplans.json    — {건물코드: {층: {image, w, h, rooms: {호수: 방}}}}
      방 = {"x": x, "y": y, "r": [rx, ry, rw, rh], "o": [x1, y1, x2, y2, ...]}
        x, y  라벨 중심(빨간 점 위치)
        r     방 바운딩 사각형 (모를 때 생략)
        o     방의 실제 외곽선 폴리곤, x·y를 번갈아 늘어놓은 평탄 리스트
              (마지막 점→첫 점으로 닫힘, 첫 점 반복 없음; 모를 때 생략)
      좌표는 모두 이미지 크기 대비 비율(0..1, 소수 4자리)

사용법:  python build_floorplans.py <도면화 폴더> <raw_rooms.json>
  예)    python build_floorplans.py ../../../../도면화 raw_rooms.json

규칙:
  - 파일명은 <건물>_<층>: S04_3F, B02_B1(지하 1층), B04A_10F(동이 나뉜 건물은 동 문자까지 건물코드).
  - 호수는 0301 / 0306-1 / 0101-A (앞 2자리 = 층), 지하는 B101 / B110-1 (B + 지하층 + 2자리).
    층과 어긋나면 경고 후 제외한다 (도면 오타 가능성 — overrides.json의 rename으로 바로잡고,
    059-1처럼 형식 밖이지만 실제 호수인 것은 allow에 넣는다).
  - 한 방 영역에서 여러 호수가 읽힌 경우(영역이 붙어 있음) 사각형은 빼고 점만 남긴다.
  - 호수가 하나도 없는 층(도서관 열람실 등)은 에셋에서 뺀다.
  - 외곽선(o): 사각형이 있는 방마다 원본 해상도 도면에서 채움색 연결요소를 다시 구해
    (extract_rooms.py와 같은 규칙) 사각형과 바운딩박스가 가장 잘 맞는 요소를 고르고,
    벽·문에 닿아 홈을 파는 라벨 글자(남색)를 방에 붙이고, 글자 구멍은 메우되
    다른 방이 들어 있는 구멍(중첩 방)은 빼고, 바깥 윤곽을
    추적해 Douglas-Peucker(OUTLINE_EPS px)로 단순화한다. ㄱ자 방처럼 사각형이 이웃 방을
    덮는 경우에도 외곽선은 실제 방 모양만 따라간다.

⚠️ floorplans.json은 이 스크립트로만 재생성한다(수동 편집 금지 — 보정은 overrides.json).
"""
import io
import json
import re
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

SCRIPT_DIR = Path(__file__).resolve().parent
APP_ROOT = SCRIPT_DIR.parents[1]  # 02_app_code/
OUT_DIR = APP_ROOT / "assets" / "floorplans"
OVERRIDES = SCRIPT_DIR / "overrides.json"
MAX_WIDTH = 2400
# group(1) = 지상층 2자리, group(2) = 지하층 1자리
CODE = re.compile(r"^(?:(\d{2})\d{2}|B(\d)\d{2})(?:-(?:\d{1,2}|[A-Z]))?$")
KEY = re.compile(r"^([SGB]\d{2}[AB]?)_(B?)(\d+)F?$", re.I)
# extract_rooms.py와 같은 채움색 (하늘색 호실, 민트색 화장실)
FILL = np.array([221, 241, 255])
WC = np.array([200, 242, 229])
FILL_TOL = 30
NESTED_MIN = 1500  # 이보다 큰 다른 채움 요소가 든 구멍 = 중첩 방
MATCH_MIN_IOU = 0.6  # 사각형 ↔ 요소 바운딩박스 IoU 하한
OUTLINE_EPS = 2.5  # Douglas-Peucker 허용 오차 (원본 px)
TEXT_MAX_SUM = 300  # 라벨 글자색 (22,56,103) 판정: RGB 합이 이 값 미만
TEXT_GROW = 3  # 글자 핵심에서 안티앨리어싱 테두리까지 넓히는 px
WIN_MARGIN = 40  # 방 주변 작업 창 여유 (px)


def code_on_floor(code: str, basement: bool, floor_no: int) -> bool:
    m = CODE.match(code)
    if m is None:
        return False
    if basement:
        return m.group(2) is not None and int(m.group(2)) == floor_no
    return m.group(1) is not None and int(m.group(1)) == floor_no


class Outliner:
    """원본 도면 한 장의 채움 영역에서 방 외곽선을 뽑는다."""

    def __init__(self, path: Path):
        a = np.asarray(Image.open(path).convert("RGB")).astype(np.int16)
        self.h, self.w = a.shape[:2]
        mask = (np.abs(a - FILL).sum(axis=2) < FILL_TOL) | (np.abs(a - WC).sum(axis=2) < FILL_TOL)
        self.lab, n = ndimage.label(mask)
        self.sizes = ndimage.sum(mask, self.lab, range(n + 1))
        self.slices = ndimage.find_objects(self.lab)
        # 라벨 글자(남색) 핵심 픽셀 — 벽색(합 ~446)보다 확연히 어둡다
        self.text = a.sum(axis=2) < TEXT_MAX_SUM

    def _match(self, rect):
        """사각형과 바운딩박스가 가장 잘 맞는 채움 요소 번호 (없으면 None)."""
        W, H = self.w, self.h
        x0, y0 = rect[0] * W, rect[1] * H
        x1, y1 = x0 + rect[2] * W, y0 + rect[3] * H
        sub = self.lab[max(0, int(y0)):min(H, int(np.ceil(y1))), max(0, int(x0)):min(W, int(np.ceil(x1)))]
        ids, counts = np.unique(sub[sub > 0], return_counts=True)
        best, best_key = None, None
        for i, c in zip(ids, counts):
            ys, xs = self.slices[i - 1]
            ix = max(0.0, min(x1, xs.stop) - max(x0, xs.start))
            iy = max(0.0, min(y1, ys.stop) - max(y0, ys.start))
            inter = ix * iy
            union = (x1 - x0) * (y1 - y0) + (xs.stop - xs.start) * (ys.stop - ys.start) - inter
            iou = inter / union if union else 0.0
            key = (iou, c)
            if best_key is None or key > best_key:
                best, best_key = int(i), key
        if best is None or best_key[0] < MATCH_MIN_IOU:
            return None
        return best

    def outline(self, rect):
        i = self._match(rect)
        if i is None:
            return None
        cys, cxs = self.slices[i - 1]
        ys = slice(max(0, cys.start - WIN_MARGIN), min(self.h, cys.stop + WIN_MARGIN))
        xs = slice(max(0, cxs.start - WIN_MARGIN), min(self.w, cxs.stop + WIN_MARGIN))
        lab = self.lab[ys, xs]
        comp = lab == i
        # 벽·문에 닿은 라벨 글자는 구멍이 아니라 홈으로 파이므로, 방에 닿은 글자
        # (+안티앨리어싱 테두리)를 방에 붙인다. 다른 방 글자는 벽에 막혀 안 닿는다.
        text = ndimage.binary_dilation(self.text[ys, xs], iterations=TEXT_GROW) & (lab == 0)
        grown, _ = ndimage.label(comp | text)
        region = grown == grown[comp][0]
        keep = ndimage.binary_fill_holes(region)
        holes, hn = ndimage.label(keep & ~region)
        if hn:
            # 다른 방의 채움이 든 구멍 = 중첩 방 → 빼기 (라벨 글자 구멍만 메운다)
            other = (lab != 0) & (lab != i) & (self.sizes[lab] > NESTED_MIN)
            for j in np.unique(holes[other]):
                if j:
                    keep[holes == j] = False
        img = np.pad(keep.astype(np.uint8), 1)
        contours, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        if not contours:
            return None
        c = max(contours, key=cv2.contourArea)
        poly = cv2.approxPolyDP(c, OUTLINE_EPS, True).reshape(-1, 2)
        if len(poly) < 3:
            return None
        out = []
        for px, py in poly:
            # 패딩 1px 보정 + 경계 픽셀 중심(+0.5)을 연속 좌표로
            out.append(round((xs.start + px - 1 + 0.5) / self.w, 4))
            out.append(round((ys.start + py - 1 + 0.5) / self.h, 4))
        return out


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
    missing = []  # 사각형은 있는데 외곽선을 못 찾은 방
    outlined = 0
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
            entry = {"x": r["x"], "y": r["y"]}
            if r.get("n", 1) == 1:
                entry["r"] = r["rect"]
            rooms[code] = entry
        for code, v in ov.get("add", {}).items():
            # overrides.json은 [x, y, (rx, ry, rw, rh)] 리스트 형식 유지
            entry = {"x": v[0], "y": v[1]}
            if len(v) == 6:
                entry["r"] = v[2:]
            rooms[code] = entry

        if not rooms:
            continue
        src = images.get(key.upper())
        if src is None:
            warnings.append(f"{key}: 원본 이미지 없음 — 건너뜀")
            continue
        outliner = Outliner(src)
        for code, entry in rooms.items():
            if "r" not in entry:
                continue
            o = outliner.outline(entry["r"])
            if o is None:
                missing.append(f"{key}: '{code}'")
            else:
                entry["o"] = o
                outlined += 1
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
    print(f"외곽선 {outlined}개")
    if missing:
        print("\n[외곽선 없음 — 사각형은 있음]")
        for w in missing:
            print(" -", w)
    if warnings:
        print("\n[경고]")
        for w in warnings:
            print(" -", w)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    main(Path(sys.argv[1]), Path(sys.argv[2]))
