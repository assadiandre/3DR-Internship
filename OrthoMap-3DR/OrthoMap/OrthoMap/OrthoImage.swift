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
import ImageIO

class OrthoImage {
    
    var id:Int /** Give the object an ID based off its index */
    var path:String /** The image path  */
    var location:CLLocationCoordinate2D? /** The GPS Coords */
    var referencePoint:CGPoint? /** Stores a reference point where a translation can be applied*/
    var referenceImage:OrthoImage? /** The reference image the reference point is based off of */ 
    var point:CGPoint? /** The actual point of the image */
    var rawPoint:CGPoint? /** The raw point of the image with no adjustments */
    var visionTranslation:CGAffineTransform? /** Adjusted translation that inverts the y translation */
    var gpsTranslation:CGAffineTransform? /** The GPS translation */
    var ratio:(xRatio:Double,yRatio:Double)? /** The GPS to image coord ratio */
    var rotation:(yaw:Double,pitch:Double,roll:Double)? /** Actual rotation */
    var image:UIImage? /** Stored Image */
    
    init(imagePath:String, id:Int) {
        let imageURL = URL(fileURLWithPath:imagePath)
        self.id = id
        self.path = imagePath
        self.location = locationForImage(imageURL)!
        self.rotation = self.rotationForImage(imageURL)//self.getRotationXMPDataFromImage(filePath:imagePath)
        
        //print(rotation!.yaw)
        
        self.image = UIImage(contentsOfFile: imagePath)!.setBoxOutImage(rotation: rotation!.yaw  )
        
        
    }

    // MARK: - Gets the Vision Translation of the image
    func getTranslation() -> CGAffineTransform {
        return visionTranslation!
    }
    
    // MARK: - Gets the GPS Translation of the image
    func getGPSTranslation() -> CGAffineTransform {
        return self.gpsTranslation!
    }
    
    // MARK: - Gets the image
    func getImage() -> UIImage {
        return self.image! ///UIImage(contentsOfFile: self.path)!
    }
    
    // MARK: - Returns the GPS Ratio
    func getGPSRatio() -> (xRatio:Double,yRatio:Double) {
        return self.ratio!
    }
    
    // MARK: - Returns the difference in between the point and reference point
    func getPointDif() -> Double? {
        if self.point != nil && self.referencePoint != nil {
            return self.point!.distanceTo(self.referencePoint!)
        }
        return nil
    }
    
    // MARK: - Sets the referenceImage
    func setReferenceImage(_ image:OrthoImage) {
        self.referenceImage = image
    }
    
    // MARK: - Sets image ID good when removing images from the bunch
    func setID(_ id:Int) {
        self.id = id
    }

    // MARK: - Sets the images point
    func setPoint(_ point:CGPoint) {
        self.point = point
    }
    
    // MARK: - Updates the point of the image that way it doesn't go off frame
    func setTranslatedPoint(_ newPoint:CGPoint) {
        self.point = CGPoint(x:self.point!.x + abs( newPoint.x) ,y: self.point!.y + abs(newPoint.y) )
    }
    
    // MARK: - Sets the reference point
    func setRefPoint(_ point:CGPoint) {
        self.referencePoint = point
    }
    
    // MARK: - Function for calling pointsForImage
    func calcPointsForImage() {
        self.pointsForImage()
    }

    
    // MARK: - Adds another Reference Image to average out the point
    func addAlternativeRef(_ alternativeImage:OrthoImage) {

        let imageTranslator = ImageTranslator(referenceImage: alternativeImage.getImage().cgImage!, floatingImage: self.getImage().cgImage! )
        let alternativeTranslation = imageTranslator.handleImageTranslationRequest()
        let suggestedPoint:CGPoint = alternativeImage.point!.applying(alternativeTranslation)


        if self.point!.distanceTo(suggestedPoint) < POINTDIF.getMedianDifference()!  {
            /** Average the two points */
            let newPoint = CGPoint(x: (self.point!.x + suggestedPoint.x)/2 ,  y:  (self.point!.y  + suggestedPoint.y)/2 )
            self.setPoint(newPoint)
        }
    }
    
    // MARK: - Uses the ImageTranslator class to find a translation
    func determineImageTranslation()  {
        if referenceImage != nil {
            let imageTranslator = ImageTranslator(referenceImage: referenceImage!.getImage().cgImage!, floatingImage: self.getImage().cgImage! )
            self.visionTranslation = imageTranslator.handleImageTranslationRequest()
        }
    }

    // MARK: - Calculates the x and y ratios for the image given gps coords
    func calcRatio() -> (xRatio:Double,yRatio:Double)?  {
        
        if referenceImage != nil && self.id != 0 {
            let imageMapPoint = MKMapPointForCoordinate(self.location!)
            let otherImageMapPoint = MKMapPointForCoordinate(referenceImage!.location!)
            let distanceX:Double = imageMapPoint.x - otherImageMapPoint.x
            let distanceY:Double = imageMapPoint.y - otherImageMapPoint.y
            
            /** IF the X distance is less than 25 then we discard the xRatio, due to the fact that GPS is off when dealing with small numbers */
            let xRatio = ( abs( distanceX ) ) < 25 ? Double( visionTranslation!.ty )  / ( distanceY ) : Double( visionTranslation!.tx ) /  ( distanceX )
            /** We do the same thing with the yRatio */
            let yRatio = ( abs( distanceY ) ) < 25 ? Double( visionTranslation!.tx )  / ( distanceX ) : Double( visionTranslation!.ty ) /  ( distanceY )
            
            return (xRatio:xRatio,yRatio:yRatio)
        }
        else {
            return nil
        }

    }
    
    
    private func makeAdjustRotation(rotation:Double) -> Double {
        switch rotation {
            case 0 ... 90:
                return 90 - rotation
            case 90 ... 180:
                return 180 - rotation
            case 180 ... 270:
                return 270 - rotation
            default:
                return 360 - rotation
        }
    }
    

    // MARK: - Sets the referencePoint and point properties
    private func pointsForImage() {
        if self.id != 0 && referenceImage?.point != nil {
            let imageMapPoint = MKMapPointForCoordinate(self.location!)
            let otherImageMapPoint = MKMapPointForCoordinate(referenceImage!.location!)
            let xDiff = ( imageMapPoint.x - otherImageMapPoint.x )
            let yDiff = ( imageMapPoint.y - otherImageMapPoint.y )

            let newTranslation = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: CGFloat(ORTHORATIO.getRatio()!.xRatio * xDiff)  , ty: CGFloat(ORTHORATIO.getRatio()!.yRatio * yDiff) )
            
            
            //let theta:CGFloat = CGFloat(self.rotation!.yaw) < 180 ?  CGFloat(self.rotation!.yaw) - 180  :  360 - CGFloat(self.rotation!.yaw)
            
            let yawInRadians = Double( makeAdjustRotation(rotation: self.rotation!.yaw)  ) * (Double.pi/180)
            print(self.id)
            let gpsTranslation =  CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: newTranslation.tx * CGFloat( cos(yawInRadians) ) - newTranslation.ty * CGFloat( sin(yawInRadians) )    , ty: newTranslation.tx * CGFloat( sin(yawInRadians) ) + newTranslation.ty * CGFloat( cos(yawInRadians) ) )
            
            self.gpsTranslation = gpsTranslation
            self.referencePoint = referenceImage!.point

            let xPoint = ( self.referencePoint!.applying( visionTranslation!).x )// + self.referencePoint!.applying( gpsTranslation).x ) / 2
            let yPoint = ( self.referencePoint!.applying( visionTranslation!).y )// + self.referencePoint!.applying( gpsTranslation).y ) / 2
            
            
            if (0.8...1.2) ~= abs(self.getTranslation().tx / self.getGPSTranslation().tx) &&  (0.8...1.2) ~= abs(self.getTranslation().ty / self.getGPSTranslation().ty)  {
                self.point = CGPoint(x:xPoint,y:yPoint) /** Otherwise Vision */
            }
            else {
                self.setPoint( self.referencePoint!.applying( self.getGPSTranslation())) /** Adjust */
            }
        

        }
        else if self.id != 0  {
            print("Points did not work.")
        }
    }
    
    func getRotationXMPDataFromImage(filePath:String)  -> (yaw:Double,pitch:Double,roll:Double)? {
        let url = URL(fileURLWithPath: filePath)
        let imageData:Data = try! Data(contentsOf: url)
        guard let source = CGImageSourceCreateWithData(imageData as NSData, nil) else { return (yaw:0,pitch:0,roll:0) }
        let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil)
        
        let flightYawTag = CGImageMetadataCopyTagWithPath(metadata!, nil, "drone-dji:FlightYawDegree" as NSString)
        let gimbalYawTag = CGImageMetadataCopyTagWithPath(metadata!, nil, "drone-dji:GimbalYawDegree" as NSString)
        let gimbalPitchTag = CGImageMetadataCopyTagWithPath(metadata!, nil, "drone-dji:GimbalPitchDegree" as NSString)
        
        
        let flightYaw = Double( String( ( String( flightYawTag.debugDescription.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)[1].split(separator: ")" , maxSplits: 1, omittingEmptySubsequences: true).first! )).split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true).last! ) )
        let gimbalYaw = Double( String( ( String( gimbalYawTag.debugDescription.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)[1].split(separator: ")" , maxSplits: 1, omittingEmptySubsequences: true).first! )).split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true).last! ) )
        let gimbalPitch = Double( String( ( String( gimbalPitchTag.debugDescription.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)[1].split(separator: ")" , maxSplits: 1, omittingEmptySubsequences: true).first! )).split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true).last! ) )
        
        
        
        if gimbalYaw != nil {
            return (yaw: -gimbalYaw! + 360 ,pitch: -gimbalPitch!,roll:0)
        }
        else {
            return (yaw:0,pitch:0,roll:0)
        }
        
    }

    
    // MARK: - Gets rotation xif data
    private func rotationForImage(_ url: URL) -> (yaw:Double,pitch:Double,roll:Double)? { // Returns rotation of image
        let createOptions: [String: AnyObject] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG as String as String as AnyObject]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, createOptions as CFDictionary?) else {
            print("Unable to determine rotation for image at \(url). Could not create image source.")
            return nil
        }
        
        let propertyOptions: [String: AnyObject] = [kCGImageSourceShouldCache as String: NSNumber(value: false as Bool)]
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, propertyOptions as CFDictionary?) as NSDictionary? else {
            print("Unable to determine rotation for image at \(url). Could not get properties from image.")
            return nil
        }
        
        guard let exifDictionary = properties[kCGImagePropertyExifDictionary] as? NSDictionary else {
            print("Unable to determine rotation for image at \(url). Required properties missing or invalid.")
            return nil
        }
        
        guard let rotation = exifDictionary[kCGImagePropertyExifUserComment] as? String,
            let allRotations = rotation.split(separator: "/") as? [Substring] else {
                print("Unable to find image rotation")
                return nil
        }
        
        //let rotationDifferences =  ( ( 360 - Double( allRotations[3] )!.convertYawTo360() ) + ( 360 - Double( allRotations[2] )!.convertYawTo360()  ) )  //( Double( allRotations[2] )!.convertYawTo360() ) - Double( allRotations[3] )!.convertYawTo360()
        
        if allRotations.count >= 6 {
            return (yaw: Double(allRotations[3])!.convertYawTo360()   ,pitch: Double( allRotations[4] )!,roll: Double( allRotations[5] )!)
        }
        else {
            return (yaw: Double(allRotations[2])!.convertYawTo360()   ,pitch: Double( allRotations[3] )!,roll: Double( allRotations[4] )!)
        }

        
    }
    
    // MARK: - Gets location xif data
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
    
    
}


