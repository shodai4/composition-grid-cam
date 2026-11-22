import SwiftUI

/// ファインダーの上に重ねる構図線。枠の外はわずかに落とす。
struct GridOverlay: View {
    let shape: GridShape
    let frameRect: CGRect
    let style: GridStyle

    /// 枠の外側を落とす濃さ。
    private let veil: Double = 0.22

    var body: some View {
        Canvas { context, size in
            guard frameRect.width > 1, frameRect.height > 1 else { return }

            // 枠の外を薄く沈める。
            var mask = Path(CGRect(origin: .zero, size: size))
            mask.addRect(frameRect)
            context.fill(mask, with: .color(Theme.ink.opacity(veil)),
                         style: FillStyle(eoFill: true))

            let color = style.color.color.opacity(style.alpha)

            // 構図線。
            for stroke in shape.strokes {
                guard stroke.points.count >= 2 else { continue }
                var path = Path()
                path.move(to: shape.converted(stroke.points[0], in: frameRect))
                for point in stroke.points.dropFirst() {
                    path.addLine(to: shape.converted(point, in: frameRect))
                }
                context.stroke(path,
                               with: .color(color),
                               style: StrokeStyle(lineWidth: style.lineWidth * stroke.emphasis,
                                                  lineCap: .round,
                                                  lineJoin: .round))
            }

            // 枠線。
            var border = Path()
            border.addRect(frameRect)
            context.stroke(border, with: .color(color), lineWidth: style.lineWidth)
        }
        .allowsHitTesting(false)
    }
}
