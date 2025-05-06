// ファイル: Views/ContentView.swift

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(Color.primaryRed)
        .onAppear {
            // デフォルトの筋トレ種目を作成
            CoreDataManager.shared.createDefaultExercises()
            
            // タブバーの外観をカスタマイズ
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
            
            // デバッグ情報の出力（デバッグビルドのみ）
            #if DEBUG
            printDatabaseDebugInfo()
            #endif
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                // アプリがバックグラウンドに移行したときにデータを保存
                CoreDataManager.shared.saveContext()
            }
        }
    }
    
    // デバッグ用のデータベース状態出力
    private func printDatabaseDebugInfo() {
        let context = CoreDataManager.shared.viewContext
        
        // Exerciseエンティティの状態を出力
        let exerciseFetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        do {
            let exercises = try context.fetch(exerciseFetchRequest)
            print("📊 Exerciseの総数: \(exercises.count)")
            print("📊 お気に入り種目数: \(exercises.filter { $0.isFavorite }.count)")
            print("📊 デフォルト種目数: \(exercises.filter { $0.isDefault }.count)")
        } catch {
            print("❌ Exerciseの取得に失敗: \(error)")
        }
        
        // WorkoutLogエンティティの状態を出力
        let logFetchRequest: NSFetchRequest<WorkoutLog> = WorkoutLog.fetchRequest()
        do {
            let logs = try context.fetch(logFetchRequest)
            print("📊 トレーニングログの総数: \(logs.count)")
            
            if let latestLog = logs.sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) }).first {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.locale = Locale(identifier: "ja_JP")
                print("📊 最新のトレーニング日: \(formatter.string(from: latestLog.date ?? Date()))")
            }
        } catch {
            print("❌ WorkoutLogの取得に失敗: \(error)")
        }
    }
}
