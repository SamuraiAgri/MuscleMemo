// ファイル: ViewModels/StatisticsViewModel.swift

import SwiftUI
import Combine
import CoreData

enum StatisticsPeriod: Int, CaseIterable {
    case month = 1
    case threeMonths = 3
    case sixMonths = 6
    case year = 12
    
    var title: String {
        switch self {
        case .month: return "1ヶ月"
        case .threeMonths: return "3ヶ月"
        case .sixMonths: return "6ヶ月"
        case .year: return "1年"
        }
    }
}

struct WeightChartEntry: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

class StatisticsViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    
    @Published var exercises: [Exercise] = []
    @Published var chartData: [WeightChartEntry] = []
    @Published var monthlyTrainingDays: Int = 0
    @Published var selectedPeriod: StatisticsPeriod = .month
    
    init() {
        // 通知を受け取るための設定
        NotificationCenter.default.publisher(for: .favoriteExerciseToggled)
            .sink { [weak self] _ in
                self?.loadExercises()
            }
            .store(in: &cancellables)
        
        // トレーニング更新の通知を受け取る
        NotificationCenter.default.publisher(for: .workoutUpdated)
            .sink { [weak self] _ in
                self?.calculateMonthlyTrainingFrequency()
            }
            .store(in: &cancellables)
    }
    
    func loadExercises() {
        // トレーニング記録のある種目のみを取得
        let allExercises = coreDataManager.getAllExercises()
        exercises = allExercises.filter { exercise in
            guard let sets = exercise.workoutSets?.allObjects as? [WorkoutSet], !sets.isEmpty else {
                return false
            }
            return true
        }
    }
    
    func loadChartData(for exercise: Exercise) {
        let endDate = Date()
        let months = selectedPeriod.rawValue
        
        guard let startDate = calendar.date(byAdding: .month, value: -months, to: endDate) else {
            chartData = []
            return
        }
        
        // 対象期間のワークアウトセットを取得
        let workoutSets = coreDataManager.getWorkoutSets(for: exercise, between: startDate, and: endDate)
        
        // 日付ごとに最大の重量を抽出
        var weightByDate: [Date: Double] = [:]
        
        for set in workoutSets {
            guard let date = set.workoutLog?.date else { continue }
            
            // 日付の時間部分を削除して日付だけを取得
            let dateKey = calendar.startOfDay(for: date)
            
            if let existingWeight = weightByDate[dateKey], existingWeight >= set.weight {
                // 既存の重量の方が大きい場合はスキップ
                continue
            }
            
            // 新しい重量を記録
            weightByDate[dateKey] = set.weight
        }
        
        // チャートデータに変換してソート
        chartData = weightByDate.map { date, weight in
            WeightChartEntry(date: date, weight: weight)
        }.sorted { $0.date < $1.date }
        
        // データ更新を通知
        objectWillChange.send()
    }
    
    func calculateMonthlyTrainingFrequency() {
        let today = Date()
        
        // 現在の月の最初の日を取得
        var components = calendar.dateComponents([.year, .month], from: today)
        components.day = 1
        guard let firstDayOfMonth = calendar.date(from: components) else {
            monthlyTrainingDays = 0
            return
        }
        
        // 現在の月の最後の日を取得
        guard let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else {
            monthlyTrainingDays = 0
            return
        }
        
        // 現在の月のトレーニング日を取得
        let trainingDates = coreDataManager.getDatesWithWorkouts(in: firstDayOfMonth)
        
        // 日付が現在の月に属するかどうか確認してフィルタリング
        let filteredDates = trainingDates.filter { date in
            return calendar.isDate(date, equalTo: firstDayOfMonth, toGranularity: .month) &&
                   calendar.isDate(date, equalTo: firstDayOfMonth, toGranularity: .year)
        }
        
        // トレーニング日数を更新
        DispatchQueue.main.async { [weak self] in
            self?.monthlyTrainingDays = filteredDates.count
            self?.objectWillChange.send()
        }
        
        print("今月(\(calendar.component(.month, from: today))月)のトレーニング日数: \(filteredDates.count)")
    }
    
    func getLastWeightForExercise(_ exercise: Exercise) -> Double {
        if let lastSet = coreDataManager.getLastWorkoutSet(for: exercise) {
            return lastSet.weight
        }
        return 0
    }
    
    func getMaxWeightForExercise(_ exercise: Exercise) -> Double {
        guard let workoutSets = exercise.workoutSets?.allObjects as? [WorkoutSet], !workoutSets.isEmpty else {
            return 0
        }
        
        return workoutSets.map { $0.weight }.max() ?? 0
    }
    
    func getAverageWeightForExercise(_ exercise: Exercise) -> Double {
        guard let workoutSets = exercise.workoutSets?.allObjects as? [WorkoutSet], !workoutSets.isEmpty else {
            return 0
        }
        
        let totalWeight = workoutSets.reduce(0) { $0 + $1.weight }
        return totalWeight / Double(workoutSets.count)
    }
    
    func getChartDataForExercise(_ exercise: Exercise) -> [WeightChartEntry] {
        if chartData.isEmpty {
            loadChartData(for: exercise)
        }
        return chartData
    }
}

// トレーニング更新の通知
extension Notification.Name {
    static let workoutUpdated = Notification.Name("workoutUpdated")
}
