//
//  IP+CoreDataProperties.swift
//  
//
//  Created by patrick on 2018/4/11.
//
//

import Foundation
import CoreData


extension IP {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<IP> {
        return NSFetchRequest<IP>(entityName: "IP")
    }

    @NSManaged public var ip: String
    @NSManaged public var name: String

}
