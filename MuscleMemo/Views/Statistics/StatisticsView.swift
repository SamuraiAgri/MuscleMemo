// ファイル: Views/Statistics/StatisticsView.swift

import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var selectedExercise: Exercise?
    @State private var isSelectingExercise = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // 種目選択
                        ExerciseSelectionCard(
                            selectedExercise: selectedExercise?.name ?? "種目を選択",
                            onTap: {
                                isSelectingExercise = true
                            }
                        )
                        
                        if let exercise = selectedExercise {
                            // 統計パネル
                            StatsPanel(
                                lastWeight: viewModel.getLastWeightForExercise(exercise),
                                maxWeight: viewModel.getMaxWeightForExercise(exercise),
                                averageWeight: viewModel.getAverageWeightForExercise(exercise)
                            )
                            
                            // 重量推移グラフ
                            ZStack {
                                WeightProgressChart(
                                    exercise: exercise,
                                    chartData: viewModel.getChartDataForExercise(exercise),
                                    selectedPeriod: $viewModel.selectedPeriod
                                )
                                
                                if viewModel.isLoadingChartData {
                                    LoadingView()
                                }
                            }
                        } else {
                            // 種目未選択時のプレースホルダー
                            WeightProgressPlaceholder()
                        }
                        
                        // 月間トレーニング頻度
                        TrainingFrequencyCard(frequency: viewModel.monthlyTrainingDays)
                    }
                    .padding()
                }
                .background(Color.lightGray.ignoresSafeArea())
                
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
            .navigationTitle("統計")
            .sheet(isPresented: $isSelectingExercise) {
                ExercisePickerView(
                    selectedExercise: $selectedExercise,
                    exercises: viewModel.exercises
                )
            }
            .onAppear {
                viewModel.loadExercises()
                viewModel.calculateMonthlyTrainingFrequency()
                
                // 初期選択種目（過去にトレーニングした種目があれば自動選択）
                if selectedExercise == nil && !viewModel.exercises.isEmpty {
                    selectedExercise = viewModel.exercises.first
                    
                    if let exercise = selectedExercise {
                        viewModel.loadChartData(for: exercise)
                    }
                }
            }
            .onChange(of: selectedExercise) { _, newValue in
                if let exercise = newValue {
                    viewModel.loadChartData(for: exercise)
                }
            }
            .onChange(of: viewModel.selectedPeriod) { _, _ in
                if let exercise = selectedExercise {
                    viewModel.loadChartData(for: exercise)
                }
            }
        }
    }
}

struct ExerciseSelectionCard: View {
    let selectedExercise: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(selectedExercise)
                    .font(.headline)
                    .foregroundColor(Color.darkGray)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .foregroundColor(Color.primaryRed)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct StatsPanel: View {
    let lastWeight: Double
    let maxWeight: Double
    let averageWeight: Double
    
    var body: some View {
        HStack {
            StatBox(title: "前回", value: "\(Int(lastWeight))kg", icon: "clock")
            
            Divider()
                .frame(height: 40)
            
            StatBox(title: "最高", value: "\(Int(maxWeight))kg", icon: "arrow.up")
            
            Divider()
                .frame(height: 40)
            
            StatBox(title: "平均", value: "\(Int(averageWeight))kg", icon: "chart.bar")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.primaryRed)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.darkGray)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.darkGray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeightProgressPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("重量推移")
                .font(.headline)
                .foregroundColor(Color.darkGray)
            
            Text("統計を表示するには種目を選択してください")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 60)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct TrainingFrequencyCard: View {
    let frequency: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今月のトレーニング日数")
                .font(.headline)
                .foregroundColor(Color.darkGray)
            
            HStack(alignment: .bottom) {
                Text("\(frequency)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.primaryRed)
                
                let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
                Text("/ \(daysInMonth) 日")
                    .font(.subheadline)
                    .foregroundColor(Color.darkGray)
                    .padding(.bottom, 10)
            }
            
            // 簡易的な進捗バー
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 6)
                        .foregroundColor(Color.lightGray)
                        .cornerRadius(3)
                    
                    let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
                    Rectangle()
                        .frame(width: min(CGFloat(frequency) / CGFloat(daysInMonth) * geometry.size.width, geometry.size.width), height: 6)
                        .foregroundColor(Color.primaryRed)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ExercisePickerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedExercise: Exercise?
    let exercises: [Exercise]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(exercises, id: \.id) { exercise in
                    Button(action: {
                        selectedExercise = exercise
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(exercise.name ?? "")
                            
                            Spacer()
                            
                            if selectedExercise?.id == exercise.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.primaryRed)
                            }
                        }
                    }
                    .foregroundColor(Color.darkGray)
                }
            }
            .navigationTitle("種目を選択")
            .navigationBarItems(
                trailing: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
