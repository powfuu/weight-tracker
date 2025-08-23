//
//  WeightGoal+CoreDataProperties.swift
//  
//
//  Created by Everit Jhon Molero on 21/8/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WeightGoal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeightGoal> {
        return NSFetchRequest<WeightGoal>(entityName: "WeightGoal")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var targetWeight: Double
    @NSManaged public var targetDate: Date?
    @NSManaged public var startDate: Date?
    @NSManaged public var startWeight: Double
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension WeightGoal : Identifiable {

}
