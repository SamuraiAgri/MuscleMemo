// ファイル: Models/Managers/WorkoutManager.swift

import Foundation
import CoreData

class WorkoutManager {
    private let coreDataManager = CoreDataManager.shared
    
    // 特定の期間のトレーニング頻度を取得
    func getTrainingFrequency(startDate: Date, endDate: Date) -> Int {
        let trainingDates = getTrainingDates(startDate: startDate, endDate: endDate)
        return trainingDates.count
    }
    
    // 特定の期間内のトレーニング日を取得
    func getTrainingDates(startDate: Date, endDate: Date) -> [Date] {
        let fetchRequest: NSFetchRequest<WorkoutLog> = WorkoutLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let logs = try coreDataManager.viewContext.fetch(fetchRequest)
            return logs.compactMap { $0.date }
        } catch {
            print("トレーニング日の取得に失敗: \(error)")
            return []
        }
    }
    
    // 特定の期間の総重量を計算
    func getTotalWeight(startDate: Date, endDate: Date) -> Double {
        let fetchRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutLog.date >= %@ AND workoutLog.date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let sets = try coreDataManager.viewContext.fetch(fetchRequest)
            return sets.reduce(0) { $0 + $1.weight }
        } catch {
            print("総重量の計算に失敗: \(error)")
            return 0
        }
    }
    
    // 特定の期間の総レップ数を計算
    func getTotalReps(startDate: Date, endDate: Date) -> Int {
        let fetchRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutLog.date >= %@ AND workoutLog.date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let sets = try coreDataManager.viewContext.fetch(fetchRequest)
            return sets.reduce(0) { $0 + Int($1.reps) }
        } catch {
            print("総レップ数の計算に失敗: \(error)")
            return 0
        }
    }
    
    // 種目ごとのトレーニング回数を取得
    func getExerciseFrequency(startDate: Date, endDate: Date) -> [UUID: Int] {
        let fetchRequest: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutLog.date >= %@ AND workoutLog.date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let sets = try coreDataManager.viewContext.fetch(fetchRequest)
            var frequency: [UUID: Int] = [:]
            
            for set in sets {
                if let exerciseId = set.exercise?.id {
                    frequency[exerciseId, default: 0] += 1
                }
            }
            
            return frequency
        } catch {
            print("種目頻度の取得に失敗: \(error)")
            return [:]
        }
    }
    
    // 最も頻繁に行われている種目を取得
    func getMostFrequentExercises(startDate: Date, endDate: Date, limit: Int = 5) -> [Exercise] {
        let frequency = getExerciseFrequency(startDate: startDate, endDate: endDate)
        
        let sortedIds = frequency.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
        
        var exercises: [Exercise] = []
        
        for id in sortedIds {
            let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let results = try coreDataManager.viewContext.fetch(fetchRequest)
                if let exercise = results.first {
                    exercises.append(exercise)
                }
            } catch {
                print("種目の取得に失敗: \(error)")
            }
        }
        
        return exercises
    }
}
