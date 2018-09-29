//
//  DataController.swift
//  VirtualTourist
//
//  Created by Victor Matthijs on 10/08/2018.
//  Copyright © 2018 Victor Matthijs. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContrainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContrainer.viewContext
    }
    
    init(modelName:String) {
        persistentContrainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil){
        persistentContrainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
