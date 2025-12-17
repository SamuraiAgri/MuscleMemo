// ファイル: Views/Common/Components/EditWorkoutFormView.swift

import SwiftUI

struct EditWorkoutFormView: View {
    @Environment(\.presentationMode) private var presentationMode
    let workoutSet: WorkoutSet
    let onSave: (Double, Int) -> Void
    let onDelete: () -> Void
    
    @State private var weight: Double
    @State private var reps: Int
    @State private var weightString: String
    @State private var repsString: String
    @State private var showingDeleteConfirmation = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    init(workoutSet: WorkoutSet, onSave: @escaping (Double, Int) -> Void, onDelete: @escaping () -> Void) {
        self.workoutSet = workoutSet
        self.onSave = onSave
        self.onDelete = onDelete
        
        // 初期値を設定
        _weight = State(initialValue: workoutSet.weight)
        _reps = State(initialValue: Int(workoutSet.reps))
        _weightString = State(initialValue: String(format: "%.1f", workoutSet.weight))
        _repsString = State(initialValue: "\(workoutSet.reps)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("種目情報")) {
                    Text(workoutSet.exercise?.name ?? "")
                        .font(.headline)
                    
                    if let date = workoutSet.workoutLog?.date {
                        Text(dateFormatted(date))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("トレーニング記録を編集")) {
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
                }
                
                Section {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("この記録を削除")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("記録を編集")
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
            .alert("記録を削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    onDelete()
                    presentationMode.wrappedValue.dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このトレーニング記録を削除しますか？この操作は元に戻せません。")
            }
        }
    }
    
    private var isFormValid: Bool {
        return weight > 0 && reps > 0
    }
    
    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func adjustWeight(_ delta: Double) {
        let newWeight = max(0, weight + delta)
        weight = (round(newWeight * 10) / 10)
        weightString = String(format: "%.1f", weight)
    }
    
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
