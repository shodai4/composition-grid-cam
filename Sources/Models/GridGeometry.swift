import CoreGraphics
import Foundation

// MARK: - 形

/// 一本の線。点はすべて「枠を (0,0)〜(ratio,1) とした座標」で持つ。
struct GridStroke: Equatable {
    var points: [CGPoint]
    /// 線幅の倍率。水平線の主線だけ少し強くする。
    var emphasis: CGFloat = 1

    init(points: [CGPoint], emphasis: CGFloat = 1) {
        self.points = points
        self.emphasis = emphasis
    }

    init(from start: CGPoint, to end: CGPoint, emphasis: CGFloat = 1) {
        self.init(points: [start, end], emphasis: emphasis)
    }
}

/// ファインダーに重ねる形の一式。画面と保存画像で同じものを使う。
struct GridShape: Equatable {
    var strokes: [GridStroke]
    /// 座標系の大きさ（幅 = 号数の比、高さ = 1）。
    var bounds: CGSize

    /// 枠の座標から画面・画素の座標へ。
    func converted(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        let sx = rect.width / bounds.width
        let sy = rect.height / bounds.height
        return CGPoint(x: rect.minX + point.x * sx, y: rect.minY + point.y * sy)
    }
}

// MARK: - 組み立て

enum GridBuilder {
    /// 四分円を折れ線にする細かさ。1 弧あたりの分割数。
    static let arcSamples = 64

    static func make(type: GridType, preset: CanvasPreset, spiral spec: SpiralSpec) -> GridShape {
        let ratio = max(0.05, preset.ratio)
        let bounds = CGSize(width: ratio, height: 1)
        switch type {
        case .thirds:
            return GridShape(strokes: thirds(ratio: ratio), bounds: bounds)
        case .golden:
            return GridShape(strokes: golden(ratio: ratio), bounds: bounds)
        case .diagonal:
            return GridShape(strokes: diagonal(ratio: ratio), bounds: bounds)
        case .horizon:
            return GridShape(strokes: horizon(ratio: ratio), bounds: bounds)
        case .spiral:
            return GridShape(strokes: spiral(ratio: ratio, spec: spec), bounds: bounds)
        }
    }

    // MARK: 三分割

    static func thirds(ratio: CGFloat) -> [GridStroke] {
        var strokes: [GridStroke] = []
        for i in 1...2 {
            let x = ratio * CGFloat(i) / 3
            strokes.append(GridStroke(from: CGPoint(x: x, y: 0), to: CGPoint(x: x, y: 1)))
            let y = CGFloat(i) / 3
            strokes.append(GridStroke(from: CGPoint(x: 0, y: y), to: CGPoint(x: ratio, y: y)))
        }
        return strokes
    }

    // MARK: 黄金比

    /// 黄金分割の位置（1 ÷ φ = 0.618、その裏は 0.382）。
    static let goldenFraction: CGFloat = 0.6180339887498949

    static func golden(ratio: CGFloat) -> [GridStroke] {
        let inner = goldenFraction
        let outer = 1 - goldenFraction
        var strokes: [GridStroke] = []
        for f in [outer, inner] {
            let x = ratio * f
            strokes.append(GridStroke(from: CGPoint(x: x, y: 0), to: CGPoint(x: x, y: 1)))
            strokes.append(GridStroke(from: CGPoint(x: 0, y: f), to: CGPoint(x: ratio, y: f)))
        }
        return strokes
    }

    // MARK: 対角線

    static func diagonal(ratio: CGFloat) -> [GridStroke] {
        [
            GridStroke(from: CGPoint(x: 0, y: 0), to: CGPoint(x: ratio, y: 1)),
            GridStroke(from: CGPoint(x: ratio, y: 0), to: CGPoint(x: 0, y: 1))
        ]
    }

    // MARK: 水平線

    static func horizon(ratio: CGFloat) -> [GridStroke] {
        [
            GridStroke(from: CGPoint(x: 0, y: 1.0 / 3), to: CGPoint(x: ratio, y: 1.0 / 3)),
            GridStroke(from: CGPoint(x: 0, y: 0.5), to: CGPoint(x: ratio, y: 0.5), emphasis: 1.6),
            GridStroke(from: CGPoint(x: 0, y: 2.0 / 3), to: CGPoint(x: ratio, y: 2.0 / 3))
        ]
    }

    // MARK: 黄金螺旋

    /// 黄金矩形（φ × 1）の中に四分円を内側へ巻く。黄金矩形は枠の中に収め、
    /// 向き（4 方向）と反転（左右）で別々に組み立てる。
    static func spiral(ratio: CGFloat, spec: SpiralSpec) -> [GridStroke] {
        let phi: CGFloat = 1.6180339887498949
        let orientation = ((spec.orientation % 4) + 4) % 4
        let baseWidth = phi
        let baseHeight: CGFloat = 1

        // 黄金矩形の置き方。奇数回転では縦長の黄金矩形になる。
        let scale: CGFloat
        if orientation % 2 == 0 {
            scale = min(1, ratio / phi)
        } else {
            scale = min(ratio, 1 / phi)
        }
        let center = CGPoint(x: ratio / 2, y: 0.5)
        let baseCenter = CGPoint(x: baseWidth / 2, y: baseHeight / 2)

        func place(_ p: CGPoint) -> CGPoint {
            var dx = p.x - baseCenter.x
            var dy = p.y - baseCenter.y
            if spec.mirrored { dx = -dx }
            for _ in 0..<orientation {
                let nx = -dy
                let ny = dx
                dx = nx
                dy = ny
            }
            return CGPoint(x: center.x + dx * scale, y: center.y + dy * scale)
        }

        var strokes: [GridStroke] = []
        var w = baseWidth
        var h = baseHeight
        var point = CGPoint(x: 0, y: 0)
        var tangent = CGVector(dx: 0, dy: 1)
        let omega: CGFloat = -1
        let order: [Character] = ["L", "B", "R", "T"]

        for index in 0..<24 {
            let side = min(w, h)
            guard side > 0.002 else { break }

            // 中心は「始点から半径ぶん、接線に直交する向き」にある。
            let back = rotate(tangent, degrees: -90)
            let ux = omega * back.dx
            let uy = omega * back.dy
            let centerOfArc = CGPoint(x: point.x - side * ux, y: point.y - side * uy)
            let startAngle = CGFloat(atan2(Double(point.y - centerOfArc.y),
                                           Double(point.x - centerOfArc.x)))

            var samples: [CGPoint] = []
            samples.reserveCapacity(arcSamples + 1)
            for step in 0...arcSamples {
                let t = CGFloat(step) / CGFloat(arcSamples)
                let angle = startAngle + omega * (.pi / 2) * t
                let raw = CGPoint(x: centerOfArc.x + side * cos(angle),
                                  y: centerOfArc.y + side * sin(angle))
                samples.append(place(raw))
            }
            strokes.append(GridStroke(points: samples))

            // 次の弧の始点と接線。
            let endDirection = rotate(CGVector(dx: ux, dy: uy), degrees: omega * 90)
            point = CGPoint(x: centerOfArc.x + side * endDirection.dx,
                            y: centerOfArc.y + side * endDirection.dy)
            tangent = rotate(tangent, degrees: omega * 90)

            // 次の矩形（正方形を切り取った残り）。
            switch order[index % 4] {
            case "L", "R":
                w -= side
            case "B", "T":
                h -= side
            default:
                break
            }
        }
        return strokes
    }

    /// 画面座標（y 下向き）での回転。
    static func rotate(_ vector: CGVector, degrees: CGFloat) -> CGVector {
        let radians = degrees * .pi / 180
        let c = cos(radians)
        let s = sin(radians)
        return CGVector(dx: vector.dx * c - vector.dy * s,
                        dy: vector.dx * s + vector.dy * c)
    }
}
