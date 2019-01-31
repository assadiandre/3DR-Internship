//
//  StitchImage.swift
//  Low-res Ortho
//
//  Created by Andre on 7/2/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import MobileCoreServices

class OrthoImage {
    
    var id:Int // Give the ortho image an ID based off its index in the set
    var path:String // The path for the actual image
    var set:Int? // What row or column set the image pertains to
    var location:CLLocationCoordinate2D?
    var referencePoint:CGPoint? // Stores a reference point for the image, where a translation can be applied
    var referenceImage:OrthoImage? // The reference image the reference point is based off of
    var point:CGPoint? // The actual point of the image
    var translation:CGAffineTransform? // Translation that is applied to referencePoint
    var adjustedTranslation:CGAffineTransform? // Adjusted translation that inverts the y translation
    var gpsTranslation:CGAffineTransform?
    var ratio:(xRatio:Double,yRatio:Double)?
    
    init(imagePath:String, id:Int) {
        let imageURL = URL(fileURLWithPath:imagePath)
        self.id = id
        self.path = imagePath
        self.location = locationForImage(imageURL)!
    }
    
    func getTranslation() -> CGAffineTransform {
        return adjustedTranslation!
    }
    
    func getGPSTranslation() -> CGAffineTransform {
        return self.gpsTranslation!
    }
    
    func setReferenceImage(_ image:OrthoImage) {
        self.referenceImage = image
    }
    
    func setID(_ id:Int) {
        self.id = id
    }
    
    func getGPSRatio() -> (xRatio:Double,yRatio:Double) {
        return self.ratio!
    }
    
    func setPoint(_ point:CGPoint) {
        self.point = point
    }
    
    func setTranslatedPoint(_ newPoint:CGPoint) { // Updates point of an image, so that images don't go off frame
        self.point = CGPoint(x:self.point!.x + abs( newPoint.x) ,y: self.point!.y + abs(newPoint.y) )
    }
    
    func setRefPoint(_ point:CGPoint) {
        self.referencePoint = point
    }
    
    func getImage() -> UIImage { /// GET RID OF AFTER
        return UIImage(contentsOfFile: self.path )!
    }
    
    func determineImageTranslation()  { // Uses the ImageTranslator class to find a translation
        if referenceImage != nil {
            let imageTranslator = ImageTranslator(referenceImage: referenceImage!.getImage().cgImage!, floatingImage: self.getImage().cgImage! )
            self.translation = imageTranslator.handleImageTranslationRequest()
            self.adjustedTranslation = self.translation
            self.adjustedTranslation!.ty = self.translation!.inverted().ty
            self.gpsTranslation = self.calculateGPSTranslation()
            self.pointsForImage()
            
            print(self.adjustedTranslation!)
            print()
        }
    }

    
    func calculateCPSCoordinateRatio(gpsXDistance:Double,gpsYDistance:Double) -> (xRatio:Double,yRatio:Double)  {

        var xRatio:Double = 0
        var yRatio:Double = 0
        
        if adjustedTranslation!.tx != 0 {
            xRatio = ( gpsXDistance / Double(  adjustedTranslation!.tx ) )
        }
        if adjustedTranslation!.ty != 0 {
            yRatio = (gpsYDistance / Double(  adjustedTranslation!.ty ))
        }
        return (xRatio:xRatio,yRatio:yRatio)
    }

    func calculateGPSTranslation() -> CGAffineTransform {
        
        let imageMapPoint = MKMapPointForCoordinate(self.location!)
        let otherImageMapPoint = MKMapPointForCoordinate(referenceImage!.location!)
        
        let xDistanceCoord:Double = (imageMapPoint.x - otherImageMapPoint.x )
        let yDistanceCoord:Double = (imageMapPoint.y  -  otherImageMapPoint.y)
        
        
        self.ratio = calculateCPSCoordinateRatio(gpsXDistance: xDistanceCoord, gpsYDistance: yDistanceCoord)

        var gpsxTranslation:CGFloat = 0
        var gpsyTranslation:CGFloat = 0
        
        if self.id <= 1 {
            if self.ratio!.xRatio != 0 {
                gpsxTranslation = CGFloat( xDistanceCoord / self.ratio!.xRatio )
            }
            if self.ratio!.yRatio != 0 {
                gpsyTranslation = CGFloat( yDistanceCoord / self.ratio!.yRatio )
            }
        }
        else  {
            if AverageRatio.xRatio != 0 {
                gpsxTranslation = CGFloat( xDistanceCoord / AverageRatio.xRatio )
            }
            if AverageRatio.yRatio != 0 {
                gpsyTranslation = CGFloat( yDistanceCoord / AverageRatio.yRatio )
            }
        }
    
        let newTranslation = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: gpsxTranslation, ty: gpsyTranslation)
        
        return newTranslation
    }

    
    private func pointsForImage() { // Sets the referencePoint and point properties
        if self.id != 0 && referenceImage?.point != nil {
            self.referencePoint = referenceImage!.point
            let gpsTranslatedPoint = self.referencePoint!.applying( self.getGPSTranslation() )
            let visionTranslatedPoint = self.referencePoint!.applying( self.getTranslation() )
            let xDifference:CGFloat = abs( gpsTranslatedPoint.x - visionTranslatedPoint.x )
            let yDifference:CGFloat = abs( gpsTranslatedPoint.y - visionTranslatedPoint.y )
            
            AverageRatio.xStack += self.ratio!.xRatio
            AverageRatio.yStack += self.ratio!.yRatio

            if xDifference > 30 || yDifference > 30 {
                self.setPoint(gpsTranslatedPoint)
            }
            else {
                let xPoint =  ( gpsTranslatedPoint.x + referencePoint!.applying(adjustedTranslation!).x ) / 2
                let yPoint =  ( gpsTranslatedPoint.y + referencePoint!.applying(adjustedTranslation!).y )  / 2
                self.point = CGPoint(x:xPoint,y:yPoint)
            }
            
            print(self.point!)
        
        }
        else if self.id != 0  {
            print("Points did not work.")
        }
    }
    
    
    private func locationForImage(_ url: URL) -> CLLocationCoordinate2D? { // Returns location of image
        let createOptions: [String: AnyObject] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG as String as String as AnyObject]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, createOptions as CFDictionary?) else {
            print("Unable to determine location for image at \(url). Could not create image source.")
            return nil
        }

        let propertyOptions: [String: AnyObject] = [kCGImageSourceShouldCache as String: NSNumber(value: false as Bool)]
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, propertyOptions as CFDictionary?) as NSDictionary? else {
            print("Unable to determine location for image at \(url). Could not get properties from image.")
            return nil
        }

        guard let gps = properties[kCGImagePropertyGPSDictionary as String] as? NSDictionary,
            let latitudeNumber = gps[kCGImagePropertyGPSLatitude as String] as? NSNumber,
            let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
            let longitudeNumber = gps[kCGImagePropertyGPSLongitude as String] as? NSNumber,
            let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String else {
                print("Unable to determine location for image at \(url). Required properties missing or invalid.")
                return nil
        }
        let latitude = latitudeNumber.doubleValue * (latitudeRef == "N" ? 1 : -1)
        let longitude = longitudeNumber.doubleValue * (longitudeRef == "E" ? 1 : -1)

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // pitch less than 90
    
    
}


