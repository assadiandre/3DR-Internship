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

extension UIImage {
    func reRender() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width:size.width, height:size.height))
        self.draw(in: CGRect(x:0, y:0, width:size.width, height:size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension UIImage {
    func cropped(boundingBox: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: boundingBox) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

extension CGPoint {
    
    func distanceTo(_ secondPoint:CGPoint) -> Double{
        let distance:Double = Double( sqrt( pow(self.x - secondPoint.x,2) + pow(self.y - secondPoint.y,2) ) )
        return distance
    }
    
    
    
}


extension UIImage {
    func cropOrtho() -> UIImage {
        
        let cropWidthOff:CGFloat = 100
        let cropHeightOff:CGFloat = 100
        
        let croppedImage = self.cropped(boundingBox: CGRect(x:cropWidthOff,y:cropHeightOff,width:size.width - (cropWidthOff * 2.0),height: size.height - (cropHeightOff * 2.0)  ))
        
        UIGraphicsBeginImageContext(CGSize(width:size.width, height:size.height))
        
        croppedImage!.draw(at: CGPoint(x:cropWidthOff,y:cropHeightOff))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
}

extension UIImage {
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}


extension UIImage {
    
    func opacitySides(cutOff:CGFloat) -> UIImage {
        
        let cropWidthOff:CGFloat = cutOff
        let cropHeightOff:CGFloat = cutOff
        
        let reducedImage = self.alpha(0.25)
        let croppedImage = self.cropped(boundingBox: CGRect(x:cropWidthOff,y:cropHeightOff,width:size.width - (cropWidthOff * 2.0),height: size.height - (cropHeightOff * 2.0)  ))
        
        UIGraphicsBeginImageContext(CGSize(width:size.width, height:size.height))
        
        reducedImage.draw(at: CGPoint(x:0,y:0))
        croppedImage!.draw(at: CGPoint(x:cropWidthOff,y:cropHeightOff))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    
}



extension UIImage {
    
    
    func addImage( newImagePoint:CGPoint, newImage:UIImage ) -> UIImage {
        var width:CGFloat = self.size.width
        var height:CGFloat = self.size.height
        var xChange:CGFloat = 0
        var yChange:CGFloat = 0
        
        /* Sets the size and change coordinates based on the image position */
        
        if  newImagePoint.x > self.size.width || newImagePoint.x < 0 {
            xChange = newImagePoint.x > 0 ? (newImagePoint.x - self.size.width) : newImagePoint.x
            width =  abs( xChange ) + width
        }
        if newImagePoint.y > self.size.height || newImagePoint.y < 0 {
            yChange = newImagePoint.y > 0 ? (newImagePoint.y - self.size.height) : newImagePoint.y
            height = abs( yChange ) + height
        }
        
        /* Adds padding for images whos width/height exit frame */

        width += ( (newImagePoint.x + newImage.size.width) - width) > 0 ? ( (newImagePoint.x + newImage.size.width) - width) : 0
        height += ( (newImagePoint.y + newImage.size.height) - height) > 0 ? ( (newImagePoint.y + newImage.size.height) - height) : 0
        
        
        /* Build the rectangle representing the area for the original image to be drawn */
        let newSize:CGSize = CGSize(width: width, height: height)
        
        var originalImageRect = CGRect.zero
        originalImageRect.size.width = self.size.width
        originalImageRect.size.height = self.size.height
        
        if xChange < 0 {
            originalImageRect.origin.x = newSize.width - originalImageRect.size.width
        }
        if yChange < 0 {
            originalImageRect.origin.y = newSize.height - originalImageRect.size.height
        }
        
        /* Create new point for newImage  */
        
        var adjustedPoint = CGPoint.zero
        adjustedPoint.x = xChange < 0 ? newImagePoint.x - xChange : newImagePoint.x
        adjustedPoint.y = yChange < 0 ? newImagePoint.y - yChange : newImagePoint.y
        
        /* Draw */
        UIGraphicsBeginImageContext(newSize)
        
        let context  = UIGraphicsGetCurrentContext()
        
        self.draw(in: originalImageRect)
        newImage.draw(at: adjustedPoint )

        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return finalImage!
    }
    
    
}


extension Double {
    
    func convertYawTo360() -> Double  {
        if self < 0 {
            return self + 360
        }
        return self
    }
    
    
    func covertFlipRotation() -> Double {
        
        if self > 90 && self <= 180 {
            return 360 - self
        }
        
        return self
    }
    
    
}


extension UIImage {
    
    func setBoxOutImage(rotation:Double) -> UIImage {
        let oldImage = self
        let tempImage = imageRotatedByDegrees(oldImage: oldImage , deg: CGFloat( rotation.covertFlipRotation() ))
        
        let theta:CGFloat = CGFloat(rotation) < 180 ? CGFloat(rotation) :  360 - CGFloat(rotation)
        
        let alpha:CGFloat = theta * (CGFloat.pi / 180)
        let yCoord = oldImage.size.width * sin(alpha)
        let xCoord = oldImage.size.height * sin(alpha)
        
        let imageWidth = tempImage.size.width - (2 * xCoord)
        let imageHeight = tempImage.size.height - (2 * yCoord)
        
        let image:UIImage = cropImage(tempImage, toRect: CGRect(x: xCoord   , y: yCoord , width: imageWidth   , height:  imageHeight  ))!
        return image
    }
    
    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect) -> UIImage?
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
    
    
    func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
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
    
    
    
    
}




























