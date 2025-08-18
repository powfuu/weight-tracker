//
//  UserSettings+CoreDataProperties.swift
//  
//
//  Created by Everit Jhon Molero on 16/8/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension UserSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var preferredUnit: String?
    @NSManaged public var targetWeight: Double
    @NSManaged public var healthKitEnabled: Bool
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var reminderTime: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension UserSettings : Identifiable {

}
