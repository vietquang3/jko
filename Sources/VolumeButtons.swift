import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import SwiftUI

/// Bắt nút tăng/giảm âm lượng cứng của iPhone.
/// Cách làm: theo dõi AVAudioSession.outputVolume, mỗi lần đổi thì tính là 1 lần bấm
/// rồi đặt âm lượng về mức giữa (0.5) để lần sau còn bấm lên/xuống được.
final class VolumeButtons: NSObject {
    var onPress: ((Bool) -> Void)?          // true = Vol+, false = Vol-

    let volumeView = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?
    private let baseLevel: Float = 0.5
    private var originalLevel: Float = 0.5
    private var active = false

    private var slider: UISlider? {
        for v in volumeView.subviews {
            if let s = v as? UISlider { return s }
        }
        return nil
    }

    func start() {
        if active { return }
        active = true
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        originalLevel = session.outputVolume

        // chờ MPVolumeView được đưa lên màn hình rồi mới đặt mức giữa
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.active else { return }
            self.setLevel(self.baseLevel)
            self.observation = self.session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
                guard let self = self, let v = change.newValue else { return }
                DispatchQueue.main.async {
                    self.volumeChanged(v)
                }
            }
        }
    }

    func stop() {
        if !active { return }
        active = false
        observation?.invalidate()
        observation = nil
        setLevel(originalLevel)          // trả âm lượng về như cũ
    }

    private func volumeChanged(_ v: Float) {
        if !active { return }
        let diff = v - baseLevel
        if abs(diff) < 0.001 { return }  // thay đổi do chính app đặt lại
        onPress?(diff > 0)
        // đặt lại mức giữa ngay sau đó
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            guard let self = self, self.active else { return }
            self.setLevel(self.baseLevel)
        }
    }

    private func setLevel(_ level: Float) {
        slider?.setValue(level, animated: false)
    }
}

/// Đặt MPVolumeView vào màn hình (gần như trong suốt) để iOS không hiện khung âm lượng to giữa màn hình.
struct VolumeHost: UIViewRepresentable {
    let view: MPVolumeView

    func makeUIView(context: Context) -> MPVolumeView {
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
