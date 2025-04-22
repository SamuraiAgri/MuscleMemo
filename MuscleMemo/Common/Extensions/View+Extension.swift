// ファイル: Common/Extensions/View+Extension.swift

import SwiftUI

extension View {
    /// 条件に応じてパディングを追加する
    @ViewBuilder func conditionalPadding(_ edge: Edge.Set, _ length: CGFloat, if condition: Bool) -> some View {
        if condition {
            self.padding(edge, length)
        } else {
            self
        }
    }
    
    /// シャドウを適用する
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    /// カードスタイルを適用する
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .standardShadow()
    }
}
