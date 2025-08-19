//
//  WeightEntry+CoreDataProperties.swift
//  
//
//  Created by Everit Jhon Molero on 19/8/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WeightEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeightEntry> {
        return NSFetchRequest<WeightEntry>(entityName: "WeightEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var weight: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var unit: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension WeightEntry : Identifiable {

}
