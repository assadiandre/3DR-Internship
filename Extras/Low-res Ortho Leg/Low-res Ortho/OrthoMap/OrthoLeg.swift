//
//  Leg.swift
//  Low-res Ortho
//
//  Created by Andre on 7/10/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation
import MapKit

class Leg {
    let index: Int
    var images: [OrthoImage]
    var hasDirection: Bool { return images.count > 1 }
    
    init(index: Int, images: [OrthoImage]){
        self.index = index
        self.images = images
    }
    
    func addImage(image: OrthoImage) {
        images.append(image)
    }
    
    func isPointInLeg(location: CLLocationCoordinate2D) -> Bool {
        guard hasDirection else {
            // Leg doesn't have a direction (only one point), then let's assume that the next point is part of the leg
            return true
        }
        
        let startMapPoint = MKMapPointForCoordinate(images.first!.location!)
        let endMapPoint = MKMapPointForCoordinate(images.last!.location!)
        let preEndMapPoint = MKMapPointForCoordinate(images[images.count - 2].location!)
        let locationMapPoint = MKMapPointForCoordinate(location)
        
        let start_end_Vector = (x: (endMapPoint.x - startMapPoint.x), y:(endMapPoint.y - startMapPoint.y))
        let prevEnd_end_Vector = (x: (endMapPoint.x - preEndMapPoint.x), y:(endMapPoint.y - preEndMapPoint.y))
        let end_location_Vector = (x: (locationMapPoint.x - endMapPoint.x), y:(locationMapPoint.y - endMapPoint.y))
        
        let lengthOf_start_end_Vector = sqrt(start_end_Vector.x * start_end_Vector.x + start_end_Vector.y * start_end_Vector.y)
        let crossProduct = start_end_Vector.x * end_location_Vector.y - start_end_Vector.y * end_location_Vector.x
        
        let distanceFromLocationToLeg = abs(crossProduct)/lengthOf_start_end_Vector
        
        let lengthOf_prevEnd_end_Vector = sqrt(prevEnd_end_Vector.x * prevEnd_end_Vector.x + prevEnd_end_Vector.y * prevEnd_end_Vector.y)
        let tresholdToBeInLeg = lengthOf_prevEnd_end_Vector / 1
        return distanceFromLocationToLeg < tresholdToBeInLeg
    }
}


