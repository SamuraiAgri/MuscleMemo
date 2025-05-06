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
    @State private var isLoading = false
    
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
        ZStack {
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
                isLoading = true
                loadExercises()
            }
            
            if isLoading {
                LoadingView()
            }
        }
    }
    
    private func loadExercises() {
        DispatchQueue.global(qos: .userInitiated).async {
            let allExercises = coreDataManager.getAllExercises()
            
            DispatchQueue.main.async {
                exercises = allExercises
                isLoading = false
            }
        }
    }
    
    private func toggleFavorite(exercise: Exercise) {
        // お気に入り状態を切り替え、即時に保存
        exercise.isFavorite.toggle()
        coreDataManager.saveContext()
        
        // UIを更新 - Exerciseが ObservedObject なので自動更新される
        
        // 通知を発行して他のビューに状態変更を伝える
        NotificationCenter.default.post(
            name: .favoriteExerciseToggled,
            object: exercise.id
        )
    }
    
    private func addExercise(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
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

struct AddExerciseView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var exerciseName = ""
    @FocusState private var isTextFieldFocused: Bool
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("種目名")) {
                    TextField("新しい種目名を入力", text: $exerciseName)
                        .focused($isTextFieldFocused)
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
                .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .onAppear {
                // キーボードを自動的に表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

// 通知名の拡張
extension Notification.Name {
    static let favoriteExerciseToggled = Notification.Name("favoriteExerciseToggled")
}
