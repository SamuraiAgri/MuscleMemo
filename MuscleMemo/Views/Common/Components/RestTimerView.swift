// ファイル: Views/Common/Components/RestTimerView.swift

import SwiftUI
import Combine

struct RestTimerView: View {
    @StateObject private var timer = RestTimerManager()
    @State private var selectedDuration: Int = 90 // デフォルト90秒
    
    let presetDurations = [30, 60, 90, 120, 180]
    
    var body: some View {
        VStack(spacing: 16) {
            // タイマー表示
            ZStack {
                // 背景円
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 150, height: 150)
                
                // 進捗円
                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(
                        timer.isActive ? Color.primaryRed : Color.gray,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timer.progress)
                
                // 時間表示
                VStack(spacing: 4) {
                    Text(timer.timeString)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(timer.isActive ? Color.darkGray : .secondary)
                    
                    if timer.isActive {
                        Text("休憩中")
                            .font(.caption)
                            .foregroundColor(Color.primaryRed)
                    }
                }
            }
            
            // プリセットボタン
            HStack(spacing: 8) {
                ForEach(presetDurations, id: \.self) { duration in
                    Button(action: {
                        selectedDuration = duration
                        timer.setDuration(duration)
                    }) {
                        Text("\(duration)秒")
                            .font(.caption)
                            .fontWeight(selectedDuration == duration ? .bold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedDuration == duration ? Color.primaryRed : Color.lightGray)
                            .foregroundColor(selectedDuration == duration ? .white : Color.darkGray)
                            .cornerRadius(16)
                    }
                }
            }
            
            // コントロールボタン
            HStack(spacing: 20) {
                // リセットボタン
                Button(action: {
                    timer.reset()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(Color.darkGray)
                        .frame(width: 50, height: 50)
                        .background(Color.lightGray)
                        .clipShape(Circle())
                }
                
                // スタート/ストップボタン
                Button(action: {
                    if timer.isActive {
                        timer.pause()
                    } else {
                        timer.start()
                    }
                }) {
                    Image(systemName: timer.isActive ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.primaryRed)
                        .clipShape(Circle())
                }
                
                // +30秒ボタン
                Button(action: {
                    timer.addTime(30)
                }) {
                    Text("+30")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.darkGray)
                        .frame(width: 50, height: 50)
                        .background(Color.lightGray)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            timer.setDuration(selectedDuration)
        }
    }
}

class RestTimerManager: ObservableObject {
    @Published var remainingSeconds: Int = 90
    @Published var isActive: Bool = false
    @Published var totalDuration: Int = 90
    
    private var cancellable: AnyCancellable?
    
    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 1.0 }
        return Double(remainingSeconds) / Double(totalDuration)
    }
    
    func setDuration(_ seconds: Int) {
        totalDuration = seconds
        remainingSeconds = seconds
        isActive = false
        cancellable?.cancel()
    }
    
    func start() {
        guard remainingSeconds > 0 else {
            remainingSeconds = totalDuration
            return
        }
        
        isActive = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.timerCompleted()
                }
            }
    }
    
    func pause() {
        isActive = false
        cancellable?.cancel()
    }
    
    func reset() {
        isActive = false
        cancellable?.cancel()
        remainingSeconds = totalDuration
    }
    
    func addTime(_ seconds: Int) {
        remainingSeconds += seconds
        totalDuration += seconds
    }
    
    private func timerCompleted() {
        isActive = false
        cancellable?.cancel()
        
        // ハプティックフィードバック
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // タイマー完了時にリセット
        remainingSeconds = totalDuration
    }
    
    deinit {
        cancellable?.cancel()
    }
}
