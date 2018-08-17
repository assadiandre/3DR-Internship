//
//  OrthoPlacer.swift
//  OrthoMap
//
//  Created by Andre on 7/13/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Mapbox
import SwiftUtilities

class OrthoPlacer {
    
    static let EARTH_RADIUS_KM: Double = 6371.0
    
    // Code ported from SS Manager PDFOverlay.js
    static public func calcImageCoordinates(map: MGLMapView, geoPoints: [CLLocationCoordinate2D], pixelPoints: [CGPoint], imageSize: CGSize) -> MGLCoordinateQuad {
        let W = imageSize.width;
        let H = imageSize.height;
        
        guard geoPoints.count == 2, pixelPoints.count == 2 else {
            return MGLCoordinateQuad()
        }
        
        // The 2 geo ref lat/lon
        let p1 = geoPoints[0]
        let p2 = geoPoints[1]
        
        // The 2 pdf image pix points
        let p1xy = pixelPoints[0]
        let p2xy = pixelPoints[1]
        
        let d = sqrt(pow((p2xy.x - p1xy.x), 2) + pow((p2xy.y - p1xy.y), 2)) // Pixel distance
        let dActual = p1.distanceTo(p2)/1000.0 // Distance in meters converted to km
        
        let dScale = dActual/Double(d);
        
        let offSetAngle = calcMapAngle(map: map, geoPoints: geoPoints, pixelPoints: pixelPoints)
        
        let b1D = sqrt(pow(p1xy.x, 2) + pow(p1xy.y, 2))
        let b1DActual = Double(b1D) * dScale
        let b1Bearing = -1 * atan2(p1xy.x, p1xy.y)
        let b1Coor = destinationCoordsInRadians(lat1: p1.latitude, lon1: p1.longitude, distanceMeters: b1DActual, bearing: Double(b1Bearing + offSetAngle))
        
        let b2D = sqrt(pow((W - p1xy.x), 2) + pow(p1xy.y, 2)) // Distance in px
        let b2DActual = Double(b2D) * dScale
        let b2Bearing = atan2(W - p1xy.x, p1xy.y)
        let b2Coor = destinationCoordsInRadians(lat1: p1.latitude, lon1: p1.longitude, distanceMeters: b2DActual, bearing: Double(b2Bearing + offSetAngle))
        
        // NOTE: These don't align with trigonometric quadrants. The 3rd point is the bottom left corner of the box. The 4th is the bottom right.
        let b3D = sqrt(pow(p1xy.x, 2) + pow((H - p1xy.y), 2))
        let b3DActual = Double(b3D) * dScale;
        let b3Bearing = CGFloat.pi + atan2(p1xy.x, H - p1xy.y)
        let b3Coor = destinationCoordsInRadians(lat1: p1.latitude, lon1: p1.longitude, distanceMeters: b3DActual, bearing: Double(b3Bearing + offSetAngle))
        
        let b4D = sqrt(pow((W - p1xy.x), 2) + pow((H - p1xy.y), 2))
        let b4DActual = Double(b4D) * dScale;
        let b4Bearing = CGFloat.pi - atan2(W - p1xy.x, H - p1xy.y)
        let b4Coor = destinationCoordsInRadians(lat1: p1.latitude, lon1: p1.longitude, distanceMeters: b4DActual, bearing: Double(b4Bearing + offSetAngle))
        
        let coordinates = MGLCoordinateQuad(
            topLeft: b1Coor,
            bottomLeft: b3Coor,
            bottomRight: b4Coor,
            topRight: b2Coor)
        
        return coordinates
    }
    /*-------------------------------------------------------------------------
     * Given a starting lat/lon point on earth, distance (in meters)
     * and bearing, calculates destination coordinates lat2/lon2.
     *
     * all params in radians
     *-------------------------------------------------------------------------*/
    //-------------------------------------------------------------------------
    // Algorithm from http://www.geomidpoint.com/destination/calculation.html
    // Algorithm also at http://www.movable-type.co.uk/scripts/latlong.html
    //
    // Spherical Earth Model
    //   1. Let radiusEarth = 6372.7976 km
    //   2. Convert distance to the distance in radians.
    //      dist = dist/radiusEarth
    //   3. Calculate the destination coordinates.
    //      lat2 = asin(sin(lat1)*cos(dist) + cos(lat1)*sin(dist)*cos(brg))
    //      lon2 = lon1 + atan2(sin(brg)*sin(dist)*cos(lat1), cos(dist)-sin(lat1)*sin(lat2))
    //-------------------------------------------------------------------------
    static public func destinationCoordsInRadians(lat1: Double, lon1: Double, distanceMeters: Double, bearing: Double) -> CLLocationCoordinate2D {
        let distRadians = distanceMeters / EARTH_RADIUS_KM
        let lat = degreesToRadians(lat1)
        let lon = degreesToRadians(lon1)
        
        let lat2 = asin( sin(lat) * cos(distRadians) + cos(lat) * sin(distRadians) * cos(bearing))
        
        let lon2 = lon + atan2( sin(bearing) * sin(distRadians) * cos(lat), cos(distRadians) - sin(lat) * sin(lat2))
        
        return CLLocationCoordinate2DMake(radiansToDegrees(lat2), radiansToDegrees(lon2))
    }
    // Code ported from SS Manager PDFOverlay.js
    static public func calcMapAngle(map: MGLMapView, geoPoints: [CLLocationCoordinate2D], pixelPoints: [CGPoint]) -> CGFloat {
        guard geoPoints.count == 2, pixelPoints.count == 2 else {
            return 0.0
        }
        
        // The 2 geo ref lat/lon
        let p1 = geoPoints[0]
        let p2 = geoPoints[1]
        
        let p1Proj = map.convert(p1, toPointTo: map)
        let p2Proj = map.convert(p2, toPointTo: map)
        let dx = p2Proj.x - p1Proj.x
        let dy = p2Proj.y - p1Proj.y
        
        // The 2 pdf image pix points
        let t1 = pixelPoints[0]
        let t2 = pixelPoints[1]
        
        let rectHeight = t2.y - t1.y
        let rectWidth = t2.x - t1.x
        
        // Compute rotation angle
        let thetaPDF = atan2(rectHeight, rectWidth)
        let thetaMap = atan2(dy, dx)
        let thetaCamera = CGFloat(degreesToRadians(map.camera.heading))
        let theta = thetaMap - thetaPDF + thetaCamera
        
        return theta;
    }
    
}
