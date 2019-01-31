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
    //var referencePoint:CGPoint? // Stores a reference point for the image, where a translation can be applied
    //var referenceImage:OrthoImage? // The reference image the reference point is based off of
    var point:CGPoint? // The actual point of the image
    var translation:CGAffineTransform? // Translation that is applied to referencePoint
    var adjustedTranslation:CGAffineTransform? // Adjusted translation that inverts the y translation
    
    /// For new code
    var referenceImages:[OrthoImage] = []
    var referencePoints:[CGPoint] = []
    var points:[CGPoint] = []
    
    /// For when allowing rotation xib data
    var yaw:Double?
    var pitch:Double?
    var roll:Double?
    var rotation:(yaw:Double,pitch:Double,roll:Double)?
    
    
    
    var image:UIImage? /// GET RID OF AFTER
    
    init(imagePath:String, id:Int) {
        let imageURL = URL(fileURLWithPath:imagePath)
        self.id = id
        self.path = imagePath
        self.location = locationForImage(imageURL)!
        //self.rotation = rotationForImage(imageURL)!
        //self.yaw = self.rotation!.yaw
        //self.pitch = self.rotation!.pitch
        //self.roll = self.rotation!.roll
        //self.setBoxOutImage()
        //self.image = UIImage(contentsOfFile: imagePath)!
    }
    
//    func setReferenceImages(_ images:(image1:OrthoImage,image2:OrthoImage,image3:OrthoImage,image4:OrthoImage)) {
//
//    }
    
//    func setReferenceImage(_ image:OrthoImage) {
//        self.referenceImage = image
//    }
    
    func setID(_ id:Int) {
        self.id = id
    }
    
    func setSet(_ set:Int) {
        self.set = set
    }
    
    func setYaw(_ yaw:Double) {
        self.yaw = yaw
    }
    
    func update() {
        self.setBoxOutImage()
    }
    
//    func setPoint(_ point:CGPoint) {
//        self.point = point
//    }
    
//    func setImage(_ image:UIImage) { /// GET RID OF AFTER
//        self.image = image
//    }
    
    func setTranslatedPoint(_ newPoint:CGPoint) { // Updates point of an image, so that images don't go off frame
        self.point = CGPoint(x:self.point!.x + abs( newPoint.x) ,y: self.point!.y + abs(newPoint.y) )
    }
    
//    func setRefPoint(_ point:CGPoint) {
//        self.referencePoint = point
//    }
    
    func getImage() -> UIImage { /// GET RID OF AFTER
        return UIImage(contentsOfFile: self.path )!
    }
    
    func determineImageTranslation()  { // Uses the ImageTranslator class to find a translation
        
        if referenceImages.count == 2 {
            let imageTranslator = ImageTranslator(referenceImage: referenceImages[1].getImage().cgImage!, floatingImage: self.getImage().cgImage! )
            self.translation = imageTranslator.handleImageTranslationRequest()
            self.adjustedTranslation = self.translation
            self.adjustedTranslation!.ty = self.translation!.inverted().ty
            self.pointsForImage()
        }
        else if !referenceImages.isEmpty {
            let imageTranslator = ImageTranslator(referenceImage: referenceImages[0].getImage().cgImage!, floatingImage: self.getImage().cgImage! )
            self.translation = imageTranslator.handleImageTranslationRequest()
            self.adjustedTranslation = self.translation
            self.adjustedTranslation!.ty = self.translation!.inverted().ty
            print(self.adjustedTranslation)
            print()
            self.pointsForImage()
        }
    }
    
    
    
    private func setBoxOutImage() {
        let oldImage = UIImage(contentsOfFile: path)!
        let tempImage = imageRotatedByDegrees(oldImage: oldImage , deg: CGFloat(self.yaw!))
        
        let alpha:CGFloat = abs(CGFloat(self.yaw!) * (CGFloat.pi / 180))
        let yCoord = oldImage.size.width * sin(alpha)
        let xCoord = oldImage.size.height * sin(alpha)
        
        let imageWidth = tempImage.size.width - (2 * xCoord)
        let imageHeight = tempImage.size.height - (2 * yCoord)
        
        self.image = cropImage(tempImage, toRect: CGRect(x: xCoord   , y: yCoord , width: imageWidth   , height:  imageHeight  ))
    }
    
    
    private func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        

        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))

        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect) -> UIImage?
    {
        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x ,
                              y:cropRect.origin.y ,
                              width:cropRect.size.width ,
                              height:cropRect.size.height )
        
        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
            else {
                return nil
        }
        
        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
    

    
    private func pointsForImage() { //Sets the referencePoint and point properties
        
        if referenceImages.count == 2 {
            // find average and add
            self.referencePoints.append(referenceImages[1].point!)
            self.points.append(referencePoints[1].applying(adjustedTranslation!))
            print("Point 1: \(self.points[0])")
            print("Point 2: \(self.points[1])")
            
            self.point = CGPoint(x:(self.points[1].x + self.points[0].x )/2,y:(self.points[1].y + self.points[0].y )/2)
        }
        else if self.id != 0 && referenceImages[0].point != nil {
            self.referencePoints.append(referenceImages[0].point!)
            self.points.append(referencePoints[0].applying(adjustedTranslation!))
            self.point = referencePoints[0].applying(adjustedTranslation!)
        }
        else if self.id != 0  {
            print("Points did not work.")
        }
        
        
    }
    
    
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
        

        return (yaw: Double( allRotations[2] )!,pitch: Double( allRotations[3] )!,roll: Double( allRotations[4] )!)
        
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
