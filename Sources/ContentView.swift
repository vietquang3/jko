import SwiftUI

struct ContentView: View {
    @StateObject private var sender = MotionSender()

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VolumeHost(view: sender.volume.volumeView)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
            VStack(spacing: 16) {
                Text("BOX CONTROLLER")
                    .font(.headline)
                    .foregroundColor(.gray)

                Text(sender.bigText)
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text(sender.pcMessage)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Spacer()

                if sender.running {
                    Text("GIỮ 1 GIÂY ĐỂ DỪNG")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(12)
                        .onLongPressGesture(minimumDuration: 1.0) {
                            sender.stop()
                        }
                } else {
                    TextField("IP máy tính, vd 192.168.1.5", text: $sender.host)
                        .keyboardType(.numbersAndPunctuation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: { sender.start() }) {
                        Text("BẮT ĐẦU")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }

                Text(sender.statusText + (sender.running ? "  |  gói: \(sender.packets)" : ""))
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
