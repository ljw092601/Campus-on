import sys, json, re, glob, os
import numpy as np
from PIL import Image
from scipy import ndimage
from rapidocr_onnxruntime import RapidOCR
eng = RapidOCR()
ROOT = 'C:/Users/ljw09/Desktop/Campus-on/도면화'
FILL = np.array([221,241,255])
WC = np.array([200,242,229])
# 0301, 059-1, 0306-1, 0101-A, B101(지하 1층), B110-1
CODE = re.compile(r'^(?:B\d{3}|\d{3,4})(?:-(?:\d{1,2}|[A-Z]))?$')
# 건물 접두어 (S07 / 507 / B02 / B04(A) / S11)
PREFIX = re.compile(r'^[SGB5$][O0]\d{1,2}(\([AB]\))?$')

def ocr(img):
    res, _ = eng(np.array(img))
    toks = []
    for box, txt, sc in (res or []):
        xs=[p[0] for p in box]; ys=[p[1] for p in box]
        toks.append(dict(t=txt.replace(' ',''), x0=min(xs), x1=max(xs), y0=min(ys), y1=max(ys)))
    toks.sort(key=lambda k:(k['y0'],k['x0']))
    return toks

def parse(toks):
    parts = []
    for k in toks:
        # 영문 세부번호 OCR 보정: 0101-l → 0101-I, 소문자 → 대문자
        k['t'] = re.sub(r'-([a-z])$', lambda m: '-' + ('I' if m.group(1) == 'l' else m.group(1).upper()), k['t'])
        if PREFIX.match(k['t']): continue
        if k['t'].startswith('-') and parts:
            p = parts[-1]; p['t'] += k['t']
            p['x0']=min(p['x0'],k['x0']); p['x1']=max(p['x1'],k['x1']); p['y1']=max(p['y1'],k['y1'])
        else: parts.append(dict(k))
    raw = ' '.join(p['t'] for p in parts)
    # "0101 ?" = suffix still to be confirmed on the drawing: not searchable
    if '?' in raw:
        return [], raw
    return [p for p in parts if CODE.match(p['t'])], raw

def process(path):
    im = Image.open(path).convert('RGB')
    a = np.asarray(im).astype(int)
    W, H = im.size
    # room fill (light blue) + restroom fill (mint); restrooms carry codes too
    mask = (np.abs(a - FILL).sum(axis=2) < 30) | (np.abs(a - WC).sum(axis=2) < 30)
    lab, n = ndimage.label(mask)
    sizes = ndimage.sum(mask, lab, range(n+1))
    out = []
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        if sizes[i] < 3000: continue
        ys, xs = sl
        h, w = ys.stop-ys.start, xs.stop-xs.start
        if w < 40 or h < 40: continue
        comp = lab[sl] == i
        filled = ndimage.binary_fill_holes(comp)
        holes, hn = ndimage.label(filled & ~comp)
        keep = filled.copy()
        # a hole that contains another room's fill is a nested room, not text
        other = (lab[sl] != 0) & (lab[sl] != i) & (sizes[lab[sl]] > 1500)
        blank = np.zeros_like(comp)
        for j in range(1, hn+1):
            if (other & (holes == j)).any():
                keep[holes == j] = False; blank |= holes == j
        # other rooms' fill + their labels: blank nested holes; outside-bbox
        # neighbours only lose their fill (labels touching walls must survive
        # in tiny rooms whose text isn't a hole)
        # OCR only this room: its hole-filled area (labels are holes) plus a
        # thin band around it for labels touching walls in tiny rooms
        near = ndimage.binary_dilation(comp, iterations=12) | keep
        crop = np.asarray(im)[sl].copy()
        crop[~near | blank | other] = 255
        scale = 1.0
        if min(w, h) < 200: scale = 200/min(w,h)
        img = Image.fromarray(crop)
        if scale != 1.0: img = img.resize((int(w*scale), int(h*scale)), Image.LANCZOS)
        codes, raw = parse(ocr(img))
        cy, cx = ndimage.center_of_mass(keep)
        for c in codes:
            lx = xs.start + (c['x0']+c['x1'])/2/scale; ly = ys.start + (c['y0']+c['y1'])/2/scale
            out.append(dict(code=c['t'], x=round(lx/W,4), y=round(ly/H,4),
                            rect=[round(xs.start/W,4), round(ys.start/H,4), round(w/W,4), round(h/H,4)], n=len(codes)))
        if not codes:
            out.append(dict(code=None, raw=raw, x=round((xs.start+cx)/W,4), y=round((ys.start+cy)/H,4),
                            rect=[round(xs.start/W,4), round(ys.start/H,4), round(w/W,4), round(h/H,4)]))
    return dict(width=W, height=H, rooms=out)

def fullscan(path):
    found = set()
    for k in ocr(Image.open(path).convert('RGB')):
        for m in re.finditer(r'(?:B\d{3}|\d{4})(?:-(?:\d{1,2}|[A-Z]))?', k['t']): found.add(m.group(0))
    return found

files = sys.argv[1:] or sorted(glob.glob(ROOT+'/*/*.png'))
try: result = json.load(open(os.environ.get('OUT','raw_rooms.json'),encoding='utf-8'))
except Exception: result = {}
for f in files:
    key = os.path.basename(f)[:-4]
    result[key] = process(f)
    rs = result[key]['rooms']
    full = fullscan(f)
    got = {r['code'] for r in rs if r['code']}
    result[key]['fullonly'] = sorted(full - got)
    print('  full-scan-only:', sorted(full-got), ' extract-only:', sorted(got-full))
    from collections import Counter
    cnt = Counter(r['code'] for r in rs if r['code'])
    print(key, 'rooms', len(cnt), 'dup', [k for k,v in cnt.items() if v>1],
          'multi', sorted({r['code'] for r in rs if r.get('n',1)>1}),
          'unlabeled', [r['raw'] for r in rs if not r['code'] and r['raw']], flush=True)
json.dump(result, open(os.environ.get('OUT','raw_rooms.json'),'w',encoding='utf-8'), ensure_ascii=False, indent=1)
