// ファイル: Views/Calendar/CalendarView.swift

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // カスタムカレンダーヘッダー
                    CalendarHeader(
                        currentMonth: viewModel.currentMonthString,
                        onPreviousMonth: {
                            viewModel.moveMonth(by: -1)
                        },
                        onNextMonth: {
                            viewModel.moveMonth(by: 1)
                        }
                    )
                    
                    // 曜日ヘッダー
                    WeekdayHeader()
                    
                    // カレンダーグリッド
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(viewModel.days, id: \.self) { day in
                            CalendarCell(
                                day: day,
                                isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                                hasWorkout: viewModel.datesWithWorkouts.contains {
                                    Calendar.current.isDate($0, inSameDayAs: day)
                                },
                                isCurrentMonth: viewModel.isDateInCurrentMonth(day)
                            )
                            .onTapGesture {
                                selectedDate = day
                                viewModel.loadWorkouts(for: day)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 選択日のワークアウト表示
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 選択日表示
                            HStack {
                                Text(selectedDateFormatted)
                                    .font(.headline)
                                    .foregroundColor(Color.darkGray)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.showWorkoutForm = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color.primaryRed)
                                        .font(.title2)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            if viewModel.workoutSets.isEmpty {
                                Text("この日のトレーニング記録はありません")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                // ワークアウトリスト
                                ForEach(viewModel.workoutSets, id: \.id) { set in
                                    WorkoutSetRow(set: set, onDelete: {
                                        viewModel.deleteWorkoutSet(set)
                                    })
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .background(Color.lightGray)
                }
                .navigationTitle("カレンダー")
                .navigationBarHidden(true)
                .sheet(isPresented: $viewModel.showWorkoutForm) {
                    ExerciseSelectorForCalendarView(
                        selectedDate: selectedDate,
                        onWorkoutAdded: {
                            viewModel.loadWorkouts(for: selectedDate)
                            viewModel.refreshDatesWithWorkouts()
                        }
                    )
                }
                .onAppear {
                    viewModel.refreshDatesWithWorkouts()
                    viewModel.loadWorkouts(for: selectedDate)
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
        }
    }
    
    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: selectedDate)
    }
}

struct CalendarHeader: View {
    let currentMonth: String
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.primaryRed)
                    .font(.title3)
            }
            
            Spacer()
            
            Text(currentMonth)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.darkGray)
            
            Spacer()
            
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.primaryRed)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(Color.white)
                    }
                }

                struct WeekdayHeader: View {
                    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
                    
                    var body: some View {
                        HStack(spacing: 0) {
                            ForEach(weekdays.indices, id: \.self) { index in
                                Text(weekdays[index])
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(index == 0 ? Color.primaryRed : Color.darkGray)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color.white)
                    }
                }

                struct CalendarCell: View {
                    let day: Date
                    let isSelected: Bool
                    let hasWorkout: Bool
                    let isCurrentMonth: Bool
                    
                    var body: some View {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.primaryRed : Color.clear)
                                .frame(width: 36, height: 36)
                            
                            Text(dayText)
                                .font(.system(size: 16))
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(textColor)
                            
                            // ワークアウト実施済みマーカー
                            if hasWorkout && !isSelected {
                                Circle()
                                    .fill(Color.primaryRed)
                                    .frame(width: 6, height: 6)
                                    .offset(y: 14)
                            }
                        }
                        .frame(height: 44)
                    }
                    
                    private var dayText: String {
                        let component = Calendar.current.component(.day, from: day)
                        return "\(component)"
                    }
                    
                    private var textColor: Color {
                        if isSelected {
                            return .white
                        }
                        
                        if !isCurrentMonth {
                            return Color.gray.opacity(0.5)
                        }
                        
                        let weekday = Calendar.current.component(.weekday, from: day)
                        if weekday == 1 { // 日曜日
                            return Color.primaryRed.opacity(0.8)
                        } else {
                            return Color.darkGray
                        }
                    }
                }

                struct ExerciseSelectorForCalendarView: View {
                    @Environment(\.presentationMode) private var presentationMode
                    @State private var selectedExercise: Exercise?
                    @State private var showingWorkoutForm = false
                    
                    let selectedDate: Date
                    let onWorkoutAdded: () -> Void
                    
                    var body: some View {
                        NavigationView {
                            ExerciseSelectorView(onExerciseSelected: { exercise in
                                selectedExercise = exercise
                                showingWorkoutForm = true
                            })
                        }
                        .sheet(isPresented: $showingWorkoutForm, onDismiss: {
                            presentationMode.wrappedValue.dismiss()
                            onWorkoutAdded()
                        }) {
                            if let exercise = selectedExercise {
                                CalendarWorkoutFormView(
                                    exercise: exercise,
                                    date: selectedDate,
                                    onSave: { _, _ in
                                        showingWorkoutForm = false
                                    }
                                )
                            }
                        }
                    }
                }
