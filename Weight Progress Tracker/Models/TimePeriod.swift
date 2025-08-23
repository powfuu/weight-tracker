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
        let localizationManager = LocalizationManager.shared
        switch self {
        case .week:
            return localizationManager.localizedString(for: LocalizationKeys.sevenDays)
        case .month:
            return localizationManager.localizedString(for: LocalizationKeys.thirtyDays)
        case .quarter:
            return localizationManager.localizedString(for: LocalizationKeys.ninetyDays)
        case .year:
            return localizationManager.localizedString(for: LocalizationKeys.oneYear)
        }
    }
    
    var shortName: String {
        let localizationManager = LocalizationManager.shared
        switch self {
        case .week:
            return localizationManager.localizedString(for: LocalizationKeys.sevenDaysShort)
        case .month:
            return localizationManager.localizedString(for: LocalizationKeys.thirtyDaysShort)
        case .quarter:
            return localizationManager.localizedString(for: LocalizationKeys.ninetyDaysShort)
        case .year:
            return localizationManager.localizedString(for: LocalizationKeys.oneYearShort)
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