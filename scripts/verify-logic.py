#!/usr/bin/env python3
"""構図カメラの計算の自己点検。

Swift 側（PreviewGeometry / GridGeometry / LevelMath）と同じ式を geometry.py に写し、
枠の割り付け・構図線の位置・黄金螺旋の巻き方・水準器の読み・保存の切り取りが
意図どおりかを確かめる。CI の test ジョブと手元の両方で実行する。
"""

import math

import geometry as g

CHECKS = []


def check(name, condition, detail=""):
    CHECKS.append((name, bool(condition), detail))


def close(a, b, tolerance=1e-9):
    return abs(a - b) <= tolerance


def rect_close(a, b, tolerance=1e-6):
    return all(abs(x - y) <= tolerance for x, y in zip(a, b))


# --- 号数 -----------------------------------------------------------------

def test_presets():
    check("号数は 17 種", len(g.PRESETS) == 17, str(len(g.PRESETS)))
    f6 = next(p for p in g.PRESETS if p.name == "F6")
    p6 = next(p for p in g.PRESETS if p.name == "P6")
    m6 = next(p for p in g.PRESETS if p.name == "M6")
    check("F6 は 410 ÷ 318", close(f6.ratio, 410 / 318), f"{f6.ratio:.5f}")
    check("P6 は 410 ÷ 273", close(p6.ratio, 410 / 273), f"{p6.ratio:.5f}")
    check("M6 は 410 ÷ 242", close(m6.ratio, 410 / 242), f"{m6.ratio:.5f}")
    check("P6 は F6 より横長", p6.ratio > f6.ratio)
    check("M6 は P6 より横長", m6.ratio > p6.ratio)
    check("正方形以外はすべて横長",
          all(p.ratio > 1.0 for p in g.PRESETS if p.short_side > 0 and p.short_side != p.long_side),
          f"最小 {min(p.ratio for p in g.PRESETS if p.short_side > 0 and p.short_side != p.long_side):.3f}")
    check("1:1 の比は 1", close(g.PRESETS[0].ratio, 1.0))
    check("F6 の寸法表記", f6.dimension == "410 × 318", f6.dimension)
    check("1:1 の寸法表記", g.PRESETS[0].dimension == "1 : 1", g.PRESETS[0].dimension)
    check("最初の号数は F6", g.INITIAL_PRESET.name == "F6", g.INITIAL_PRESET.name)
    check("号数の名は重ならない", len({p.name for p in g.PRESETS}) == len(g.PRESETS))


# --- 映像と枠の割り付け ---------------------------------------------------

def test_layout():
    # 9:16 の映像（2160 × 3840 を縦に回したもの）
    aspect = 2160 / 3840
    video = g.fit_rect(aspect, (390, 570))
    check("9:16 の映像は高さで収まる", close(video[3], 570), f"{video}")
    check("9:16 の映像の幅", close(video[2], 570 * 0.5625), f"{video[2]:.3f}")
    check("映像は左右中央", close(video[0], 390 - (video[0] + video[2])), f"{video[0]:.3f}")
    check("映像は左上から始まらない", video[0] > 0)

    tall = g.fit_rect(aspect, (300, 300))
    check("正方形の領域では幅で収まる", close(tall[2], 300 * 0.5625) and close(tall[3], 300),
          f"{tall}")

    zero = g.fit_rect(aspect, (0, 0))
    check("領域が 0 なら割り付けなし", zero == (0.0, 0.0, 0.0, 0.0), str(zero))

    # 枠（F6）は映像の中に中央で入る
    frame = g.frame_rect(410 / 318, video)
    check("枠は映像の中", frame[0] >= video[0] - 1e-9 and frame[0] + frame[2] <= video[0] + video[2] + 1e-9
          and frame[1] >= video[1] - 1e-9 and frame[1] + frame[3] <= video[1] + video[3] + 1e-9,
          str(frame))
    check("枠の縦横比は号数どおり", close(frame[2] / frame[3], 410 / 318, 1e-9),
          f"{frame[2] / frame[3]:.6f}")
    check("枠は左右中央", close(frame[0], video[0] + (video[2] - frame[2]) / 2), f"{frame[0]:.3f}")
    check("枠は上下中央", close(frame[1], video[1] + (video[3] - frame[3]) / 2), f"{frame[1]:.3f}")

    # 1:1 の枠
    square = g.frame_rect(1.0, video)
    check("1:1 の枠は正方形", close(square[2], square[3], 1e-9), f"{square}")


# --- 保存の切り取り -------------------------------------------------------

def test_export():
    aspect = 2160 / 3840
    norm = g.normalized_frame(410 / 318, aspect)
    check("F6 の枠は横いっぱい", close(norm[2], 1.0, 1e-9), f"{norm}")
    check("F6 の枠の高さ（割合）", close(norm[3], aspect / (410 / 318), 1e-12), f"{norm[3]:.6f}")
    check("F6 の枠は上下中央", close(norm[1], (1 - norm[3]) / 2), f"{norm[1]:.6f}")

    crop = g.pixel_rect(norm, (2160, 3840))
    check("切り取りは整数の画素", all(float(v).is_integer() for v in crop), str(crop))
    check("切り取りは画像の内側", crop[0] >= 0 and crop[1] >= 0
          and crop[0] + crop[2] <= 2160 and crop[1] + crop[3] <= 3840, str(crop))
    check("切り取りの縦横比は号数どおり", close(crop[2] / crop[3], 410 / 318, 2e-3),
          f"{crop[2] / crop[3]:.4f}")
    check("切り取りは横長（縦長になっていない）", crop[2] > crop[3], str(crop))
    check("切り取りの幅は全幅", close(crop[2], 2160), str(crop))

    square_crop = g.pixel_rect(g.normalized_frame(1.0, aspect), (2160, 3840))
    check("1:1 の切り取りは正方形", abs(square_crop[2] - square_crop[3]) <= 1,
          str(square_crop))

    # 端をはみ出す割合でも内側に収める
    edge = g.pixel_rect((0.9, 0.9, 0.5, 0.5), (100, 100))
    check("はみ出す割合は内側に丸める", edge == (90.0, 90.0, 10.0, 10.0), str(edge))

    # 線の太さの換算（保存画像の高さ 320px を 1pt とみなす）
    def line_px(width, height):
        return max(1.0, width * height / 320)

    check("0.5pt は 1676px で約 2.6px", close(line_px(0.5, 1676), 2.61875, 1e-6),
          f"{line_px(0.5, 1676):.3f}")
    check("細い画像でも 1px を下回らない", line_px(0.5, 100) == 1.0, str(line_px(0.5, 100)))
    check("2.0pt は太い", line_px(2.0, 1676) > line_px(0.5, 1676) * 3.5)


# --- 構図線 ---------------------------------------------------------------

def test_lines():
    ratio = 410 / 318

    thirds = g.thirds(ratio)
    check("三分割は 4 本", len(thirds) == 4, str(len(thirds)))
    xs = sorted({p[0] for s in thirds if s[0][0] == s[1][0] for p in s})
    check("三分割の縦線", close(xs[0], ratio / 3) and close(xs[1], ratio * 2 / 3), str(xs))
    ys = sorted({p[1] for s in thirds if s[0][1] == s[1][1] for p in s})
    check("三分割の横線", close(ys[0], 1 / 3) and close(ys[1], 2 / 3), str(ys))

    gold = g.golden(ratio)
    check("黄金比は 4 本", len(gold) == 4, str(len(gold)))
    xs = sorted({p[0] for s in gold if s[0][0] == s[1][0] for p in s})
    check("黄金比の縦線は 0.382 / 0.618",
          close(xs[0], ratio * 0.3819660112501051, 1e-9) and
          close(xs[1], ratio * 0.6180339887498949, 1e-9), str(xs))

    diag = g.diagonal(ratio)
    check("対角線は 2 本", len(diag) == 2)
    check("対角線は角から角へ",
          diag[0][0] == (0.0, 0.0) and close(diag[0][1][0], ratio) and close(diag[0][1][1], 1.0))
    check("もう一本は逆の対角", diag[1][0][0] == ratio and diag[1][0][1] == 0.0
          and diag[1][1][0] == 0.0 and close(diag[1][1][1], 1.0))
    check("対角線は中央で交わる",
          close(diag[0][0][0] + (diag[0][1][0] - diag[0][0][0]) / 2, diag[1][0][0] + (diag[1][1][0] - diag[1][0][0]) / 2))

    hor = g.horizon(ratio)
    check("水平線は 3 本", len(hor) == 3)
    check("水平線の位置", [round(s[0][1], 6) for s in hor] == [round(1 / 3, 6), 0.5, round(2 / 3, 6)],
          str([s[0][1] for s in hor]))
    check("水平線はすべて横いっぱい", all(close(s[0][0], 0.0) and close(s[1][0], ratio) for s in hor))

    for name, strokes in (("三分割", thirds), ("黄金比", gold), ("対角線", diag), ("水平線", hor)):
        inside = all(-1e-9 <= p[0] <= ratio + 1e-9 and -1e-9 <= p[1] <= 1 + 1e-9
                     for s in strokes for p in s)
        check(f"{name}は枠の内側", inside)


# --- 黄金螺旋 -------------------------------------------------------------

def arc_length(points):
    return sum(math.dist(points[i], points[i + 1]) for i in range(len(points) - 1))


def test_spiral():
    ratios = [p.ratio for p in g.PRESETS]
    for ratio in ratios:
        for orientation in range(4):
            for mirrored in (False, True):
                strokes = g.spiral(ratio, orientation, mirrored)
                label = f"螺旋 ratio={ratio:.2f} 向き={orientation} 反転={mirrored}"
                check(f"{label}: 弧は 8 本以上", len(strokes) >= 8, str(len(strokes)))
                inside = all(-1e-9 <= p[0] <= ratio + 1e-9 and -1e-9 <= p[1] <= 1 + 1e-9
                             for s in strokes for p in s)
                check(f"{label}: 枠の内側", inside)
                continuity = max(math.dist(strokes[i][-1], strokes[i + 1][0])
                                 for i in range(len(strokes) - 1))
                check(f"{label}: 弧はつながる", continuity < 1e-12, f"{continuity:.2e}")
                radii = [arc_length(s) / (math.pi / 2) for s in strokes]
                ratio_steps = [radii[i + 1] / radii[i] for i in range(len(radii) - 1)]
                worst = max(abs(r - 1 / g.PHI) for r in ratio_steps)
                check(f"{label}: 半径は 1/φ ずつ縮む", worst < 1e-6, f"最大ずれ {worst:.2e}")
                check(f"{label}: 内側へ巻く", radii[-1] < radii[0] / 50, f"{radii[-1] / radii[0]:.4f}")

    f6 = 410 / 318
    base = g.spiral(f6, 0, False)
    xs = [p[0] for s in base for p in s]
    ys = [p[1] for s in base for p in s]
    span_x = max(xs) - min(xs)
    span_y = max(ys) - min(ys)
    check("黄金螺旋は枠のどちらかを満たす", close(max(span_x / f6, span_y / 1.0), 1.0, 1e-6),
          f"{span_x:.4f} × {span_y:.4f}")
    check("黄金螺旋の短辺は φ で割った長さ", close(min(span_x / f6, span_y) * g.PHI, max(span_x, span_y), 1e-6),
          f"{span_x:.4f} × {span_y:.4f}")

    turned = g.spiral(f6, 1, False)
    turned_xs = [p[0] for s in turned for p in s]
    check("向きを変えると横の広がりが変わる",
          abs((max(turned_xs) - min(turned_xs)) - (max(xs) - min(xs))) > 0.01,
          f"{(max(turned_xs) - min(turned_xs)):.4f} / {(max(xs) - min(xs)):.4f}")

    mirrored = g.spiral(f6, 0, True)
    same = all(close(a[0], b[0], 1e-9) and close(a[1], b[1], 1e-9)
               for s1, s2 in zip(base, mirrored) for a, b in zip(s1, s2))
    check("反転すると形が変わる", not same)
    check("反転しても枠の内側",
          all(-1e-9 <= p[0] <= f6 + 1e-9 and -1e-9 <= p[1] <= 1 + 1e-9
              for s in mirrored for p in s))

    # 弧のまま返す版と、折れ線の版が同じ形になる
    for orientation in range(4):
        for mirrored in (False, True):
            specs = g.spiral_arc_specs(f6, orientation, mirrored)
            strokes = g.spiral(f6, orientation, mirrored)
            check(f"弧の仕様と折れ線の本数が同じ（向き={orientation} 反転={mirrored}）",
                  len(specs) == len(strokes), f"{len(specs)} / {len(strokes)}")
            worst = 0.0
            for (cx, cy, r, a0, a1), points in zip(specs, strokes):
                for k, point in enumerate(points):
                    start = a0
                    angle = math.radians(start + (a1 - start) * k / (len(points) - 1))
                    sample = (cx + r * math.cos(angle), cy + r * math.sin(angle))
                    worst = max(worst, math.dist(sample, point))
            check(f"弧の仕様は折れ線と一致（向き={orientation} 反転={mirrored}）",
                  worst < 1e-9, f"{worst:.2e}")

    square = g.spiral(1.0, 0, False)
    check("1:1 でも螺旋が収まる",
          all(0 <= p[0] <= 1 + 1e-9 and 0 <= p[1] <= 1 + 1e-9 for s in square for p in s))


# --- 水準器 ---------------------------------------------------------------

def test_level():
    check("まっすぐ構えると 0 度", close(g.roll(0.0, -1.0), 0.0), f"{g.roll(0.0, -1.0):.3f}")
    tilt = math.radians(10)
    check("右へ 10 度傾けると +10 度",
          close(g.roll(math.sin(tilt), -math.cos(tilt)), 10.0, 1e-9),
          f"{g.roll(math.sin(tilt), -math.cos(tilt)):.3f}")
    check("左へ 5 度傾けると −5 度",
          close(g.roll(-math.sin(math.radians(5)), -math.cos(math.radians(5))), -5.0, 1e-9))
    check("伏せた状態では 0 度（割り算を避ける）", close(g.roll(0.0, 0.0), 0.0))

    check("水平に構えると仰角 0", close(g.elevation(0.0), 0.0), f"{g.elevation(0.0):.3f}")
    check("真下を向くと −90 度", close(g.elevation(-1.0), -90.0), f"{g.elevation(-1.0):.3f}")
    check("真上を向くと +90 度", close(g.elevation(1.0), 90.0), f"{g.elevation(1.0):.3f}")
    check("30 度上げると +30 度", close(g.elevation(0.5), 30.0, 1e-9), f"{g.elevation(0.5):.3f}")
    check("範囲外は丸める", close(g.elevation(1.7), 90.0))

    check("0.5 度は水平とみなす", g.is_level(0.5))
    check("0.6 度は水平とみなさない", not g.is_level(0.6))
    check("−0.4 度は水平とみなす", g.is_level(-0.4))
    check("泡は 6 度で右端", close(g.bubble_offset(6.0), 1.0))
    check("泡は −3 度で左へ半分", close(g.bubble_offset(-3.0), -0.5))
    check("泡は 0 度で中央", close(g.bubble_offset(0.0), 0.0))
    check("泡は行き過ぎない", close(g.bubble_offset(30.0), 1.0) and close(g.bubble_offset(-30.0), -1.0))

    check("+0.04 は +0.0", g.signed_tenths(0.04) == "+0.0", g.signed_tenths(0.04))
    check("−0.04 は +0.0（−0.0 を出さない）", g.signed_tenths(-0.04) == "+0.0", g.signed_tenths(-0.04))
    check("+1.24 は +1.2", g.signed_tenths(1.24) == "+1.2", g.signed_tenths(1.24))
    check("−3.46 は −3.5", g.signed_tenths(-3.46) == "-3.5", g.signed_tenths(-3.46))
    check("+12 は +12.0", g.signed_tenths(12.0) == "+12.0", g.signed_tenths(12.0))
    check("0.05 は +0.1", g.signed_tenths(0.05) == "+0.1", g.signed_tenths(0.05))


# --- 出力 -----------------------------------------------------------------

def main():
    test_presets()
    test_layout()
    test_export()
    test_lines()
    test_spiral()
    test_level()

    width = max(len(name) for name, _, _ in CHECKS)
    failures = 0
    for name, ok, detail in CHECKS:
        print(f"{'ok  ' if ok else 'FAIL'}  {name.ljust(width)}  {detail}")
        if not ok:
            failures += 1
    print(f"\n{len(CHECKS) - failures} / {len(CHECKS)} 件 ok")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
