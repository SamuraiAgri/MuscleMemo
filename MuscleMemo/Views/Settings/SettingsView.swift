// ファイル: Views/Settings/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("基本設定")) {
                    NavigationLink(destination: ExerciseManagementView()) {
                        SettingsRow(
                            icon: "dumbbell",
                            title: "種目管理",
                            subtitle: "種目の追加、削除、お気に入り設定"
                        )
                    }
                }
                
                Section(header: Text("データ管理")) {
                    Button(action: {
                        viewModel.exportData()
                    }) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "データをエクスポート",
                            subtitle: "トレーニング記録をファイルに保存"
                        )
                    }
                    
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        SettingsRow(
                            icon: "trash",
                            title: "データをリセット",
                            subtitle: "全てのトレーニング記録を削除",
                            iconColor: .red
                        )
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    SettingsRow(
                        icon: "info.circle",
                        title: "バージョン",
                        subtitle: "1.0.0"
                    )
                }
            }
            .navigationTitle("設定")
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("データをリセット"),
                    message: Text("全てのトレーニング記録が削除されます。この操作は元に戻せません。"),
                    primaryButton: .destructive(Text("リセット")) {
                        viewModel.resetAllData()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = Color.primaryRed
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
