import CoreGraphics
import UIKit

/// 保存する 1 枚を組み立てる。枠の内側だけを切り取り、必要なら構図線を焼き込む。
enum ExportRenderer {
    /// 画面の枠と同じ割合（0〜1）で切り取る。
    /// - Parameters:
    ///   - image: カメラの 1 枚（縦持ちに回したもの）
    ///   - frameRect: 映像全体に対する枠の割合
    ///   - grid: 枠の座標系で作った構図線
    ///   - style: 線の色・太さ・濃さ
    ///   - includeGrid: 構図線を焼き込むか
    static func render(image: CGImage,
                       frameRect: CGRect,
                       grid: GridShape?,
                       style: GridStyle,
                       includeGrid: Bool) -> CGImage? {
        let imageSize = CGSize(width: image.width, height: image.height)
        let crop = PreviewGeometry.pixelRect(normalized: frameRect, imageSize: imageSize)
        guard crop.width >= 1, crop.height >= 1,
              let cropped = image.cropping(to: crop) else { return nil }
        guard includeGrid, let grid, !grid.strokes.isEmpty else { return cropped }

        let width = cropped.width
        let height = cropped.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }

        let canvas = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        context.draw(cropped, in: canvas)

        // ここから下は y 下向きの座標で描く（画面側の式と同じ向き）。
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        // 画面の 1pt がおよそ何画素になるかを見て、線の太さを合わせる。
        let pixelScale = CGFloat(height) / 320
        let lineWidth = max(1, style.lineWidth * pixelScale)

        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setShouldAntialias(true)
        let color = UIColor(style.color.color)
        for stroke in grid.strokes {
            guard stroke.points.count >= 2 else { continue }
            context.setStrokeColor(color.withAlphaComponent(style.alpha).cgColor)
            context.setLineWidth(lineWidth * stroke.emphasis)
            context.beginPath()
            let first = grid.converted(stroke.points[0], in: canvas)
            context.move(to: first)
            for point in stroke.points.dropFirst() {
                context.addLine(to: grid.converted(point, in: canvas))
            }
            context.strokePath()
        }
        context.restoreGState()

        return context.makeImage()
    }
}
