import SwiftUI

/// 構図線の色。映像の明るさに合わせて選ぶ。
enum LineColor: String, CaseIterable, Identifiable {
    case ivory
    case ink
    case vermilion
    case cyan

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .ivory: return Color(hex: 0xF9F8F5)
        case .ink: return Color(hex: 0x121213)
        case .vermilion: return Color(hex: 0xD2543F)
        case .cyan: return Color(hex: 0x63C7D6)
        }
    }

    var title: String {
        switch self {
        case .ivory: return "白"
        case .ink: return "黒"
        case .vermilion: return "赤"
        case .cyan: return "シアン"
        }
    }
}

/// 線の太さ（pt）。
enum LineWeight: Double, CaseIterable, Identifiable {
    case hair = 0.5
    case fine = 1.0
    case bold = 2.0

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .hair: return "0.5"
        case .fine: return "1.0"
        case .bold: return "2.0"
        }
    }
}

/// 線の濃さ。
enum LineOpacity: Double, CaseIterable, Identifiable {
    case light = 0.35
    case medium = 0.60
    case strong = 0.90

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .light: return "35"
        case .medium: return "60"
        case .strong: return "90"
        }
    }
}

/// 線の見た目をまとめたもの。画面と保存画像の両方で同じ値を使う。
struct GridStyle: Equatable {
    var color: LineColor = .ivory
    var weight: LineWeight = .fine
    var opacity: LineOpacity = .strong

    /// 実際に描く線の太さ（pt）。
    var lineWidth: CGFloat { CGFloat(weight.rawValue) }

    /// 実際に描く不透明度。
    var alpha: Double { opacity.rawValue }
}
