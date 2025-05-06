// ファイル: ViewModels/SettingsViewModel.swift

import SwiftUI
import CoreData

class SettingsViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    @Published var isExporting = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var exportURL: URL?
    
    func exportData() {
        isExporting = true
        // 実際のアプリではファイル共有やクラウドバックアップなどの実装を行う
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer {
                DispatchQueue.main.async {
                    self?.isExporting = false
                }
            }
            
            // JSONデータのエクスポート
            if let url = self?.exportDataToJSON() {
                DispatchQueue.main.async {
                    self?.exportURL = url
                }
            } else {
                DispatchQueue.main.async {
                    self?.errorMessage = "データのエクスポートに失敗しました"
                    self?.showError = true
                }
            }
        }
    }
    
    func resetAllData() {
        let context = coreDataManager.viewContext
        
        do {
            // バッチ削除処理を使用してより効率的に削除
            coreDataManager.batchDeleteAllWorkoutSets()
            
            // WorkoutLogを全て削除
            let fetchRequestLogs: NSFetchRequest<NSFetchRequestResult> = WorkoutLog.fetchRequest()
            let deleteLogs = NSBatchDeleteRequest(fetchRequest: fetchRequestLogs)
            deleteLogs.resultType = .resultTypeObjectIDs
            if let result = try context.execute(deleteLogs) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            }
            
            // カスタム種目を削除（デフォルト種目は残す）
            let fetchRequestExercises: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            fetchRequestExercises.predicate = NSPredicate(format: "isDefault == %@", NSNumber(value: false))
            
            let customExercises = try context.fetch(fetchRequestExercises)
            for exercise in customExercises {
                context.delete(exercise)
            }
            
            coreDataManager.saveContext()
            
            // デフォルト種目のお気に入り状態をリセット
            let defaultExercises: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            defaultExercises.predicate = NSPredicate(format: "isDefault == %@", NSNumber(value: true))
            
            let defaultList = try context.fetch(defaultExercises)
            for exercise in defaultList {
                exercise.isFavorite = false
            }
            
            coreDataManager.saveContext()
            
            // 通知を送信
            NotificationCenter.default.post(name: .workoutUpdated, object: nil)
            NotificationCenter.default.post(name: .favoriteExerciseToggled, object: nil)
        } catch {
            errorMessage = "データリセットに失敗しました"
            showError = true
            print("データリセットに失敗: \(error)")
        }
    }
    
    func exportDataToJSON() -> URL? {
        // エクスポートするデータを取得
        let exercises = coreDataManager.getAllExercises()
        
        // JSONに変換可能な形式に変形
        var exportData: [String: Any] = [:]
        var exercisesData: [[String: Any]] = []
        
        for exercise in exercises {
            var exerciseDict: [String: Any] = [
                "id": exercise.id?.uuidString ?? UUID().uuidString,
                "name": exercise.name ?? "",
                "isDefault": exercise.isDefault,
                "isFavorite": exercise.isFavorite
            ]
            
            var sets: [[String: Any]] = []
            if let workoutSets = exercise.workoutSets?.allObjects as? [WorkoutSet] {
                for set in workoutSets {
                    if let log = set.workoutLog, let date = log.date {
                        let setDict: [String: Any] = [
                            "id": set.id?.uuidString ?? UUID().uuidString,
                            "weight": set.weight,
                            "reps": set.reps,
                            "date": date.timeIntervalSince1970
                        ]
                        sets.append(setDict)
                    }
                }
            }
            
            exerciseDict["sets"] = sets
            exercisesData.append(exerciseDict)
        }
        
        exportData["exercises"] = exercisesData
        exportData["version"] = "1.0"
        exportData["exportDate"] = Date().timeIntervalSince1970
        
        // JSONデータに変換
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            
            // 一時ファイルを作成
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "MuscleMemo_Export_\(Date().timeIntervalSince1970).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("エクスポートファイル作成エラー: \(error)")
            return nil
        }
    }
}
