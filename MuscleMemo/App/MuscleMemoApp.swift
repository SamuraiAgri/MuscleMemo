// ファイル: App/MuscleMemoApp.swift

import SwiftUI

@main
struct MuscleMemoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let persistenceController = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
        // iOS 17で非推奨のメソッドを最新の形式に更新
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                persistenceController.saveContext()
            }
        }
    }
}
