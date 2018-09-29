//
//  OwnAnnotion.swift
//  VirtualTourist
//
//  Created by Victor Matthijs on 12/08/2018.
//  Copyright © 2018 Victor Matthijs. All rights reserved.
//

import Foundation
import MapKit

class OwnAnnotion: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var pin:Pin
    var beenVisited:Bool = false
    
    init(coor:CLLocationCoordinate2D, pin:Pin) {
        self.coordinate = coor
        self.pin = pin
    }
    
    func setBeenVisited(value:Bool){
        self.beenVisited = value
    }
}
