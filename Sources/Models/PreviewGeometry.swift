import CoreGraphics
import Foundation

/// ファインダーと枠の割り付け。プレビュー層（.resizeAspect）と Canvas が
/// 同じ矩形になるよう、どちらもこの式から作る。
enum PreviewGeometry {
    /// 与えられた領域に、幅 ÷ 高さ = aspect の矩形を中央に収める。
    static func fitRect(aspect: CGFloat, in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, aspect > 0 else { return .zero }
        let width = min(size.width, size.height * aspect)
        let height = width / aspect
        return CGRect(x: (size.width - width) / 2,
                      y: (size.height - height) / 2,
                      width: width,
                      height: height)
    }

    /// 映像の矩形の中に、キャンバスの枠を中央に収める。
    static func frameRect(canvasRatio: CGFloat, in videoRect: CGRect) -> CGRect {
        guard videoRect.width > 0, videoRect.height > 0 else { return .zero }
        let inner = fitRect(aspect: canvasRatio, in: videoRect.size)
        return inner.offsetBy(dx: videoRect.minX, dy: videoRect.minY)
    }

    /// 枠の矩形を、映像全体に対する 0〜1 の割合に直す。
    static func normalized(_ rect: CGRect, in container: CGRect) -> CGRect {
        guard container.width > 0, container.height > 0 else { return .zero }
        return CGRect(x: (rect.minX - container.minX) / container.width,
                      y: (rect.minY - container.minY) / container.height,
                      width: rect.width / container.width,
                      height: rect.height / container.height)
    }

    /// 0〜1 の割合を、画像の画素の矩形に直す。端は画像の内側に収める。
    static func pixelRect(normalized: CGRect, imageSize: CGSize) -> CGRect {
        let width = max(1, imageSize.width)
        let height = max(1, imageSize.height)
        let clampedX = min(max(normalized.minX, 0), 1)
        let clampedY = min(max(normalized.minY, 0), 1)
        let clampedW = min(max(normalized.width, 0), 1 - clampedX)
        let clampedH = min(max(normalized.height, 0), 1 - clampedY)

        let x = (clampedX * width).rounded(.down)
        let y = (clampedY * height).rounded(.down)
        var w = (clampedW * width).rounded()
        var h = (clampedH * height).rounded()
        w = min(max(w, 1), width - x)
        h = min(max(h, 1), height - y)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
