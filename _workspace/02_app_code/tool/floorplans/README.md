# 강의실 검색 도면 파이프라인

`도면화/<건물>/<건물>_<층>F.png` (디자인 도면) → `assets/floorplans/` (앱 에셋)

1. **extract_rooms.py** — 방 채움색(하늘색 호실·민트색 화장실)으로 방 영역을 나누고,
   방마다 OCR(rapidocr)로 호수를 읽어 라벨 중심(빨간 점 위치)·방 사각형을 비율 좌표로 저장.
   전체 이미지 OCR과 교차 비교해 누락 후보를 출력한다.

   ```
   pip install --user rapidocr_onnxruntime pillow numpy scipy
   OUT=raw_rooms.json python extract_rooms.py ../../../../도면화/*/*.png ../../../../도면화/B04/*/*.png
   ```

   - 호수 형식: `0301`, `0306-1`, `0101-A`, 지하 `B101`·`B110-1`. 파일명은 `S04_3F`, `B02_B1`(지하),
     동이 나뉜 건물은 `B04A_3F`처럼 동 문자까지 건물코드로 쓴다.
   - `0101 ?`처럼 `?`가 있는 방은 세부번호 미확정으로 보고 제외한다.
2. **overrides.json** — OCR 보정 (`rename` 오인식 교정, `drop` 제외, `allow` 형식 밖 실제 호수, `add` 수동 좌표
   `[x, y, rx, ry, rw, rh]`). 세로쓰기 라벨 등 OCR 불가 항목은 여기서 추가한다.
3. **build_floorplans.py** — 호수 형식/층 일치 검증 후 WebP(가로 2400px, 무손실) +
   `floorplans.json` 생성.

   ```
   python build_floorplans.py ../../../../도면화 raw_rooms.json
   ```

도면이 추가·수정되면 1→3을 다시 돌리고, 경고 목록과 점 위치를 눈으로 확인한다.
