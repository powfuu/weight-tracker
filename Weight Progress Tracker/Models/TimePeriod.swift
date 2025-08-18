//
//  TimePeriod.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import Foundation

enum TimePeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week:
            return "7 días"
        case .month:
            return "30 días"
        case .quarter:
            return "90 días"
        case .year:
            return "1 año"
        }
    }
    
    var shortName: String {
        switch self {
        case .week:
            return "7D"
        case .month:
            return "30D"
        case .quarter:
            return "90D"
        case .year:
            return "1A"
        }
    }
    
    var days: Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .quarter:
            return 90
        case .year:
            return 365
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .day, value: -90, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    func dateRange() -> (start: Date, end: Date) {
        return (start: startDate, end: Date())
    }
}