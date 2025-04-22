// ファイル: Common/Utilities/PreviewHelper.swift

import SwiftUI
import CoreData

struct PreviewHelper {
    static func createPreviewContext() -> NSManagedObjectContext {
        let context = CoreDataManager.shared.viewContext
        
        // サンプルデータの作成
        let exercise1 = createExercise(context: context, name: "ベンチプレス", isDefault: true, isFavorite: true)
        let exercise2 = createExercise(context: context, name: "スクワット", isDefault: true, isFavorite: true)
        
        let todayLog = createWorkoutLog(context: context, date: Date())
        let yesterdayLog = createWorkoutLog(context: context, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        _ = createWorkoutSet(context: context, log: todayLog, exercise: exercise1, weight: 60.0, reps: 10)
        _ = createWorkoutSet(context: context, log: todayLog, exercise: exercise2, weight: 80.0, reps: 8)
        _ = createWorkoutSet(context: context, log: yesterdayLog, exercise: exercise1, weight: 55.0, reps: 12)
        
        return context
    }
    
    static private func createExercise(context: NSManagedObjectContext, name: String, isDefault: Bool, isFavorite: Bool) -> Exercise {
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.isDefault = isDefault
        exercise.isFavorite = isFavorite
        return exercise
    }
    
    static private func createWorkoutLog(context: NSManagedObjectContext, date: Date) -> WorkoutLog {
        let log = WorkoutLog(context: context)
        log.id = UUID()
        log.date = date
        return log
    }
    
    static private func createWorkoutSet(context: NSManagedObjectContext, log: WorkoutLog, exercise: Exercise, weight: Double, reps: Int) -> WorkoutSet {
        let set = WorkoutSet(context: context)
        set.id = UUID()
        set.workoutLog = log
        set.exercise = exercise
        set.weight = weight
        set.reps = Int16(reps)
        return set
    }
}
