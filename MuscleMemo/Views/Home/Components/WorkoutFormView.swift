// ファイル: Views/Home/Components/WorkoutFormView.swift

import SwiftUI

struct WorkoutFormView: View {
    @Environment(\.presentationMode) private var presentationMode
    let exercise: Exercise
    let lastWorkoutSet: WorkoutSet?
    let onSave: (Double, Int) -> Void
    
    @State private var weight: Double = 0
    @State private var reps: Int = 1
    @State private var weightString: String = "0"
    @State private var repsString: String = "1"
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("種目情報")) {
                    Text(exercise.name ?? "")
                        .font(.headline)
                }
                
                if let lastSet = lastWorkoutSet {
                    Section(header: Text("前回の記録")) {
                        HStack {
                            Text("重量")
                            Spacer()
                            Text("\(Int(lastSet.weight))kg")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("回数")
                            Spacer()
                            Text("\(lastSet.reps)回")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("今回の記録")) {
                    // 重量入力
                    HStack {
                        Text("重量 (kg)")
                        Spacer()
                        
                        Button {
                            adjustWeight(-2.5)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color.primaryRed)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        TextField("0", text: $weightString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(.horizontal, 8)
                            .focused($focusedField, equals: .weight)
                            .onChange(of: weightString) { _, newValue in
                                if let newWeight = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                    weight = newWeight
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button {
                            adjustWeight(2.5)
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
                            adjustReps(-1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color.primaryRed)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        TextField("1", text: $repsString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding(.horizontal, 8)
                            .focused($focusedField, equals: .reps)
                            .onChange(of: repsString) { _, newValue in
                                if let newReps = Int(newValue) {
                                    reps = newReps
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button {
                            adjustReps(1)
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
                    .sensoryFeedback(.impact(flexibility: .rigid), trigger: isFormValid)
                }
            }
            .navigationTitle("\(exercise.name ?? "") を記録")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("完了") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                // 前回の記録があれば初期値として設定
                if let lastSet = lastWorkoutSet {
                    weight = lastSet.weight
                    weightString = String(format: "%.1f", lastSet.weight)
                    reps = Int(lastSet.reps)
                    repsString = "\(lastSet.reps)"
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return weight > 0 && reps > 0
    }
    
    // 重量調整ヘルパーメソッド（小数点以下の丸めも実施）
    private func adjustWeight(_ delta: Double) {
        let newWeight = max(0, weight + delta)
        // 小数第一位まで丸める
        weight = (round(newWeight * 10) / 10).rounded(toPlaces: 1)
        weightString = String(format: "%.1f", weight)
    }
    
    // 回数調整ヘルパーメソッド
    private func adjustReps(_ delta: Int) {
        let newReps = max(1, reps + delta)
        reps = newReps
        repsString = "\(newReps)"
    }
    
    private func saveWorkout() {
        onSave(weight, reps)
        presentationMode.wrappedValue.dismiss()
    }
}

// Double型の拡張（小数点以下の丸め処理を追加）
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
