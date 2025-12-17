// ファイル: Views/Common/Components/WorkoutSetRow.swift

import SwiftUI

struct WorkoutSetRow: View {
    let set: WorkoutSet
    var onDelete: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var showDate: Bool = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(set.exercise?.name ?? "")
                        .font(.headline)
                        .foregroundColor(Color.darkGray)
                    
                    if showDate, let date = set.workoutLog?.date {
                        Text("(\(dateFormatter.string(from: date)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("\(Int(set.weight))kg × \(set.reps)回")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.primaryRed)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.primaryRed)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?()
        }
    }
}
