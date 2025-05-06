// ファイル: Views/Settings/SettingsView.swift

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingResetConfirmation = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            showingShareSheet = true
                        }) {
                            SettingsRow(
                                icon: "square.and.arrow.up",
                                title: "データをエクスポート",
                                subtitle: "トレーニング記録をファイルに保存"
                            )
                        }
                        .disabled(viewModel.isExporting)
                        
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
                .sheet(isPresented: $showingShareSheet) {
                    if let url = viewModel.exportURL {
                        ShareSheet(items: [url])
                    }
                }
                .overlay(Group {
                    if viewModel.isExporting {
                        LoadingView()
                    }
                })
                
                // エラー表示
                if viewModel.showError {
                    VStack {
                        Text(viewModel.errorMessage ?? "エラーが発生しました")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 100)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                viewModel.showError = false
                            }
                        }
                    }
                }
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
