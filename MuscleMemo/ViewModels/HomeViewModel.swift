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
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init() {
        // アプリ起動時に初期データを読み込む
        loadInitialData()
        
        // 通知を受け取るための設定
        NotificationCenter.default.publisher(for: .favoriteExerciseToggled)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadFavoriteExercises()
            }
            .store(in: &cancellables)
        
        // トレーニング更新通知
        NotificationCenter.default.publisher(for: .workoutUpdated)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshTodaysWorkouts()
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
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let today = Date()
            var sets: [WorkoutSet] = []
            
            if let workoutLog = self.coreDataManager.getWorkoutLog(for: today) {
                if let workoutSets = workoutLog.workoutSets?.allObjects as? [WorkoutSet] {
                    sets = workoutSets.sorted(by: { set1, set2 in
                        guard let id1 = set1.id?.uuidString, let id2 = set2.id?.uuidString else {
                            return false
                        }
                        return id1 > id2
                    })
                }
            }
            
            DispatchQueue.main.async {
                self.todaysWorkoutSets = sets
                self.isLoading = false
                self.objectWillChange.send()
            }
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
        do {
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
        } catch {
            errorMessage = "トレーニング記録の追加に失敗しました"
            showError = true
            print("ワークアウト追加エラー: \(error)")
        }
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
    
    // スマートな重量提案機能
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
