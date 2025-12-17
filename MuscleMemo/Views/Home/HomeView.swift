// ファイル: Views/Home/HomeView.swift

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingExerciseSelector = false
    @State private var showingWorkoutForm = false
    @State private var showingEditForm = false
    @State private var selectedExercise: Exercise?
    @State private var selectedWorkoutSet: WorkoutSet?
    @State private var showingDeleteConfirmation = false
    @State private var workoutSetToDelete: WorkoutSet?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.lightGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 今日のトレーニング概要
                        WorkoutSummaryCard(
                            workoutSets: viewModel.todaysWorkoutSets,
                            onEditSet: { set in
                                selectedWorkoutSet = set
                                showingEditForm = true
                            },
                            onDeleteSet: { set in
                                workoutSetToDelete = set
                                showingDeleteConfirmation = true
                            }
                        )
                        
                        // 休憩タイマー（トレーニング中のみ表示）
                        if !viewModel.todaysWorkoutSets.isEmpty {
                            RestTimerCard()
                        }
                        
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
                .overlay(Group {
                    if viewModel.isLoading {
                        LoadingView()
                    }
                })
                
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
                
                // エラー表示
                if viewModel.showError {
                    VStack {
                        Text(viewModel.errorMessage ?? "エラーが発生しました")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 100)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                viewModel.showError = false
                            }
                        }
                    }
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
            .sheet(isPresented: $showingEditForm, onDismiss: {
                selectedWorkoutSet = nil
                viewModel.refreshTodaysWorkouts()
            }) {
                if let workoutSet = selectedWorkoutSet {
                    EditWorkoutFormView(
                        workoutSet: workoutSet,
                        onSave: { weight, reps in
                            viewModel.updateWorkoutSet(workoutSet, weight: weight, reps: reps)
                        },
                        onDelete: {
                            viewModel.deleteWorkoutSet(workoutSet)
                        }
                    )
                }
            }
            .alert("記録を削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let set = workoutSetToDelete {
                        viewModel.deleteWorkoutSet(set)
                        workoutSetToDelete = nil
                    }
                }
                Button("キャンセル", role: .cancel) {
                    workoutSetToDelete = nil
                }
            } message: {
                Text("このトレーニング記録を削除しますか？")
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
    var onEditSet: ((WorkoutSet) -> Void)? = nil
    var onDeleteSet: ((WorkoutSet) -> Void)? = nil
    
    // 今日のセット数を計算
    private var totalSets: Int {
        return workoutSets.count
    }
    
    // 今日の総重量を計算
    private var totalVolume: Double {
        return workoutSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("本日の記録")
                    .font(.headline)
                    .foregroundColor(Color.darkGray)
                
                Spacer()
                
                if !workoutSets.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(totalSets)セット")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.primaryRed)
                        Text("総重量: \(Int(totalVolume))kg")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if workoutSets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("まだトレーニング記録がありません")
                        .foregroundColor(.secondary)
                    Text("下のボタンからトレーニングを記録しましょう")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(workoutSets, id: \.id) { set in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.exercise?.name ?? "未知の種目")
                                .fontWeight(.medium)
                            Text("\(Int(set.weight))kg × \(set.reps)回")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            if let onEdit = onEditSet {
                                Button(action: { onEdit(set) }) {
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(Color.primaryRed)
                                        .font(.title3)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            
                            if let onDelete = onDeleteSet {
                                Button(action: { onDelete(set) }) {
                                    Image(systemName: "trash.circle")
                                        .foregroundColor(.red.opacity(0.7))
                                        .font(.title3)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
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

// 休憩タイマーカード
struct RestTimerCard: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(Color.primaryRed)
                    
                    Text("休憩タイマー")
                        .font(.headline)
                        .foregroundColor(Color.darkGray)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                RestTimerView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                // より安定したレイアウト - LazyVGridを使用
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(exercises) { exercise in
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
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
