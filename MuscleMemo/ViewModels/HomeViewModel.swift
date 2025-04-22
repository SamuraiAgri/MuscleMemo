// ファイル: ViewModels/HomeViewModel.swift

import Foundation
import SwiftUI
import Combine
import CoreData

class HomeViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var todaysWorkoutSets: [WorkoutSet] = []
    @Published var favoriteExercises: [Exercise] = []
    @Published var isLoading: Bool = false
    
    init() {
        // アプリ起動時に初期データを読み込む
        loadInitialData()
        
        // 通知を受け取るための設定
        NotificationCenter.default.publisher(for: .favoriteExerciseToggled)
            .sink { [weak self] _ in
                self?.loadFavoriteExercises()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshTodaysWorkouts()
            self?.loadFavoriteExercises()
        }
    }
    
    func refreshTodaysWorkouts() {
        isLoading = true
        
        let today = Date()
        
        if let workoutLog = coreDataManager.getWorkoutLog(for: today) {
            // workoutLogからWorkoutSetの配列を取得
            if let sets = workoutLog.workoutSets?.allObjects as? [WorkoutSet] {
                // 日付で降順ソート
                todaysWorkoutSets = sets.sorted(by: { set1, set2 in
                    return set1.id?.uuidString ?? "" > set2.id?.uuidString ?? ""
                })
            } else {
                todaysWorkoutSets = []
            }
        } else {
            todaysWorkoutSets = []
        }
        
        // 変更を明示的に通知
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.objectWillChange.send()
        }
    }
    
    func loadFavoriteExercises() {
        isLoading = true
        
        // お気に入り種目を読み込む
        let favorites = coreDataManager.getFavoriteExercises()
        
        // UIスレッドで更新
        DispatchQueue.main.async { [weak self] in
            self?.favoriteExercises = favorites
            self?.isLoading = false
            self?.objectWillChange.send()
        }
    }
    
    func addWorkoutSet(exercise: Exercise, weight: Double, reps: Int) {
        let today = Date()
        let workoutLog = coreDataManager.getOrCreateWorkoutLog(for: today)
        
        _ = coreDataManager.addWorkoutSet(
            to: workoutLog,
            exercise: exercise,
            weight: weight,
            reps: reps
        )
        
        refreshTodaysWorkouts()
        
        // トレーニング更新の通知を送信
        NotificationCenter.default.post(name: .workoutUpdated, object: nil)
    }
    
    func getLastWorkoutSet(for exercise: Exercise) -> WorkoutSet? {
        return coreDataManager.getLastWorkoutSet(for: exercise)
    }
    
    // 種目をお気に入りに登録/解除
    func toggleFavorite(exercise: Exercise) {
        let isFavorite = coreDataManager.toggleFavorite(exercise: exercise)
        print("種目「\(exercise.name ?? "")」をお気に入り\(isFavorite ? "登録" : "解除")しました")
        loadFavoriteExercises() // お気に入りリストを更新
        
        // 通知を送信
        NotificationCenter.default.post(name: .favoriteExerciseToggled, object: exercise.id)
    }
}
