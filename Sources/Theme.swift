import SwiftUI

// MARK: - 色と書体

/// 墨とアイボリーだけで組む。数値は計器のように等幅で置く。
enum Theme {
    /// 墨色 #1A1A1B
    static let ink = Color(hex: 0x1A1A1B)
    /// アイボリー #F9F8F5
    static let ivory = Color(hex: 0xF9F8F5)
    /// 錆青 #4A6A7A（合図にだけ使う）
    static let accent = Color(hex: 0x4A6A7A)
    /// 区切りの細線
    static let hairline = Color(hex: 0xF9F8F5).opacity(0.14)
    /// 操作の下地
    static let panel = Color(hex: 0x1A1A1B).opacity(0.90)

    /// 説明の文字。
    static func label(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// 数値・記号の文字。
    static func mono(_ size: CGFloat = 11, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - 細い線

/// 高さ 1pt の罫線。
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
    }
}
