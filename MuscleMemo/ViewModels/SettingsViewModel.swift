// ファイル: ViewModels/SettingsViewModel.swift

import SwiftUI
import CoreData

class SettingsViewModel: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    func exportData() {
        // 実際のアプリではファイル共有やクラウドバックアップなどの実装を行う
        // この例ではプレースホルダーとして実装
        print("データのエクスポート処理をここに実装")
    }
    
    func resetAllData() {
        let context = coreDataManager.viewContext
        
        // WorkoutSetを全て削除
        let fetchRequestSets: NSFetchRequest<NSFetchRequestResult> = WorkoutSet.fetchRequest()
        let deleteSets = NSBatchDeleteRequest(fetchRequest: fetchRequestSets)
        
        // WorkoutLogを全て削除
        let fetchRequestLogs: NSFetchRequest<NSFetchRequestResult> = WorkoutLog.fetchRequest()
        let deleteLogs = NSBatchDeleteRequest(fetchRequest: fetchRequestLogs)
        
        // カスタム種目を削除（デフォルト種目は残す）
        let fetchRequestExercises: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        fetchRequestExercises.predicate = NSPredicate(format: "isDefault == %@", NSNumber(value: false))
        
        do {
            try context.execute(deleteSets)
            try context.execute(deleteLogs)
            
            let customExercises = try context.fetch(fetchRequestExercises)
            for exercise in customExercises {
                context.delete(exercise)
            }
            
            coreDataManager.saveContext()
        } catch {
            print("データリセットに失敗: \(error)")
        }
    }
}
