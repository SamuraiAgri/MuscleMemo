// ファイル: Views/Home/HomeView.swift

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingExerciseSelector = false
    @State private var showingWorkoutForm = false
    @State private var selectedExercise: Exercise?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 今日のトレーニング概要
                        WorkoutSummaryCard(workoutSets: viewModel.todaysWorkoutSets)
                        
                        // お気に入り種目リスト
                        FavoriteExerciseList(
                            exercises: viewModel.favoriteExercises,
                            onExerciseSelected: { exercise in
                                selectedExercise = exercise
                                showingWorkoutForm = true
                            }
                        )
                        
                        Spacer(minLength: 80)
                    }
                    .padding()
                }
                
                VStack {
                    Spacer()
                    
                    // 記録追加ボタン
                    Button(action: {
                        showingExerciseSelector = true
                    }) {
                        Text("トレーニングを記録")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryRed)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .background(
                        Color.lightGray
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
            }
            .navigationTitle("今日のトレーニング")
            .sheet(isPresented: $showingExerciseSelector) {
                NavigationView {
                    ExerciseSelectorView(onExerciseSelected: { exercise in
                        selectedExercise = exercise
                        showingExerciseSelector = false
                        showingWorkoutForm = true
                    })
                }
            }
            .sheet(isPresented: $showingWorkoutForm, onDismiss: {
                selectedExercise = nil
                viewModel.refreshTodaysWorkouts()
            }) {
                if let exercise = selectedExercise {
                    WorkoutFormView(
                        exercise: exercise,
                        lastWorkoutSet: viewModel.getLastWorkoutSet(for: exercise),
                        onSave: { weight, reps in
                            viewModel.addWorkoutSet(exercise: exercise, weight: weight, reps: reps)
                            showingWorkoutForm = false
                        }
                    )
                }
            }
            .onAppear {
                // 表示時にデータを更新
                viewModel.refreshTodaysWorkouts()
                viewModel.loadFavoriteExercises()
            }
        }
    }
}

struct WorkoutSummaryCard: View {
    let workoutSets: [WorkoutSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本日の記録")
                .font(.headline)
                .foregroundColor(Color.darkGray)
            
            if workoutSets.isEmpty {
                Text("まだトレーニング記録がありません")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(workoutSets, id: \.id) { set in
                    HStack {
                        Text(set.exercise?.name ?? "未知の種目")
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(set.weight))kg × \(set.reps)回")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if set != workoutSets.last {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FavoriteExerciseList: View {
    let exercises: [Exercise]
    let onExerciseSelected: (Exercise) -> Void
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("お気に入り種目")
                    .font(.headline)
                    .foregroundColor(Color.darkGray)
                
                Spacer()
                
                if !exercises.isEmpty {
                    Text("\(exercises.count)種目")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if exercises.isEmpty {
                HStack {
                    Text("お気に入り種目が登録されていません")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("⭐️を押すとお気に入りに登録できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
            } else {
                // より安定したレイアウト - ZStackを使用してローディング表示を重ねる
                ZStack {
                    // グリッドレイアウト
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(exercises, id: \.id) { exercise in
                            Button(action: {
                                onExerciseSelected(exercise)
                            }) {
                                HStack {
                                    Text(exercise.name ?? "")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.primaryRed)
                                .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .id(exercise.id)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            // 画面表示時に更新
            withAnimation {
                isRefreshing = true
            }
            
            // 少し遅延させて確実に更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isRefreshing = false
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
    }
}
