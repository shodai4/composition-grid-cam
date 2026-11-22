import CoreGraphics
import Foundation

/// キャンバスの号数。幅 ÷ 高さの比をファインダーの枠に使う。
struct CanvasPreset: Identifiable, Hashable {
    let name: String
    /// 短辺（mm）。1:1 では 0。
    let shortSide: Int
    /// 長辺（mm）。1:1 では 0。
    let longSide: Int

    var id: String { name }

    /// 幅 ÷ 高さ（横長）。
    var ratio: CGFloat {
        guard shortSide > 0, longSide > 0 else { return 1 }
        return CGFloat(longSide) / CGFloat(shortSide)
    }

    /// 枠の下に添える寸法。号数の呼び寸法（mm）。
    var dimension: String {
        guard shortSide > 0, longSide > 0 else { return "1 : 1" }
        return "\(longSide) × \(shortSide)"
    }

    static let square = CanvasPreset(name: "1:1", shortSide: 0, longSide: 0)

    /// 主要な号数（JIS 呼び寸法）。
    static let all: [CanvasPreset] = [
        square,
        CanvasPreset(name: "F3", shortSide: 220, longSide: 273),
        CanvasPreset(name: "F5", shortSide: 250, longSide: 350),
        CanvasPreset(name: "F6", shortSide: 318, longSide: 410),
        CanvasPreset(name: "F8", shortSide: 380, longSide: 455),
        CanvasPreset(name: "F10", shortSide: 455, longSide: 530),
        CanvasPreset(name: "F12", shortSide: 500, longSide: 606),
        CanvasPreset(name: "P3", shortSide: 190, longSide: 273),
        CanvasPreset(name: "P5", shortSide: 240, longSide: 350),
        CanvasPreset(name: "P6", shortSide: 273, longSide: 410),
        CanvasPreset(name: "P8", shortSide: 300, longSide: 455),
        CanvasPreset(name: "P10", shortSide: 350, longSide: 530),
        CanvasPreset(name: "M3", shortSide: 170, longSide: 273),
        CanvasPreset(name: "M5", shortSide: 220, longSide: 350),
        CanvasPreset(name: "M6", shortSide: 242, longSide: 410),
        CanvasPreset(name: "M10", shortSide: 300, longSide: 530),
        CanvasPreset(name: "S6", shortSide: 410, longSide: 410)
    ]

    /// F6（410 × 318）を最初の枠にする。
    static let initial = all.first { $0.name == "F6" } ?? square
}
