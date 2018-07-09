//
//  LocationData+CoreDataProperties.swift
//  Solar Cal
//
//  Created by Laxman Pandey on 09/07/18.
//  Copyright © 2018 Laxman Pandey. All rights reserved.
//
//

import Foundation
import CoreData


extension LocationData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationData> {
        return NSFetchRequest<LocationData>(entityName: "LocationData")
    }

    @NSManaged public var lat: Double
    @NSManaged public var long: Double
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var timezone: String?
    @NSManaged public var sunRiseDate: NSDate?
    @NSManaged public var sunSetDate: NSDate?

}
