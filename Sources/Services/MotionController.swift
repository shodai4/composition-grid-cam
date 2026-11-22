import CoreMotion
import Foundation
import UIKit

/// 水準器。deviceMotion を 30 回/秒で読み、傾きと仰角を 0.1 度単位で出す。
/// 水平に入った瞬間だけ触覚で知らせる。
final class MotionController: ObservableObject {
    @Published private(set) var roll: Double = 0
    @Published private(set) var elevation: Double = 0
    @Published private(set) var isAvailable = false

    private let manager = CMMotionManager()
    private var wasLevel = true
    private var hasReading = false

    /// 水平とみなせるか。
    var isLevel: Bool { LevelMath.isLevel(roll: roll) }

    func start() {
        guard manager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }
        isAvailable = true
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.consume(gravity: motion.gravity)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        hasReading = false
    }

    private func consume(gravity: CMAcceleration) {
        let rawRoll = LevelMath.roll(gravityX: gravity.x, gravityY: gravity.y)
        let rawElevation = LevelMath.elevation(gravityZ: gravity.z)

        // 0.1 度の読みが揺れないよう、軽く均す。
        if hasReading {
            roll += (rawRoll - roll) * 0.35
            elevation += (rawElevation - elevation) * 0.35
        } else {
            roll = rawRoll
            elevation = rawElevation
            hasReading = true
        }

        let level = LevelMath.isLevel(roll: roll)
        if level != wasLevel {
            wasLevel = level
            if level {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}
