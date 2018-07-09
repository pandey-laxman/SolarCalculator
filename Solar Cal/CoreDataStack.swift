//
//  CoreDataStack.swift
//  Solar Cal
//
//  Created by Laxman Pandey on 09/07/18.
//  Copyright © 2018 Laxman Pandey. All rights reserved.
//

import UIKit
import CoreData
final class CoreDataStack: NSObject {
    static let sharedInstance = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "Solar_Cal")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
     lazy var managedContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    private override init() {
        
    }
    
    func saveContext () -> Bool {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        return false
    }
    
    func fetchLocationData() -> [LocationData]? {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationData")
        request.returnsObjectsAsFaults = false
        do {
            let result = try managedContext.fetch(request)
            return result as? [LocationData]
            
        } catch {
            
            print("Failed")
        }
        return nil
    }
}

