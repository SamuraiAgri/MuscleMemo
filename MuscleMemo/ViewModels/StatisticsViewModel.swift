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
    @Published var isLoadingChartData: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init() {
        // 通知を受け取るための設定
        NotificationCenter.default.publisher(for: .favoriteExerciseToggled)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadExercises()
            }
            .store(in: &cancellables)
        
        // トレーニング更新の通知を受け取る
        NotificationCenter.default.publisher(for: .workoutUpdated)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.calculateMonthlyTrainingFrequency()
                if let selectedExercise = self?.exercises.first {
                    self?.loadChartData(for: selectedExercise)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadExercises() {
        // トレーニング記録のある種目のみを取得
        let allExercises = coreDataManager.getAllExercises()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let filteredExercises = allExercises.filter { exercise in
                guard let sets = exercise.workoutSets?.allObjects as? [WorkoutSet], !sets.isEmpty else {
                    return false
                }
                return true
            }
            
            DispatchQueue.main.async {
                self?.exercises = filteredExercises
                self?.objectWillChange.send()
            }
        }
    }
    
    func loadChartData(for exercise: Exercise) {
        isLoadingChartData = true
        chartData = []
        errorMessage = nil
        
        let endDate = Date()
        let months = selectedPeriod.rawValue
        
        guard let startDate = calendar.date(byAdding: .month, value: -months, to: endDate) else {
            isLoadingChartData = false
            chartData = []
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 対象期間のワークアウトセットを取得
            let workoutSets = self.coreDataManager.getWorkoutSets(for: exercise, between: startDate, and: endDate)
            
            // 日付ごとに最大の重量を抽出
            var weightByDate: [Date: Double] = [:]
            
            for set in workoutSets {
                guard let date = set.workoutLog?.date else { continue }
                
                // 日付の時間部分を削除して日付だけを取得
                let dateKey = self.calendar.startOfDay(for: date)
                
                if let existingWeight = weightByDate[dateKey], existingWeight >= set.weight {
                    // 既存の重量の方が大きい場合はスキップ
                    continue
                }
                
                // 新しい重量を記録
                weightByDate[dateKey] = set.weight
            }
            
            // チャートデータに変換してソート
            let newChartData = weightByDate.map { date, weight in
                WeightChartEntry(date: date, weight: weight)
            }.sorted { $0.date < $1.date }
            
            DispatchQueue.main.async {
                self.chartData = newChartData
                self.isLoadingChartData = false
                self.objectWillChange.send()
            }
        }
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
            if chartData.isEmpty || isLoadingChartData {
                loadChartData(for: exercise)
            }
            return chartData
        }
        
        // 重量提案機能の追加
        func suggestNextWeight(for exercise: Exercise) -> Double {
            guard let lastSet = coreDataManager.getLastWorkoutSet(for: exercise) else {
                return 0
            }
            
            let lastWeight = lastSet.weight
            let lastReps = lastSet.reps
            
            // 前回が12回以上なら重量アップ、6回未満なら重量ダウン、それ以外は維持
            if lastReps >= 12 {
                // 重量5%アップ（最小2.5kg）
                let increment = max(2.5, lastWeight * 0.05)
                return round((lastWeight + increment) * 2) / 2  // 0.5kg単位に丸める
            } else if lastReps < 6 {
                // 重量5%ダウン
                let decrement = lastWeight * 0.05
                return max(0, round((lastWeight - decrement) * 2) / 2)  // 0.5kg単位に丸める
            }
            
            return lastWeight  // 現状維持
        }
    }

    // トレーニング更新の通知
    extension Notification.Name {
        static let workoutUpdated = Notification.Name("workoutUpdated")
    }
