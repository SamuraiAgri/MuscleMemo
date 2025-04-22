// ファイル: Views/Common/Components/WorkoutSetRow.swift

import SwiftUI

struct WorkoutSetRow: View {
    let set: WorkoutSet
    var onDelete: (() -> Void)? = nil
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
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(Color.primaryRed)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct WorkoutSetRow_Previews: PreviewProvider {
    static var previews: some View {
        let context = PreviewHelper.createPreviewContext()
        let set = (context.registeredObjects.first { $0 is WorkoutSet }) as! WorkoutSet
        
        return VStack {
            WorkoutSetRow(set: set)
            
            WorkoutSetRow(set: set, onDelete: {})
            
            WorkoutSetRow(set: set, showDate: true)
        }
        .padding()
        .background(Color.lightGray)
    }
}
