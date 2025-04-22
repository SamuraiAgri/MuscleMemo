// ファイル: Common/Constants/AppConstants.swift

import Foundation

struct AppConstants {
    // アプリ全般
    static let appName = "MuscleMemo"
    static let appVersion = "1.0.0"
    
    // UI関連
    static let cornerRadius: CGFloat = 10
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    // エラーメッセージ
    static let genericErrorMessage = "エラーが発生しました。もう一度お試しください。"
    static let networkErrorMessage = "ネットワークエラーが発生しました。接続を確認してください。"
    static let dataErrorMessage = "データの読み込みに失敗しました。"
    
    // その他
    static let defaultExercises = [
        "ベンチプレス", "スクワット", "デッドリフト", "ショルダープレス", "懸垂",
        "バーベルローイング", "レッグプレス", "レッグエクステンション", "レッグカール",
        "アームカール", "トライセプスエクステンション", "ラットプルダウン", "チェストフライ",
        "サイドレイズ", "プランク", "クランチ", "レッグレイズ", "ディップス",
        "プッシュアップ", "ヒップスラスト"
    ]
}
