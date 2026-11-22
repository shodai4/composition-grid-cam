#!/usr/bin/env python3
"""構図カメラの計算を Python に写したもの。

Swift 側（PreviewGeometry / GridGeometry / LevelMath）と同じ式を持ち、
検算・アイコン生成・見本の描画で共有する。数値はすべて
「枠を (0,0)〜(ratio,1) とした座標」（y は下向き）で扱う。
"""

import math

PHI = 1.6180339887498949
GOLDEN_FRACTION = 0.6180339887498949


# --- 号数 ---------------------------------------------------------------

class Preset:
    def __init__(self, name, short_side, long_side):
        self.name = name
        self.short_side = short_side
        self.long_side = long_side

    @property
    def ratio(self):
        if self.short_side <= 0 or self.long_side <= 0:
            return 1.0
        return self.long_side / self.short_side

    @property
    def dimension(self):
        if self.short_side <= 0:
            return "1 : 1"
        return f"{self.long_side} × {self.short_side}"

    def __repr__(self):
        return f"Preset({self.name})"


PRESETS = [
    Preset("1:1", 0, 0),
    Preset("F3", 220, 273),
    Preset("F5", 250, 350),
    Preset("F6", 318, 410),
    Preset("F8", 380, 455),
    Preset("F10", 455, 530),
    Preset("F12", 500, 606),
    Preset("P3", 190, 273),
    Preset("P5", 240, 350),
    Preset("P6", 273, 410),
    Preset("P8", 300, 455),
    Preset("P10", 350, 530),
    Preset("M3", 170, 273),
    Preset("M5", 220, 350),
    Preset("M6", 242, 410),
    Preset("M10", 300, 530),
    Preset("S6", 410, 410),
]

INITIAL_PRESET = next(p for p in PRESETS if p.name == "F6")


# --- 割り付け -----------------------------------------------------------

def fit_rect(aspect, size):
    """幅 ÷ 高さ = aspect の矩形を、与えられた領域の中央に収める。"""
    width, height = size
    if width <= 0 or height <= 0 or aspect <= 0:
        return (0.0, 0.0, 0.0, 0.0)
    w = min(width, height * aspect)
    h = w / aspect
    return ((width - w) / 2, (height - h) / 2, w, h)


def frame_rect(canvas_ratio, video_rect):
    x, y, w, h = video_rect
    if w <= 0 or h <= 0:
        return (0.0, 0.0, 0.0, 0.0)
    fx, fy, fw, fh = fit_rect(canvas_ratio, (w, h))
    return (x + fx, y + fy, fw, fh)


def normalized(rect, container):
    cx, cy, cw, ch = container
    if cw <= 0 or ch <= 0:
        return (0.0, 0.0, 0.0, 0.0)
    return ((rect[0] - cx) / cw, (rect[1] - cy) / ch, rect[2] / cw, rect[3] / ch)


def pixel_rect(norm, image_size):
    """0〜1 の割合を画素の矩形に直す（Swift の pixelRect と同じ丸め）。"""
    width = max(1.0, float(image_size[0]))
    height = max(1.0, float(image_size[1]))
    nx = min(max(norm[0], 0.0), 1.0)
    ny = min(max(norm[1], 0.0), 1.0)
    nw = min(max(norm[2], 0.0), 1.0 - nx)
    nh = min(max(norm[3], 0.0), 1.0 - ny)
    x = math.floor(nx * width)
    y = math.floor(ny * height)
    w = round_half_away(nw * width)
    h = round_half_away(nh * height)
    w = min(max(w, 1.0), width - x)
    h = min(max(h, 1.0), height - y)
    return (x, y, w, h)


def round_half_away(value):
    """Swift の .rounded()（0 から遠い側へ四捨五入）に合わせる。"""
    if value >= 0:
        return float(math.floor(value + 0.5))
    return float(math.ceil(value - 0.5))


def video_unit_rect(video_aspect):
    """保存用。映像の縦横比を保ったまま高さ 1 の矩形にする。"""
    return (0.0, 0.0, video_aspect, 1.0)


def normalized_frame(canvas_ratio, video_aspect):
    """枠を、映像全体に対する 0〜1 の割合で返す。"""
    video = video_unit_rect(video_aspect)
    return normalized(frame_rect(canvas_ratio, video), video)


# --- 構図線 -------------------------------------------------------------

def thirds(ratio):
    strokes = []
    for i in (1, 2):
        x = ratio * i / 3
        strokes.append([(x, 0.0), (x, 1.0)])
        y = i / 3
        strokes.append([(0.0, y), (ratio, y)])
    return strokes


def golden(ratio):
    strokes = []
    for f in (1 - GOLDEN_FRACTION, GOLDEN_FRACTION):
        x = ratio * f
        strokes.append([(x, 0.0), (x, 1.0)])
        strokes.append([(0.0, f), (ratio, f)])
    return strokes


def diagonal(ratio):
    return [
        [(0.0, 0.0), (ratio, 1.0)],
        [(ratio, 0.0), (0.0, 1.0)],
    ]


def horizon(ratio):
    return [
        [(0.0, 1 / 3), (ratio, 1 / 3)],
        [(0.0, 0.5), (ratio, 0.5)],
        [(0.0, 2 / 3), (ratio, 2 / 3)],
    ]


def rotate(vector, degrees):
    radians = math.radians(degrees)
    c, s = math.cos(radians), math.sin(radians)
    return (vector[0] * c - vector[1] * s, vector[0] * s + vector[1] * c)


def spiral(ratio, orientation=0, mirrored=False, samples=64, limit=24):
    """黄金螺旋。黄金矩形（φ × 1）を枠の中に置き、四分円を内側へ巻く。"""
    orientation = orientation % 4
    base_w, base_h = PHI, 1.0
    if orientation % 2 == 0:
        scale = min(1.0, ratio / PHI)
    else:
        scale = min(ratio, 1.0 / PHI)
    center = (ratio / 2, 0.5)
    base_center = (base_w / 2, base_h / 2)

    def place(point):
        dx, dy = point[0] - base_center[0], point[1] - base_center[1]
        if mirrored:
            dx = -dx
        for _ in range(orientation):
            dx, dy = -dy, dx
        return (center[0] + dx * scale, center[1] + dy * scale)

    strokes = []
    x = y = 0.0
    w, h = base_w, base_h
    point = (0.0, 0.0)
    tangent = (0.0, 1.0)
    omega = -1.0
    order = "LBRT"

    for index in range(limit):
        side = min(w, h)
        if side <= 0.002:
            break
        back = rotate(tangent, -90)
        ux, uy = omega * back[0], omega * back[1]
        c = (point[0] - side * ux, point[1] - side * uy)
        start = math.atan2(point[1] - c[1], point[0] - c[0])

        points = []
        for step in range(samples + 1):
            t = step / samples
            angle = start + omega * (math.pi / 2) * t
            points.append(place((c[0] + side * math.cos(angle),
                                 c[1] + side * math.sin(angle))))
        strokes.append(points)

        end_direction = rotate((ux, uy), omega * 90)
        point = (c[0] + side * end_direction[0], c[1] + side * end_direction[1])
        tangent = rotate(tangent, omega * 90)

        direction = order[index % 4]
        if direction == "L":
            x += side
            w -= side
        elif direction == "B":
            h -= side
        elif direction == "R":
            w -= side
        elif direction == "T":
            y += side
            h -= side

    return strokes


def spiral_arc_specs(ratio, orientation=0, mirrored=False, limit=24):
    """黄金螺旋を「弧のまま」返す。icon のように ImageDraw.arc で描くとき用。
    返り値は (中心x, 中心y, 半径, 開始角度, 終了角度)。角度は度、y 下向き。
    """
    orientation = orientation % 4
    base_w, base_h = PHI, 1.0
    if orientation % 2 == 0:
        scale = min(1.0, ratio / PHI)
    else:
        scale = min(ratio, 1.0 / PHI)
    center = (ratio / 2, 0.5)
    base_center = (base_w / 2, base_h / 2)

    def place(point):
        dx, dy = point[0] - base_center[0], point[1] - base_center[1]
        if mirrored:
            dx = -dx
        for _ in range(orientation):
            dx, dy = -dy, dx
        return (center[0] + dx * scale, center[1] + dy * scale)

    arcs = []
    x = y = 0.0
    w, h = base_w, base_h
    point = (0.0, 0.0)
    tangent = (0.0, 1.0)
    omega = -1.0
    order = "LBRT"

    for index in range(limit):
        side = min(w, h)
        if side <= 0.002:
            break
        back = rotate(tangent, -90)
        ux, uy = omega * back[0], omega * back[1]
        c = (point[0] - side * ux, point[1] - side * uy)
        start = math.degrees(math.atan2(point[1] - c[1], point[0] - c[0]))
        pc = place(c)
        if mirrored:
            start = 180.0 - start
        start += 90.0 * orientation
        sweep = omega * 90.0 * (-1 if mirrored else 1)
        arcs.append((pc[0], pc[1], side * scale, start, start + sweep))

        end_direction = rotate((ux, uy), omega * 90)
        point = (c[0] + side * end_direction[0], c[1] + side * end_direction[1])
        tangent = rotate(tangent, omega * 90)

        direction = order[index % 4]
        if direction == "L":
            x += side
            w -= side
        elif direction == "B":
            h -= side
        elif direction == "R":
            w -= side
        elif direction == "T":
            y += side
            h -= side

    return arcs


def build(grid_type, ratio, orientation=0, mirrored=False, samples=64):
    if grid_type == "thirds":
        return thirds(ratio)
    if grid_type == "golden":
        return golden(ratio)
    if grid_type == "diagonal":
        return diagonal(ratio)
    if grid_type == "horizon":
        return horizon(ratio)
    if grid_type == "spiral":
        return spiral(ratio, orientation, mirrored, samples=samples)
    raise ValueError(grid_type)


# --- 水準器 -------------------------------------------------------------

TOLERANCE = 0.5
BUBBLE_RANGE = 6.0


def roll(gx, gy):
    magnitude = math.hypot(gx, gy)
    if magnitude <= 0.15:
        return 0.0
    return math.degrees(math.atan2(gx, -gy))


def elevation(gz):
    return math.degrees(math.asin(min(max(gz, -1.0), 1.0)))


def is_level(value):
    return abs(value) <= TOLERANCE


def bubble_offset(value):
    return min(max(value / BUBBLE_RANGE, -1.0), 1.0)


def signed_tenths(value):
    rounded = round_half_away(value * 10) / 10
    if abs(rounded) < 0.05:
        rounded = 0.0
    return f"{rounded:+.1f}"
