import CoreGraphics
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var pro: ProStore
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var camera = CameraController()

    @State private var grid: GridType = .thirds
    @State private var spiral = SpiralSpec()
    @State private var preset: CanvasPreset = .initial
    @State private var style = GridStyle()
    @State private var frozen: CGImage?
    @State private var includeGridOnSave = true
    @State private var isSaving = false
    @State private var toast: String?
    @State private var toastToken = 0

    // MARK: - 本体

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            VStack(spacing: 0) {
                previewArea
                ControlPanel(grid: $grid,
                             spiral: $spiral,
                             preset: $preset,
                             style: $style,
                             includeGridOnSave: $includeGridOnSave,
                             isFrozen: frozen != nil,
                             isSaving: isSaving,
                             onFreeze: freezeOrResume,
                             onSave: save)
                adArea
            }
            .ignoresSafeArea(edges: .top)
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .onAppear { camera.start() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                camera.refresh()
            case .inactive, .background:
                camera.stop()
            @unknown default:
                break
            }
        }
    }

    // MARK: - ファインダー

    private var previewArea: some View {
        GeometryReader { geo in
            let video = videoRect(in: geo.size)
            let frame = PreviewGeometry.frameRect(canvasRatio: preset.ratio, in: video)
            ZStack {
                Color.black
                if let frozen {
                    Image(decorative: frozen, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    PreviewLayerView(session: camera.session)
                }
                GridOverlay(shape: shape, frameRect: frame, style: style)
                topScrim
                readouts
                if camera.status == .denied || camera.status == .unavailable {
                    permissionNotice
                }
                if let toast {
                    toastView(toast)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 映像の縦横比（幅 ÷ 高さ）。プレビュー層が受け取るのと同じ寸法から出す。
    private var videoAspect: CGFloat {
        if camera.videoSize.width > 1, camera.videoSize.height > 1 {
            return camera.videoSize.width / camera.videoSize.height
        }
        return 9.0 / 16.0
    }

    /// 映像の矩形。プレビュー層（.resizeAspect）と同じ式で割り付ける。
    private func videoRect(in size: CGSize) -> CGRect {
        guard size.width > 1, size.height > 1 else { return .zero }
        return PreviewGeometry.fitRect(aspect: videoAspect, in: size)
    }

    /// 枠の位置を、映像全体に対する 0〜1 の割合で持つ（保存に使う）。
    private var normalizedFrame: CGRect {
        let video = CGRect(x: 0, y: 0, width: videoAspect, height: 1)
        let frame = PreviewGeometry.frameRect(canvasRatio: preset.ratio, in: video)
        return PreviewGeometry.normalized(frame, in: video)
    }

    private var shape: GridShape {
        GridBuilder.make(type: grid, preset: preset, spiral: spiral)
    }

    private var topScrim: some View {
        LinearGradient(colors: [Theme.ink.opacity(0.55), Theme.ink.opacity(0.0)],
                       startPoint: .top,
                       endPoint: .bottom)
            .frame(height: 100)
            .frame(maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
    }

    private var readouts: some View {
        VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(Theme.mono(13))
                        .foregroundStyle(Theme.ivory)
                    Text(preset.dimension)
                        .font(Theme.mono(10))
                        .foregroundStyle(Theme.ivory.opacity(0.55))
                }
                Spacer(minLength: 8)
                LevelReadout()
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)

            if frozen != nil {
                Text("停止")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.ivory.opacity(0.85))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.ink.opacity(0.55)))
            }
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
    }

    private func toastView(_ text: String) -> some View {
        VStack {
            Spacer(minLength: 0)
            Text(text)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.ivory)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.ink.opacity(0.78)))
                .padding(.bottom, 18)
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    private var permissionNotice: some View {
        VStack(spacing: 10) {
            Text(camera.status == .denied ? "カメラへのアクセスが許可されていません" : "カメラを起動できませんでした")
                .font(Theme.label(13))
                .foregroundStyle(Theme.ivory.opacity(0.90))
                .multilineTextAlignment(.center)
            if camera.status == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("設定を開く")
                        .font(Theme.label(11))
                        .foregroundStyle(Theme.ivory.opacity(0.70))
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.ink.opacity(0.82)))
    }

    // MARK: - 広告

    @ViewBuilder
    private var adArea: some View {
        if !pro.isPro {
            VStack(spacing: 0) {
                Hairline()
                if pro.canPurchase {
                    Button {
                        Task { await pro.purchase() }
                    } label: {
                        Text("広告を消す")
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.ivory.opacity(0.45))
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    Spacer(minLength: 0)
                    BannerAdView()
                        .frame(width: 320, height: 50)
                    Spacer(minLength: 0)
                }
            }
            .background(Theme.ink)
        }
    }

    // MARK: - 停止と保存

    private func freezeOrResume() {
        if frozen != nil {
            frozen = nil
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }
        guard let image = camera.latestImage() else {
            showToast("映像がまだ届いていません")
            return
        }
        frozen = image
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func save() {
        guard !isSaving else { return }
        guard let source = frozen ?? camera.latestImage() else {
            showToast("映像がまだ届いていません")
            return
        }
        isSaving = true

        // 枠は映像全体に対する割合で持つ（画面の大きさに依らない）。
        let unitFrame = normalizedFrame
        let gridShape = shape
        let styleSnapshot = style
        let withGrid = includeGridOnSave

        Task {
            let rendered = ExportRenderer.render(image: source,
                                                 frameRect: unitFrame,
                                                 grid: gridShape,
                                                 style: styleSnapshot,
                                                 includeGrid: withGrid)
            var outcome: PhotoSaver.Outcome = .failed
            if let rendered {
                outcome = await PhotoSaver.save(UIImage(cgImage: rendered))
            }
            await MainActor.run {
                isSaving = false
                switch outcome {
                case .saved:
                    showToast("保存しました")
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case .denied:
                    showToast("写真への追加が許可されていません")
                case .failed:
                    showToast("保存できませんでした")
                }
            }
        }
    }

    private func showToast(_ text: String) {
        toastToken &+= 1
        let token = toastToken
        withAnimation(.easeOut(duration: 0.15)) { toast = text }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            await MainActor.run {
                guard toastToken == token else { return }
                withAnimation(.easeIn(duration: 0.20)) { toast = nil }
            }
        }
    }
}

// MARK: - 水準の読み

/// 傾きと仰角を 0.1 度単位で出す。30 回/秒で更新されるので、この中だけで閉じる。
private struct LevelReadout: View {
    @StateObject private var motion = MotionController()

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                Text("水平")
                    .font(Theme.label(9))
                    .foregroundStyle(Theme.ivory.opacity(0.45))
                Text(LevelMath.signedTenths(motion.roll) + "°")
                    .font(Theme.mono(12, weight: motion.isLevel ? .medium : .regular))
                    .foregroundStyle(motion.isLevel ? Theme.accent : Theme.ivory)
            }
            HStack(spacing: 6) {
                Text("仰角")
                    .font(Theme.label(9))
                    .foregroundStyle(Theme.ivory.opacity(0.45))
                Text(LevelMath.signedTenths(motion.elevation) + "°")
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.ivory.opacity(0.70))
            }
            bubble
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }

    private var bubble: some View {
        ZStack {
            Capsule()
                .stroke(Theme.ivory.opacity(0.22), lineWidth: 0.5)
                .frame(width: 54, height: 5)
            Rectangle()
                .fill(motion.isLevel ? Theme.accent : Theme.ivory.opacity(0.55))
                .frame(width: 1.5, height: 9)
                .offset(x: CGFloat(LevelMath.bubbleOffset(roll: motion.roll)) * 27)
        }
        .frame(width: 54, height: 10)
        .animation(.easeOut(duration: 0.08), value: motion.roll)
    }
}
