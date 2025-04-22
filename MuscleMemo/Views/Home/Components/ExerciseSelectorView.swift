// ファイル: Views/Home/Components/ExerciseSelectorView.swift

import SwiftUI
import CoreData
import Combine

struct ExerciseSelectorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @State private var searchText = ""
    @State private var showingAddExercise = false
    @State private var exercises: [Exercise] = []
    
    let onExerciseSelected: (Exercise) -> Void
    let coreDataManager = CoreDataManager.shared
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var body: some View {
        VStack {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("種目を検索", text: $searchText)
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.lightGray)
            .cornerRadius(10)
            .padding(.horizontal)
            
            // 種目リスト
            List {
                ForEach(filteredExercises, id: \.id) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        onToggleFavorite: {
                            toggleFavorite(exercise: exercise)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onExerciseSelected(exercise)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("トレーニング種目")
        .navigationBarItems(
            leading: Button("キャンセル") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Button(action: {
                showingAddExercise = true
            }) {
                Image(systemName: "plus")
            }
        )
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(onSave: { name in
                addExercise(name: name)
            })
        }
        .onAppear {
            loadExercises()
        }
    }
    
    private func loadExercises() {
        exercises = coreDataManager.getAllExercises()
    }
    
    private func toggleFavorite(exercise: Exercise) {
        // お気に入り状態を切り替え、即時に保存
        exercise.isFavorite.toggle()
        coreDataManager.saveContext()
        
        // リストを更新 - 変更後に再取得することで状態を同期
        DispatchQueue.main.async {
            // 少し遅延させて状態の更新を安定させる
            self.loadExercises()
        }
        
        // 通知を発行して他のビューに状態変更を伝える
        // ここでは遅延実行して画面が白くならないようにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: .favoriteExerciseToggled,
                object: exercise.id
            )
        }
    }
    
    private func addExercise(name: String) {
        let newExercise = Exercise(context: viewContext)
        newExercise.id = UUID()
        newExercise.name = name
        newExercise.isDefault = false
        newExercise.isFavorite = false
        
        coreDataManager.saveContext()
        loadExercises()
    }
}

struct ExerciseRow: View {
    @ObservedObject var exercise: Exercise
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            Text(exercise.name ?? "")
                .font(.body)
            
            Spacer()
            
            Button(action: onToggleFavorite) {
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 22))
                    .foregroundColor(exercise.isFavorite ? .accentOrange : .gray)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

// その他のコードは変更なし
struct AddExerciseView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var exerciseName = ""
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("種目名")) {
                    TextField("新しい種目名を入力", text: $exerciseName)
                }
            }
            .navigationTitle("種目を追加")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    guard !exerciseName.isEmpty else { return }
                    onSave(exerciseName)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(exerciseName.isEmpty)
            )
        }
    }
}

struct ExerciseSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExerciseSelectorView(onExerciseSelected: { _ in })
                .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
        }
    }
}

// 通知名の拡張
extension Notification.Name {
    static let favoriteExerciseToggled = Notification.Name("favoriteExerciseToggled")
}
