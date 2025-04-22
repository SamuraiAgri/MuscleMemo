// ファイル: Common/Extensions/Color+Extension.swift

import SwiftUI

extension Color {
    // カラーコードから色を生成するための拡張
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // アプリの主要カラー定義
    static let primaryRed = Color(hex: "E53935")        // メインの赤色
    static let lightGray = Color(hex: "F5F5F5")         // 背景色用ライトグレー
    static let darkGray = Color(hex: "616161")          // テキスト用ダークグレー
    static let accentOrange = Color(hex: "FF9800")      // アクセントオレンジ
    static let successGreen = Color(hex: "4CAF50")      // 成功表示用グリーン
}
