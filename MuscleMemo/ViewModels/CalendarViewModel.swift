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
                    return set1.id?.uuidString ?? "" > set2.id?.uuidString ?? ""
                })
            } else {
                workoutSets = []
            }
        } else {
            workoutSets = []
        }
    }
    
    func addWorkoutSet(for date: Date, exercise: Exercise, weight: Double, reps: Int) {
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
    }
    
    func deleteWorkoutSet(_ workoutSet: WorkoutSet) {
        if let date = workoutSet.workoutLog?.date {
            // CoreDataから削除
            coreDataManager.viewContext.delete(workoutSet)
            coreDataManager.saveContext()
            
            // UIを更新
            loadWorkouts(for: date)
            refreshDatesWithWorkouts()
        }
    }
}
