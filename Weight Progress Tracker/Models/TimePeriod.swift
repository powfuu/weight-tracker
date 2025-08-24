//
//  TimePeriod.swift
//  Weight Progress Tracker
//
//  Created by Everit Jhon Molero on 16/8/25.
//

import Foundation

enum TimePeriod: String, CaseIterable {
    case threeDays = "three_days"
    case week = "week"
    case fifteenDays = "fifteen_days"
    case month = "month"
    case threeMonths = "three_months"
    case sixMonths = "six_months"
    case year = "year"
    
    func displayName(using localizationManager: LocalizationManager) -> String {
        switch self {
        case .threeDays:
            return localizationManager.localizedString(for: LocalizationKeys.threeDays)
        case .week:
            return localizationManager.localizedString(for: LocalizationKeys.sevenDays)
        case .fifteenDays:
            return localizationManager.localizedString(for: LocalizationKeys.fifteenDays)
        case .month:
            return localizationManager.localizedString(for: LocalizationKeys.thirtyDays)
        case .threeMonths:
            return localizationManager.localizedString(for: LocalizationKeys.threeMonths)
        case .sixMonths:
            return localizationManager.localizedString(for: LocalizationKeys.sixMonths)
        case .year:
            return localizationManager.localizedString(for: LocalizationKeys.oneYear)
        }
    }
    
    func shortName(using localizationManager: LocalizationManager) -> String {
        switch self {
        case .threeDays:
            return localizationManager.localizedString(for: LocalizationKeys.threeDaysShort)
        case .week:
            return localizationManager.localizedString(for: LocalizationKeys.sevenDaysShort)
        case .fifteenDays:
            return localizationManager.localizedString(for: LocalizationKeys.fifteenDaysShort)
        case .month:
            return localizationManager.localizedString(for: LocalizationKeys.thirtyDaysShort)
        case .threeMonths:
            return localizationManager.localizedString(for: LocalizationKeys.threeMonthsShort)
        case .sixMonths:
            return localizationManager.localizedString(for: LocalizationKeys.sixMonthsShort)
        case .year:
            return localizationManager.localizedString(for: LocalizationKeys.oneYearShort)
        }
    }
    
    var days: Int {
        switch self {
        case .threeDays:
            return 3
        case .week:
            return 7
        case .fifteenDays:
            return 15
        case .month:
            return 30
        case .threeMonths:
            return 90
        case .sixMonths:
            return 180
        case .year:
            return 365
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .threeDays:
            return calendar.date(byAdding: .day, value: -3, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .fifteenDays:
            return calendar.date(byAdding: .day, value: -15, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    func dateRange() -> (start: Date, end: Date) {
        return (start: startDate, end: Date())
    }
}