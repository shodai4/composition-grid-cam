import Foundation

/// 黄金螺旋の向き。90 度ずつ 4 方向、左右の反転と組み合わせる。
struct SpiralSpec: Equatable {
    /// 0…3。90 度ずつ回した向き。
    var orientation: Int = 0
    /// 左右反転。
    var mirrored: Bool = false

    /// 向きを 90 度進める。
    mutating func turn() {
        orientation = (orientation + 1) % 4
    }

    /// 向きを 90 度戻す。
    mutating func turnBack() {
        orientation = (orientation + 3) % 4
    }

    /// 「1 / 4」のような表示用の番号。
    var quarterText: String {
        "\(orientation + 1) / 4"
    }
}
