// ファイル: Views/Statistics/Components/WeightProgressChart.swift

import SwiftUI
import Charts

struct WeightProgressChart: View {
    let exercise: Exercise
    let chartData: [WeightChartEntry]
    @Binding var selectedPeriod: StatisticsPeriod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(exercise.name ?? "") の重量推移")
                    .font(.headline)
                    .foregroundColor(Color.darkGray)
                
                Spacer()
                
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .fixedSize()
                .scaleEffect(0.9)
            }
            
            if chartData.isEmpty {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 60)
            } else {
                Chart(chartData) { entry in
                    LineMark(
                        x: .value("日付", entry.date),
                        y: .value("重量", entry.weight)
                    )
                    .foregroundStyle(Color.primaryRed)
                    
                    PointMark(
                        x: .value("日付", entry.date),
                        y: .value("重量", entry.weight)
                    )
                    .foregroundStyle(Color.primaryRed)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(dateFormatter.string(from: date))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight))kg")
                            }
                        }
                    }
                }
            }
            
            // 最高記録と日付
            if let maxEntry = chartData.max(by: { $0.weight < $1.weight }) {
                HStack {
                    Text("最高記録:")
                        .font(.subheadline)
                        .foregroundColor(Color.darkGray)
                    
                    Text("\(Int(maxEntry.weight))kg")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryRed)
                    
                    Text("(\(dateFormatter.string(from: maxEntry.date)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }
}

struct WeightProgressChart_Previews: PreviewProvider {
    static var previews: some View {
        let context = PreviewHelper.createPreviewContext()
        let exercise = (context.registeredObjects.first { $0 is Exercise }) as! Exercise
        
        let today = Date()
        let calendar = Calendar.current
        
        // サンプルデータ作成
        var sampleData: [WeightChartEntry] = []
        for i in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: -i * 3, to: today) {
                let entry = WeightChartEntry(
                    date: date,
                    weight: Double(60 + i)
                )
                sampleData.append(entry)
            }
        }
        
        return VStack {
            // データあり
            WeightProgressChart(
                exercise: exercise,
                chartData: sampleData,
                selectedPeriod: .constant(.month)
            )
            .padding()
            
            // データなし
            WeightProgressChart(
                exercise: exercise,
                chartData: [],
                selectedPeriod: .constant(.month)
            )
            .padding()
        }
        .background(Color.lightGray)
        .previewLayout(.sizeThatFits)
    }
}
