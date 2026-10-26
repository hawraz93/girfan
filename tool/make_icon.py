"""Draws the Girfan (گیرفان, "pocket") logo and writes every launcher icon.

    python3 tool/make_icon.py

Outputs assets/icon/{icon,foreground,logo}.png plus the Android mipmaps,
adaptive-icon foregrounds and the iOS AppIcon set. Needs Pillow.
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SS = 4  # supersampling factor
N = 1024 * SS

NAVY_TOP = (22, 48, 94)
NAVY_BOTTOM = (9, 21, 48)
EMERALD_TOP = (52, 211, 153)
EMERALD_BOTTOM = (5, 150, 105)
CARD = (236, 253, 245)
CARD_BACK = (110, 231, 183)
STITCH = (3, 38, 25)
ADAPTIVE_BG = "#0E2147"


def _s(v):
    return int(v * SS)


def _rounded_mask(poly, radius):
    """Polygon mask with rounded corners (blur + threshold)."""
    m = Image.new("L", (N, N), 0)
    ImageDraw.Draw(m).polygon([(_s(x), _s(y)) for x, y in poly], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(_s(radius)))
    return m.point(lambda v: 255 if v > 128 else 0)


def _vgradient(top, bottom, y0, y1):
    g = Image.new("RGB", (N, N))
    d = ImageDraw.Draw(g)
    for y in range(N):
        t = min(max((y - _s(y0)) / max(_s(y1 - y0), 1), 0), 1)
        d.line([(0, y), (N, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return g


def _card(layer, cx, cy, w, h, angle, color):
    c = Image.new("RGBA", (_s(w) + 8, _s(h) + 8), (0, 0, 0, 0))
    ImageDraw.Draw(c).rounded_rectangle(
        [4, 4, _s(w) + 4, _s(h) + 4], radius=_s(34), fill=color + (255,)
    )
    # chip stripe so it reads as a bank card
    ImageDraw.Draw(c).rounded_rectangle(
        [_s(40), _s(46), _s(118), _s(98)], radius=_s(12), fill=(16, 185, 129, 255)
    )
    c = c.rotate(angle, resample=Image.BICUBIC, expand=True)
    layer.alpha_composite(c, (_s(cx) - c.width // 2, _s(cy) - c.height // 2))


def _dashed(draw, pts, dash, gap, width, fill):
    import math

    carry = 0.0
    on = True
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        seg = math.dist((x0, y0), (x1, y1))
        pos = 0.0
        while pos < seg:
            step = (dash if on else gap) - carry
            end = min(pos + step, seg)
            if on:
                a = (x0 + (x1 - x0) * pos / seg, y0 + (y1 - y0) * pos / seg)
                b = (x0 + (x1 - x0) * end / seg, y0 + (y1 - y0) * end / seg)
                draw.line([(_s(a[0]), _s(a[1])), (_s(b[0]), _s(b[1]))], fill=fill, width=_s(width))
            if end - pos < step:
                carry += end - pos
            else:
                carry = 0.0
                on = not on
            pos = end


def artwork():
    """Pocket with a card tucked in, on a transparent 1024 canvas."""
    layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    _card(layer, 470, 330, 300, 196, 14, CARD_BACK)
    _card(layer, 548, 318, 320, 206, -9, CARD)

    pocket = [(282, 400), (742, 400), (722, 660), (512, 800), (302, 660)]
    mask = _rounded_mask(pocket, 22)
    body = _vgradient(EMERALD_TOP, EMERALD_BOTTOM, 400, 800).convert("RGBA")
    shadow = mask.filter(ImageFilter.GaussianBlur(_s(26)))
    shade = Image.new("RGBA", (N, N), (2, 10, 30, 0))
    shade.putalpha(shadow.point(lambda v: int(v * 0.55)))
    layer.alpha_composite(shade, (0, _s(18)))
    pocket_img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    pocket_img.paste(body, (0, 0), mask)
    layer.alpha_composite(pocket_img)

    d = ImageDraw.Draw(layer)
    stitch = STITCH + (80,)
    _dashed(d, [(320, 446), (704, 446)], 26, 16, 8, stitch)
    _dashed(d, [(332, 478), (346, 636), (512, 748), (678, 636), (692, 478)], 26, 16, 8, stitch)
    return layer


def background():
    # Diagonal navy gradient: lighter at the top-left, deep at the bottom-right.
    t = Image.linear_gradient("L").resize((N * 2, N * 2)).rotate(45, resample=Image.BICUBIC)
    t = t.crop((N // 2, N // 2, N // 2 + N, N // 2 + N))
    bg = Image.composite(
        Image.new("RGBA", (N, N), NAVY_BOTTOM + (255,)),
        Image.new("RGBA", (N, N), NAVY_TOP + (255,)),
        t,
    )
    glow = Image.new("L", (N, N), 0)
    ImageDraw.Draw(glow).ellipse([_s(560), _s(-260), _s(1300), _s(480)], fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(_s(120)))
    tint = Image.new("RGBA", (N, N), EMERALD_TOP + (0,))
    tint.putalpha(glow)
    bg.alpha_composite(tint)
    return bg


def scaled(img, factor, dy=0):
    w = int(N * factor)
    small = img.resize((w, w), Image.LANCZOS)
    out = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    out.alpha_composite(small, ((N - w) // 2, (N - w) // 2 + _s(dy)))
    return out


def save(img, path, size, rgb=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if rgb:
        out = out.convert("RGB")
    out.save(path, optimize=True)


def main():
    art = artwork()
    icon = background()
    icon.alpha_composite(scaled(art, 1.0, dy=-28))

    fg = scaled(art, 1.32, dy=-30)

    # In-app logo: rounded square with the full icon.
    logo_mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(logo_mask).rounded_rectangle([0, 0, N - 1, N - 1], radius=_s(230), fill=255)
    logo = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    logo.paste(icon, (0, 0), logo_mask)

    a = ROOT / "assets/icon"
    save(icon, a / "icon.png", 1024, rgb=True)
    save(fg, a / "foreground.png", 1024)
    save(logo, a / "logo.png", 512)

    res = ROOT / "android/app/src/main/res"
    for name, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        save(icon, res / f"mipmap-{name}/ic_launcher.png", px, rgb=True)
    for name, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
        save(fg, res / f"drawable-{name}/ic_launcher_foreground.png", px)
    colors = res / "values/colors.xml"
    colors.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
        f'    <color name="ic_launcher_background">{ADAPTIVE_BG}</color>\n</resources>\n'
    )

    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for img in json.loads((ios / "Contents.json").read_text())["images"]:
        base = float(img["size"].split("x")[0])
        px = round(base * int(img["scale"].rstrip("x")))
        save(icon, ios / img["filename"], px, rgb=True)

    ico = icon.resize((256, 256), Image.LANCZOS)
    ico.save(ROOT / "windows/runner/resources/app_icon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("icons written")


if __name__ == "__main__":
    main()
