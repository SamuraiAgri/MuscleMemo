// ファイル: ViewModels/ExerciseManagementViewModel.swift

import SwiftUI
import CoreData
import Combine  // Combineフレームワークをインポート

class ExerciseManagementViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var exercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    init() {
        // 通知を受け取るための設定
        NotificationCenter.default.publisher(for: .favoriteExerciseToggled)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadExercises()
            }
            .store(in: &cancellables)
    }
    
    func loadExercises() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let allExercises = self.coreDataManager.getAllExercises()
            
            DispatchQueue.main.async {
                self.exercises = allExercises
                self.isLoading = false
                self.objectWillChange.send() // 明示的な更新通知
            }
        }
    }
    
    func addExercise(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "種目名を入力してください"
            showError = true
            return
        }
        
        // 既存の種目と重複しないか確認
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingNames = exercises.compactMap { $0.name?.lowercased() }
        
        if existingNames.contains(trimmedName.lowercased()) {
            errorMessage = "その種目名は既に存在します"
            showError = true
            return
        }
        
        let context = coreDataManager.viewContext
        let newExercise = Exercise(context: context)
        newExercise.id = UUID()
        newExercise.name = trimmedName
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
            errorMessage = "デフォルト種目は削除できません"
            showError = true
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
        
        do {
            try context.save()
            loadExercises()
            
            // 空になったWorkoutLogを削除
            coreDataManager.cleanupEmptyWorkoutLogs()
            
            // 通知を送信して他の画面を更新
            NotificationCenter.default.post(name: .workoutUpdated, object: nil)
        } catch {
            errorMessage = "種目の削除に失敗しました"
            showError = true
            print("種目削除エラー: \(error)")
        }
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
