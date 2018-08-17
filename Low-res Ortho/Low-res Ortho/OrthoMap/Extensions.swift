//
//  Extensions.swift
//  Low-res Ortho
//
//  Created by Andre on 7/5/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

extension CLLocationCoordinate2D {
    func distanceTo(_ other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return to.distance(from: from)
    }
}


