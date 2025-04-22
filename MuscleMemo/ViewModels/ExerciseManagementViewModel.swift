// ファイル: ViewModels/ExerciseManagementViewModel.swift

import SwiftUI
import CoreData
import Combine  // Combineフレームワークをインポート

class ExerciseManagementViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var exercises: [Exercise] = []
    
    init() {
        // 通知を受け取るための設定
        NotificationCenter.default.publisher(for: .favoriteExerciseToggled)
            .sink { [weak self] _ in
                self?.loadExercises()
            }
            .store(in: &cancellables)
    }
    
    func loadExercises() {
        exercises = coreDataManager.getAllExercises()
        objectWillChange.send() // 明示的な更新通知
    }
    
    func addExercise(name: String) {
        let context = coreDataManager.viewContext
        let newExercise = Exercise(context: context)
        newExercise.id = UUID()
        newExercise.name = name
        newExercise.isDefault = false
        newExercise.isFavorite = false
        
        coreDataManager.saveContext()
        loadExercises()
    }
    
    func toggleFavorite(exercise: Exercise) {
        let isFavorite = coreDataManager.toggleFavorite(exercise: exercise)
        // 処理完了をコンソールに出力（デバッグ用）
        print("種目「\(exercise.name ?? "")」をお気に入り\(isFavorite ? "登録" : "解除")しました")
        
        // UIを即時更新
        objectWillChange.send()
        
        // 通知を送信
        NotificationCenter.default.post(name: .favoriteExerciseToggled, object: exercise)
        
        // リストも更新
        loadExercises()
    }
    
    func deleteExercise(exercise: Exercise) {
        // デフォルト種目は削除不可
        if exercise.isDefault {
            return
        }
        
        let context = coreDataManager.viewContext
        
        // 関連するWorkoutSetも削除
        if let sets = exercise.workoutSets?.allObjects as? [WorkoutSet] {
            for set in sets {
                context.delete(set)
            }
        }
        
        context.delete(exercise)
        coreDataManager.saveContext()
        loadExercises()
    }
    
    // 検索機能
    func searchExercises(query: String) -> [Exercise] {
        if query.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name?.localizedCaseInsensitiveContains(query) ?? false }
        }
    }
    
    // カテゴリーで種目をフィルタリング
    func getExercisesByCategory(category: ExerciseCategory) -> [Exercise] {
        switch category {
        case .all:
            return exercises
        case .favorites:
            return exercises.filter { $0.isFavorite }
        case .custom:
            return exercises.filter { !$0.isDefault }
        case .default:
            return exercises.filter { $0.isDefault }
        }
    }
}

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case all = "すべて"
    case favorites = "お気に入り"
    case custom = "カスタム"
    case `default` = "デフォルト"
    
    var id: String { self.rawValue }
}
