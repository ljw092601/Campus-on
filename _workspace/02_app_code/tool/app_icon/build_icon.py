"""Derive the launcher-icon inputs from assets/icon/donga-mate-icon.png.

The source is a 1024px rounded-square emblem with transparent corners. Both
platforms apply their own corner mask, so the corners are filled with the
emblem's blue to make a full-bleed square. For the Android adaptive
foreground the whole square is scaled down until every non-blue pixel sits
inside the 66dp safe circle and pasted onto an opaque blue layer, so no
resampled edge can show (the Android 12+ splash draws the foreground alone).
The in-app home AppBar emblem is the source itself (rounded corners kept),
downscaled to 128px.

Run from the app root:  python tool/app_icon/build_icon.py
Then:                   dart run flutter_launcher_icons
"""
import math

from PIL import Image

SRC = "assets/icon/donga-mate-icon.png"
BLUE = (47, 111, 237)  # #2F6FED, keep in sync with pubspec adaptive_icon_background
SIZE = 1024
SAFE_RADIUS = SIZE * 33 / 108  # adaptive icon safe zone: 66dp circle on 108dp
MARGIN = 0.95  # keep the artwork slightly inside the safe circle


def main():
    src = Image.open(SRC).convert("RGBA")
    assert src.size == (SIZE, SIZE), src.size

    src.resize((128, 128), Image.LANCZOS).save("assets/home/app_emblem.png")

    full = Image.new("RGBA", src.size, BLUE + (255,))
    full.alpha_composite(src)
    full.convert("RGB").save("assets/icon/app_icon.png")

    # Farthest artwork pixel (anything clearly not background blue) from centre.
    px = full.load()
    c = (SIZE - 1) / 2
    reach = 0.0
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, _ = px[x, y]
            if abs(r - BLUE[0]) + abs(g - BLUE[1]) + abs(b - BLUE[2]) > 60:
                reach = max(reach, math.hypot(x - c, y - c))

    scale = min(1.0, SAFE_RADIUS * MARGIN / reach)
    side = round(SIZE * scale)
    fg = Image.new("RGBA", (SIZE, SIZE), BLUE + (255,))
    off = (SIZE - side) // 2
    fg.paste(full.resize((side, side), Image.LANCZOS).convert("RGB"), (off, off))
    fg.save("assets/icon/app_icon_adaptive_fg.png")
    print(f"artwork reach {reach:.0f}px -> adaptive scale {scale:.3f}")


if __name__ == "__main__":
    main()
