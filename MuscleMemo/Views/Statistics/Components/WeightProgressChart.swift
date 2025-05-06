// ファイル: Views/Statistics/Components/WeightProgressChart.swift

import SwiftUI
import Charts

struct WeightProgressChart: View {
    let exercise: Exercise
    let chartData: [WeightChartEntry]
    @Binding var selectedPeriod: StatisticsPeriod
    
    // チャートデータが空かどうかチェック
    private var hasData: Bool {
        return !chartData.isEmpty
    }
    
    // 最高記録エントリーを取得
    private var maxEntry: WeightChartEntry? {
        return chartData.max(by: { $0.weight < $1.weight })
    }
    
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
            
            if !hasData {
                Text("データがありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 60)
            } else {
                Chart {
                    ForEach(chartData) { entry in
                        LineMark(
                            x: .value("日付", entry.date),
                            y: .value("重量", entry.weight)
                        )
                        .foregroundStyle(Color.primaryRed)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("日付", entry.date),
                            y: .value("重量", entry.weight)
                        )
                        .foregroundStyle(Color.primaryRed)
                    }
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
                .chartYScale(domain: yAxisDomain)
            }
            
            // 最高記録と日付
            if let maxEntry = maxEntry {
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
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    // Y軸のスケールを調整（データの最小値から最大値までを少し余裕を持たせて表示）
    private var yAxisDomain: ClosedRange<Double> {
        if chartData.isEmpty {
            return 0...100
        }
        
        let minWeight = chartData.map { $0.weight }.min() ?? 0
        let maxWeight = chartData.map { $0.weight }.max() ?? 100
        
        // 上下に少し余裕を持たせる（最低でも10kgの範囲）
        let padding = max(5.0, (maxWeight - minWeight) * 0.1)
        return max(0, minWeight - padding)...maxWeight + padding
    }
}
