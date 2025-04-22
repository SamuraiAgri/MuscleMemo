// ファイル: Models/Extensions/Date+Extension.swift

import Foundation

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: self.startOfMonth())!
    }
    
    func formatAsYearMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    func formatAsShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    func formatAsFullDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: self)
    }
    
    func isSameDay(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: date)
    }
    
    func isSameMonth(as date: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.year, .month], from: self)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return selfComponents.year == dateComponents.year && selfComponents.month == dateComponents.month
    }
}
