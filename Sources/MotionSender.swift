import Foundation
import CoreMotion
import Network
import UIKit

final class MotionSender: ObservableObject {
    @Published var host: String = UserDefaults.standard.string(forKey: "pcHost") ?? "192.168.1."
    @Published var running: Bool = false
    @Published var statusText: String = "Nhập IP máy tính (script in ra) rồi bấm BẮT ĐẦU"
    @Published var bigText: String = "—"
    @Published var pcMessage: String = ""
    @Published var packets: Int = 0

    private let motion = CMMotionManager()
    private let motionQueue = OperationQueue()
    private let netQueue = DispatchQueue(label: "box.net")
    private var connection: NWConnection?
    private var receiving = false
    private var sent: Int = 0
    private var uiTimer: Timer?
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)
    let volume = VolumeButtons()
    private var btnSeq: UInt8 = 0

    func start() {
        if running { return }
        let h = host.trimmingCharacters(in: .whitespaces)
        if h.isEmpty {
            statusText = "Chưa nhập IP"
            return
        }
        UserDefaults.standard.set(h, forKey: "pcHost")
        UIApplication.shared.isIdleTimerDisabled = true

        let conn = NWConnection(host: NWEndpoint.Host(h), port: NWEndpoint.Port(rawValue: 9876)!, using: .udp)
        connection = conn
        receiving = false
        conn.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleState(state)
            }
        }
        conn.start(queue: netQueue)
        running = true
        sent = 0
        statusText = "Đang kết nối…"
        startMotion()

        volume.onPress = { [weak self] up in
            self?.sendButton(up)
        }
        volume.start()

        uiTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.packets = self.sent
            self.sendHello()
        }
        haptic.prepare()
    }

    func stop() {
        volume.stop()
        motion.stopDeviceMotionUpdates()
        uiTimer?.invalidate()
        uiTimer = nil
        connection?.cancel()
        connection = nil
        receiving = false
        running = false
        UIApplication.shared.isIdleTimerDisabled = false
        statusText = "Đã dừng"
    }

    private func handleState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            statusText = "Đang gửi tới PC"
            if !receiving {
                receiving = true
                receiveLoop()
            }
            sendHello()
        case .waiting(let err):
            statusText = "Chờ mạng… kiểm tra Wi-Fi và quyền Mạng cục bộ (\(err))"
        case .failed(let err):
            statusText = "Lỗi: \(err)"
            stop()
        default:
            break
        }
    }

    /// Gửi 1 lần bấm nút âm lượng: 'B' + 'U'/'D' + số thứ tự. Gửi 2 lần cho chắc, PC tự bỏ bản trùng.
    private func sendButton(_ up: Bool) {
        guard let conn = connection else { return }
        btnSeq = btnSeq &+ 1
        let data = Data([0x42, up ? 0x55 : 0x44, btnSeq])
        conn.send(content: data, completion: .contentProcessed({ _ in }))
        netQueue.asyncAfter(deadline: .now() + 0.02) {
            conn.send(content: data, completion: .contentProcessed({ _ in }))
        }
    }

    private func sendHello() {
        guard let conn = connection else { return }
        // chỉ gửi "H" khi chưa nhận được gì từ PC (để PC biết địa chỉ điện thoại)
        if pcMessage.isEmpty {
            conn.send(content: Data([0x48]), completion: .contentProcessed({ _ in }))
        }
    }

    private func receiveLoop() {
        connection?.receiveMessage { [weak self] data, _, _, error in
            guard let self = self else { return }
            if let data = data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.handleMessage(text)
                }
            }
            if error == nil {
                self.receiveLoop()
            }
        }
    }

    private func handleMessage(_ text: String) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        var i = 0
        while i < lines.count {
            let line = String(lines[i])
            if line.hasPrefix("MSG|") {
                // tin MSG có thể có nhiều dòng: gộp các dòng không có tiền tố
                var msg = String(line.dropFirst(4))
                var j = i + 1
                while j < lines.count {
                    let nxt = String(lines[j])
                    if nxt.hasPrefix("MSG|") || nxt.hasPrefix("EV|") || nxt.hasPrefix("HIT|") { break }
                    msg += "\n" + nxt
                    j += 1
                }
                pcMessage = msg
                i = j
                continue
            } else if line.hasPrefix("HIT|") {
                bigText = String(line.dropFirst(4))
                haptic.impactOccurred()
                haptic.prepare()
            } else if line.hasPrefix("EV|") {
                bigText = String(line.dropFirst(3))
            }
            i += 1
        }
    }

    private func startMotion() {
        if !motion.isDeviceMotionAvailable {
            statusText = "Máy không có cảm biến chuyển động"
            return
        }
        motionQueue.maxConcurrentOperationCount = 1
        motion.deviceMotionUpdateInterval = 1.0 / 100.0
        motion.startDeviceMotionUpdates(to: motionQueue) { [weak self] dm, _ in
            guard let self = self, let m = dm, let conn = self.connection else { return }
            let floats: [Float32] = [
                Float32(m.userAcceleration.x), Float32(m.userAcceleration.y), Float32(m.userAcceleration.z),
                Float32(m.gravity.x), Float32(m.gravity.y), Float32(m.gravity.z),
                Float32(m.rotationRate.x), Float32(m.rotationRate.y), Float32(m.rotationRate.z)
            ]
            var data = Data([0x4D])
            floats.withUnsafeBufferPointer { buf in
                data.append(Data(buffer: buf))
            }
            conn.send(content: data, completion: .contentProcessed({ _ in }))
            self.sent += 1
        }
    }
}
