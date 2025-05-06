// ファイル: ViewModels/CalendarViewModel.swift

import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private let calendar = Calendar.current
    
    @Published var currentDate = Date()
    @Published var days: [Date] = []
    @Published var datesWithWorkouts: [Date] = []
    @Published var workoutSets: [WorkoutSet] = []
    @Published var showWorkoutForm = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentDate)
    }
    
    init() {
        generateDaysInMonth()
    }
    
    func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
            generateDaysInMonth()
            refreshDatesWithWorkouts()
        }
    }
    
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        return calendar.component(.month, from: date) == calendar.component(.month, from: currentDate)
    }
    
    func generateDaysInMonth() {
        days.removeAll()
        
        // 現在月の最初の日と最後の日を取得
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let _ = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        
        // カレンダーの最初の日（その月の1日が含まれる週の日曜日）を取得
        var startDate = monthStart
        if let weekday = calendar.dateComponents([.weekday], from: startDate).weekday, weekday > 1 {
            startDate = calendar.date(byAdding: .day, value: -(weekday - 1), to: startDate)!
        }
        
        // カレンダーに表示する6週間分の日付を生成
        for dayOffset in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                days.append(date)
                
                // 現在月の最終週の土曜日までで終了
                if calendar.component(.month, from: date) != calendar.component(.month, from: monthStart) &&
                   calendar.component(.weekday, from: date) == 7 &&
                   dayOffset > 28 {
                    break
                }
            }
        }
    }
    
    func refreshDatesWithWorkouts() {
        // 表示中の月のワークアウトがある日付を取得
        datesWithWorkouts = coreDataManager.getDatesWithWorkouts(in: currentDate)
    }
    
    func loadWorkouts(for date: Date) {
        // 特定の日付のワークアウトセットを取得
        if let workoutLog = coreDataManager.getWorkoutLog(for: date) {
            if let sets = workoutLog.workoutSets?.allObjects as? [WorkoutSet] {
                workoutSets = sets.sorted(by: { set1, set2 in
                    guard let id1 = set1.id?.uuidString, let id2 = set2.id?.uuidString else {
                        return false
                    }
                    return id1 > id2
                })
            } else {
                workoutSets = []
            }
        } else {
            workoutSets = []
        }
    }
    
    func addWorkoutSet(for date: Date, exercise: Exercise, weight: Double, reps: Int) {
        do {
            let workoutLog = coreDataManager.getOrCreateWorkoutLog(for: date)
            
            _ = coreDataManager.addWorkoutSet(
                to: workoutLog,
                exercise: exercise,
                weight: weight,
                reps: reps
            )
            
            loadWorkouts(for: date)
            refreshDatesWithWorkouts()
            
            // トレーニング更新の通知を送信
            NotificationCenter.default.post(name: .workoutUpdated, object: nil)
        } catch {
            errorMessage = "トレーニングの追加に失敗しました"
            showError = true
            print("ワークアウト追加エラー: \(error)")
        }
    }
    
    func deleteWorkoutSet(_ workoutSet: WorkoutSet) {
        guard let date = workoutSet.workoutLog?.date else {
            print("WorkoutSetの削除に失敗: 関連するWorkoutLogが見つかりません")
            return
        }
        
        // 削除前にIDをローカル変数に保持
        let workoutLogID = workoutSet.workoutLog?.id
        
        // CoreDataから削除
        coreDataManager.viewContext.delete(workoutSet)
        
        do {
            try coreDataManager.viewContext.save()
            
            // UIを更新
            loadWorkouts(for: date)
            refreshDatesWithWorkouts()
            
            // ログに残っているセットがない場合はログも削除
            if let logID = workoutLogID,
               let log = coreDataManager.getWorkoutLogByID(id: logID),
               log.workoutSets?.count == 0 {
                coreDataManager.viewContext.delete(log)
                try coreDataManager.viewContext.save()
            }
        } catch {
            errorMessage = "トレーニングの削除に失敗しました"
            showError = true
            print("WorkoutSet削除エラー: \(error)")
        }
    }
}
