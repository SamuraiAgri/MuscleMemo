// ファイル: Views/Common/Components/CustomButton.swift

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var isPrimary: Bool = true
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(backgroundColor)
                .cornerRadius(10)
        }
        .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        }
        return isPrimary ? Color.primaryRed : Color.white
    }
    
    private var textColor: Color {
        if isDisabled {
            return Color.gray
        }
        return isPrimary ? Color.white : Color.primaryRed
    }
}

struct CustomButtonStyle: ButtonStyle {
    var isPrimary: Bool = true
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                backgroundColor
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        }
        return isPrimary ? Color.primaryRed : Color.white
    }
    
    private var textColor: Color {
        if isDisabled {
            return Color.gray
        }
        return isPrimary ? Color.white : Color.primaryRed
    }
}

extension View {
    func customButtonStyle(isPrimary: Bool = true, isDisabled: Bool = false) -> some View {
        self.buttonStyle(CustomButtonStyle(isPrimary: isPrimary, isDisabled: isDisabled))
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomButton(title: "プライマリーボタン", action: {})
            
            CustomButton(title: "セカンダリーボタン", action: {}, isPrimary: false)
            
            CustomButton(title: "無効ボタン", action: {}, isDisabled: true)
            
            Button("カスタムスタイルボタン") {}
                .customButtonStyle()
            
            Button("無効スタイルボタン") {}
                .customButtonStyle(isDisabled: true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
