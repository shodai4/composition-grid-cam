#!/usr/bin/env python3
"""アプリアイコン（1024×1024・アルファなし）を作る。

墨の地に、アイボリーの黄金螺旋と、ファインダーの四隅の印。
引き算だけで作り、小さい表示でも形が残る太さにする。
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

import geometry

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

SIZE = 1024
SCALE = 3
INK = (26, 26, 27)
IVORY = (249, 248, 245)

SPIRAL_LONG = 0.84      # アイコンに対する黄金矩形の長辺の比
SPIRAL_WIDTH = 0.018
TICK_INSET = 0.052      # 四隅の印までの余白
TICK_ARM = 0.078
TICK_WIDTH = 0.022
TICK_ALPHA = 0.55


def draw_spiral(draw: ImageDraw.ImageDraw, canvas: int) -> None:
    # 黄金矩形（φ × 1）の長辺をアイコンの 84% にして中央に置く
    long_side = SPIRAL_LONG * canvas
    short_side = long_side / geometry.PHI
    scale = short_side
    left = (canvas - long_side) / 2
    top = (canvas - short_side) / 2
    width = max(1, int(round(SPIRAL_WIDTH * canvas)))
    for cx, cy, radius, a0, a1 in geometry.spiral_arc_specs(geometry.PHI, 0, False):
        x = left + cx * scale
        y = top + cy * scale
        r = radius * scale
        if r < width:
            # 線の太さより小さい弧は、目の中で潰れるので描かない
            continue
        box = (x - r, y - r, x + r, y + r)
        draw.arc(box, min(a0, a1), max(a0, a1), fill=IVORY, width=width)


def draw_ticks(draw: ImageDraw.ImageDraw, canvas: int) -> None:
    color = tuple(int(c * TICK_ALPHA + INK[i] * (1 - TICK_ALPHA)) for i, c in enumerate(IVORY))
    inset = TICK_INSET * canvas
    arm = TICK_ARM * canvas
    width = max(1, int(round(TICK_WIDTH * canvas)))
    for corner_x, corner_y, dx, dy in (
        (inset, inset, 1, 1),
        (canvas - inset, inset, -1, 1),
        (inset, canvas - inset, 1, -1),
        (canvas - inset, canvas - inset, -1, -1),
    ):
        draw.line([(corner_x, corner_y), (corner_x + dx * arm, corner_y)], fill=color, width=width)
        draw.line([(corner_x, corner_y), (corner_x, corner_y + dy * arm)], fill=color, width=width)


def main() -> None:
    canvas = SIZE * SCALE
    image = Image.new("RGB", (canvas, canvas), INK)
    draw = ImageDraw.Draw(image)
    draw_ticks(draw, canvas)
    draw_spiral(draw, canvas)

    icon = image.resize((SIZE, SIZE), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / "AppIcon.png"
    icon.save(path, "PNG")
    check(icon)
    print(f"wrote {path} ({icon.size}, mode={icon.mode})")


def check(icon: Image.Image) -> None:
    """書き出したものを読み直して、約束どおりか確かめる。"""
    image = Image.open(OUT / "AppIcon.png")
    problems = []
    if image.size != (SIZE, SIZE):
        problems.append(f"大きさが {image.size}")
    if image.mode != "RGB":
        problems.append(f"アルファ付き（mode={image.mode}）")
    pixels = image.convert("RGB")
    data = list(pixels.tobytes())
    ivory = sum(1 for i in range(0, len(data), 3) if data[i] > 200 and data[i + 1] > 200 and data[i + 2] > 190)
    if ivory < SIZE * SIZE * 0.005:
        problems.append(f"線が見えない（明るい画素 {ivory}）")
    if ivory > SIZE * SIZE * 0.25:
        problems.append(f"地が埋まっている（明るい画素 {ivory}）")
    corners = [pixels.getpixel(p) for p in ((2, 2), (SIZE - 3, 2), (2, SIZE - 3), (SIZE - 3, SIZE - 3))]
    if any(max(c) > 60 for c in corners):
        problems.append(f"四隅が墨でない {corners}")
    middle = SIZE // 2
    reach = int(SIZE * 0.18)
    central = sum(
        1
        for x in range(middle - reach, middle + reach, 2)
        for y in range(middle - reach, middle + reach, 2)
        if max(pixels.getpixel((x, y))) > 150
    )
    if central < 60:
        problems.append(f"中央に螺旋が通っていない（明るい画素 {central}）")
    if problems:
        raise SystemExit("アイコンの点検に失敗: " + " / ".join(problems))
    print(f"ok  アイコン: 1024×1024, RGB, 明るい画素 {ivory / (SIZE * SIZE):.2%}")


if __name__ == "__main__":
    main()
