import CoreGraphics
import Foundation

/// 水準器の計算。CoreMotion の重力ベクトルから、地平線の傾きと仰角を出す。
enum LevelMath {
    /// 水平とみなす幅（度）。この中に入ったら合図を出す。
    static let tolerance: Double = 0.5

    /// 泡の可動域（度）。この傾きで端まで動く。
    static let bubbleRange: Double = 6

    /// 地平線の傾き（度）。右に傾けると正。
    static func roll(gravityX: Double, gravityY: Double) -> Double {
        let magnitude = (gravityX * gravityX + gravityY * gravityY).squareRoot()
        guard magnitude > 0.15 else { return 0 }
        return atan2(gravityX, -gravityY) * 180 / .pi
    }

    /// 仰角（度）。水平に構えたとき 0、上を向くと正。
    static func elevation(gravityZ: Double) -> Double {
        let clamped = min(max(gravityZ, -1), 1)
        return asin(clamped) * 180 / .pi
    }

    /// 水平とみなせるか。
    static func isLevel(roll: Double) -> Bool {
        abs(roll) <= tolerance
    }

    /// 泡の位置。−1〜1（左端〜右端）。
    static func bubbleOffset(roll: Double) -> Double {
        min(max(roll / bubbleRange, -1), 1)
    }

    /// 符号つき、小数 1 桁。−0.0 は出さない。
    static func signedTenths(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        let normalized = abs(rounded) < 0.05 ? 0 : rounded
        return String(format: "%+.1f", normalized)
    }

    /// 小数 1 桁（符号なし）。
    static func tenths(_ value: Double) -> String {
        String(format: "%.1f", abs(value) < 0.05 ? 0 : value)
    }
}
