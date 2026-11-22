import Foundation

/// ファインダーに重ねる構図線の種類。
enum GridType: String, CaseIterable, Identifiable {
    /// 三分割
    case thirds
    /// 黄金比（黄金分割）
    case golden
    /// 対角線
    case diagonal
    /// 水平線（水平を探す）
    case horizon
    /// フィボナッチ黄金螺旋
    case spiral

    var id: String { rawValue }

    /// 操作列に出す短い名。
    var title: String {
        switch self {
        case .thirds: return "三分"
        case .golden: return "黄金"
        case .diagonal: return "対角"
        case .horizon: return "水平"
        case .spiral: return "螺旋"
        }
    }

    /// 読み上げ用の名。
    var longTitle: String {
        switch self {
        case .thirds: return "三分割"
        case .golden: return "黄金比"
        case .diagonal: return "対角線"
        case .horizon: return "水平線"
        case .spiral: return "黄金螺旋"
        }
    }
}
