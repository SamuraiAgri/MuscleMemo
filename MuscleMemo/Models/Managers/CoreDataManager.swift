// ファイル: Models/Managers/CoreDataManager.swift

import CoreData
import SwiftUI

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {
        // シングルトンパターン
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MuscleMemo")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("CoreDataの永続コンテナ読み込みに失敗: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("保存に失敗: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Exercise管理
    
    func createDefaultExercises() {
        let defaultExercises = AppConstants.defaultExercises
        
        // 既存のデフォルト種目を取得
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDefault == %@", NSNumber(value: true))
        
        do {
            let existingExercises = try viewContext.fetch(fetchRequest)
            let existingNames = existingExercises.map { $0.name ?? "" }
            
            // 新規追加が必要な種目だけを追加
            for exerciseName in defaultExercises {
                if !existingNames.contains(exerciseName) {
                    let newExercise = Exercise(context: viewContext)
                    newExercise.id = UUID()
                    newExercise.name = exerciseName
                    newExercise.isDefault = true
                    newExercise.isFavorite = false
                }
            }
            
            saveContext()
        } catch {
            print("デフォルト種目の作成に失敗: \(error)")
        }
    }
    
    func getAllExercises() -> [Exercise] {
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        
        do {
            let result = try viewContext.fetch(fetchRequest)
            // データベースエラーをデバッグログに出力
            print("取得した種目数: \(result.count)")
            return result
        } catch {
            print("全種目の取得に失敗: \(error)")
            // エラー時は空配列を返す
            return []
        }
    }

    func getFavoriteExercises() -> [Exercise] {
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        
        do {
            let result = try viewContext.fetch(fetchRequest)
            print("取得したお気に入り種目数: \(result.count)")
            return result
        } catch {
            print("お気に入り種目の取得に失敗: \(error)")
            return []
        }
    }
    
    func toggleFavorite(exercise: Exercise) -> Bool {
        exercise.isFavorite.toggle()
        saveContext()
        return exercise.isFavorite
    }
    
    // MARK: - WorkoutLog管理
    
    func getWorkoutLog(for date: Date) -> WorkoutLog? {
        let fetchRequest: NSFetchRequest<WorkoutLog> = WorkoutLog.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let logs = try viewContext.fetch(fetchRequest)
            return logs.first
        } catch {
            print("特定日付のトレーニングログ取得に失敗: \(error)")
            return nil
        }
    }
    
    func createWorkoutLog(for date: Date) -> WorkoutLog {
        let workoutLog = WorkoutLog(context: viewContext)
        workoutLog.id = UUID()
        workoutLog.date = date
        saveContext()
        return workoutLog
    }
    
    func getOrCreateWorkoutLog(for date: Date) -> WorkoutLog {
        if let existingLog = getWorkoutLog(for: date) {
            return existingLog
        } else {
            return createWorkoutLog(for: date)
        }
    }
    
    func getDatesWithWorkouts(in month: Date) -> [Date] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: month)
        let month = calendar.component(.month, from: month)
        
        // 指定された月の最初と最後の日を取得
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let startDate = calendar.date(from: components) else { return [] }
        guard let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { return [] }
        
        let fetchRequest: NSFetchRequest<WorkoutLog> = WorkoutLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let logs = try viewContext.fetch(fetchRequest)
            return logs.compactMap { $0.date }
        } catch {
            print("月間トレーニング日取得に失敗: \(error)")
            return []
        }
    }
    
    // MARK: - WorkoutSet管理
    
    func addWorkoutSet(to log: WorkoutLog, exercise: Exercise, weight: Double, reps: Int) -> WorkoutSet {
        let workoutSet = WorkoutSet(context: viewContext)
        workoutSet.id = UUID()
        workoutSet.exercise = exercise
        workoutSet.workoutLog = log
        workoutSet.weight = weight
        workoutSet.reps = Int16(reps)
        saveContext()
        return workoutSet
    }
    
    func getLastWorkoutSet(for exercise: Exercise) -> WorkoutSet? {
        let fetchRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "exercise == %@", exercise)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSet.workoutLog?.date, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let sets = try viewContext.fetch(fetchRequest)
            return sets.first
        } catch {
            print("最新のワークアウトセット取得に失敗: \(error)")
            return nil
        }
    }
    
    func getWorkoutSets(for exercise: Exercise, between startDate: Date, and endDate: Date) -> [WorkoutSet] {
        let fetchRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        
        // 日付範囲とエクササイズの両方に一致するワークアウトセットを検索
        fetchRequest.predicate = NSPredicate(
            format: "exercise == %@ AND workoutLog.date >= %@ AND workoutLog.date <= %@",
            exercise, startDate as NSDate, endDate as NSDate
        )
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSet.workoutLog?.date, ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("期間内のワークアウトセット取得に失敗: \(error)")
            return []
        }
    }
}
