// ファイル: Views/Calendar/Components/CalendarWorkoutFormView.swift

import SwiftUI

struct CalendarWorkoutFormView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = CalendarViewModel()
    
    let exercise: Exercise
    let date: Date
    let onSave: (Double, Int) -> Void
    
    @State private var weight: Double = 0
    @State private var reps: Int = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("種目情報")) {
                    Text(exercise.name ?? "")
                        .font(.headline)
                    
                    Text(dateFormatted)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("トレーニング記録")) {
                    // 重量入力
                    HStack {
                        Text("重量 (kg)")
                        Spacer()
                        
                        Button {
                            if weight > 0 {
                                weight = max(0, weight - 2.5)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color.primaryRed)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        TextField("0", value: $weight, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(.horizontal, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button {
                            weight += 2.5
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color.primaryRed)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 8)
                    
                    // 回数入力
                    HStack {
                        Text("回数")
                        Spacer()
                        
                        Button {
                            if reps > 1 {
                                reps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color.primaryRed)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        TextField("1", value: $reps, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(.horizontal, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button {
                            reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color.primaryRed)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: saveWorkout) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(isFormValid ? Color.primaryRed : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("\(exercise.name ?? "") を記録")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                // 前回の記録を取得して初期値として設定
                if let lastSet = CoreDataManager.shared.getLastWorkoutSet(for: exercise) {
                    weight = lastSet.weight
                    reps = Int(lastSet.reps)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return weight > 0 && reps > 0
    }
    
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func saveWorkout() {
        // WorkoutSetを追加
        viewModel.addWorkoutSet(for: date, exercise: exercise, weight: weight, reps: reps)
        
        // 画面を閉じる
        onSave(weight, reps)
        presentationMode.wrappedValue.dismiss()
    }
}

struct CalendarWorkoutFormView_Previews: PreviewProvider {
    static var previews: some View {
        // プレビュー用のダミーデータ
        let context = PreviewHelper.createPreviewContext()
        let exercise = context.registeredObjects.first { $0 is Exercise } as! Exercise
        
        return CalendarWorkoutFormView(
            exercise: exercise,
            date: Date(),
            onSave: { _, _ in }
        )
    }
}
