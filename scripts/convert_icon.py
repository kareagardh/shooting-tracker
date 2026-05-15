"""
Draw the shooting tracker icon directly with Pillow.
SVG viewBox: 100x80  →  1024x1024 PNG with dark background.
"""
import os
from PIL import Image, ImageDraw

SIZE = 1024
CONTENT_W = 900    # fit 100-unit-wide content into 900px
CONTENT_H = 720    # 80 units × 9 px/unit

SCALE = 9.0        # px per SVG unit
OX = (SIZE - CONTENT_W) / 2   # 62  – horizontal offset
OY = (SIZE - CONTENT_H) / 2   # 152 – vertical offset

def p(x, y):
    """SVG unit → pixel coords tuple."""
    return (OX + x * SCALE, OY + y * SCALE)

def r(radius):
    return radius * SCALE

def ellipse(draw, cx, cy, radius, fill):
    rx = r(radius)
    x0, y0 = OX + cx * SCALE - rx, OY + cy * SCALE - rx
    x1, y1 = OX + cx * SCALE + rx, OY + cy * SCALE + rx
    draw.ellipse([x0, y0, x1, y1], fill=fill)

img = Image.new("RGBA", (SIZE, SIZE), (13, 17, 23, 255))   # #0D1117
draw = ImageDraw.Draw(img)

# ── target circles ──────────────────────────────────────────────
ellipse(draw, 35, 38, 30, "#e63946")
ellipse(draw, 35, 38, 22, "white")
ellipse(draw, 35, 38, 14, "#e63946")
ellipse(draw, 35, 38,  6, "white")
ellipse(draw, 35, 38,  2.5, "#e63946")

# ── crosshair lines ─────────────────────────────────────────────
lw = max(2, int(1.8 * SCALE))
draw.line([p(35, 4),  p(35, 16)], fill="#333333", width=lw)
draw.line([p(35, 60), p(35, 72)], fill="#333333", width=lw)
draw.line([p(1,  38), p(13, 38)], fill="#333333", width=lw)
draw.line([p(57, 38), p(69, 38)], fill="#333333", width=lw)

# ── list panel rect (x=52, y=44, w=44, h=34, rx=5) ──────────────
x0, y0 = p(52, 44)
x1, y1 = p(52 + 44, 44 + 34)
draw.rounded_rectangle([x0, y0, x1, y1], radius=r(5), fill="#1d3557")

# ── list rows ────────────────────────────────────────────────────
row_lw = max(2, int(2 * SCALE))
for ry in [55, 65, 75]:
    ellipse(draw, 61, ry, 2.5, "#e63946")
    draw.line([p(67, ry), p(88, ry)], fill="white", width=row_lw)

out = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons', 'app_icon_1024.png')
img.save(os.path.normpath(out), "PNG")
print(f"Saved: {os.path.normpath(out)}")
