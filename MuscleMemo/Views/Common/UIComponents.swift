// ファイル: Views/Common/UIComponents.swift

import SwiftUI

// 共通のローディング表示用ビュー
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.7)
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("読み込み中...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 共通のエラー表示用ビュー
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.white)
                
                Text(message)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
        }
        .padding()
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// シェアシート用の構造体
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
