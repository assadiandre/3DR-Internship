//
//  OrthoImageBuilder.swift
//  Low-res Ortho
//
//  Created by Andre on 7/3/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

extension UIImage {
    func cropped(boundingBox: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: boundingBox) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}


class OrthoImageBuilder {
    
    var allData:[OrthoImage] = []
    
    init(pathArray:[String]) { // Initializes OrthoImageBuilder with an array of OrthoImage objects
        for (index, path) in pathArray.enumerated() {
            let orthoImage = OrthoImage(imagePath: path, id: index)
            allData.append(orthoImage)
        }
    }
    
    func build() { // Builds the ortho
        self.pairAllGPSImageRef()
        self.findAllTranslations()
        let newOrigin = self.findNewOrigin()
        self.translateAllPoints(newOrigin: newOrigin)
    }
    
    func createImage() -> UIImage? { // Draws the ortho
        let size = self.getFrameSize()
        let returnValue:UIImage?
        let renderer = UIGraphicsImageRenderer(size: size)
        
        returnValue = renderer.image { context in
            ///Uncomment to see border
            //UIColor.darkGray.setStroke()
            //context.stroke(renderer.format.bounds)
            
            for (index,orthoImage) in self.allData.enumerated() {
            
                //orthoImage.getImage().cropped(boundingBox: CGRect(x: 70, y: 0, width: orthoImage.getImage().size.width - 70 , height: orthoImage.getImage().size.height))?.draw(at: orthoImage.point!)
//
//
                
                if index < 6 {
                    orthoImage.getImage().draw(at: orthoImage.point!)
                    print(index)
                }

            
            }
            
        }
        
        return returnValue
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let contextImage: UIImage = UIImage(cgImage: image.cgImage!)
        
        let contextSize: CGSize = contextImage.size
        
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x:posX, y:posY, width:cgwidth, height:cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }

    
    func addData(pathArray:[String]) { // Adds OrthoImage objects to OrthoImageBuilder
        for index in allData.count ..< pathArray.count {
            let orthoImage = OrthoImage(imagePath: pathArray[index], id: index)
            allData.append(orthoImage)
        }
    }
    
    func pairAllGPSImageRef() { // Mass pairs all image references
        for (index,image) in allData.enumerated() {
            self.pairGPSImageRefLinear(targetImage: image, index:index)
            //self.pairGPSImageRef(targetImage: image)
        }
    }

    func updateAllIDs() {
        for (index,image) in allData.enumerated() {
            image.setID(index)
        }
    }
    
    
    func findAllTranslations() { // Finds the translation needed for all the images
        for (index, image) in allData.enumerated() {
            if image.referenceImage?.id != nil {
                print( "Image ID: \(image.id), Reference ID: \(image.referenceImage!.id)" )
                print("TargetImage: \(image.path.components(separatedBy: "VideoFrame-").last!) CurrentImageRef: \(image.referenceImage!.path.components(separatedBy: "VideoFrame-").last!) ")
                //print(image.rotation!)
                
                AverageRatio.xRatio = AverageRatio.xStack / Double(index - 1)
                AverageRatio.yRatio = AverageRatio.yStack / Double(index - 1)
                image.determineImageTranslation()
                

            }
            else {

                print("ERROR no reference image, check that pairAllGPSImageRef was called.")
            }
        }
        
        
        
        
    }
    
    func findNewOrigin() -> CGPoint { // Finds the top left most coordinate in allData
        return CGPoint(x:findxMin(),y:findyMin())
    }
    
    func translateAllPoints(newOrigin:CGPoint) { // Translates all points in allData
        for orthoImage in allData {
            orthoImage.setTranslatedPoint(newOrigin)
        }
    }
    
    func getFrameSize() -> CGSize {
        let width:CGFloat = (self.findxMax() + self.allData[0].getImage().size.width/2) - (self.findxMin() - self.allData[0].getImage().size.width/2)
        let height:CGFloat = (self.findyMax() + self.allData[0].getImage().size.height/2) - (self.findyMin() - self.allData[0].getImage().size.height/2)
        return CGSize(width:width,height:height)
    }

    private func pairGPSImageRefLinear(targetImage:OrthoImage, index:Int)  { // Finds smallest GPS distance in array and pairs image
        var smallestDistance:Double = Double.greatestFiniteMagnitude
        var currentImageRef:OrthoImage?

        for i in 0 ... index  {
            if targetImage.id == 0 { // Sets points for first image
                targetImage.setPoint(CGPoint.zero)
                targetImage.setRefPoint(CGPoint.zero)
                currentImageRef = targetImage
            }
            else if allData[i].id != targetImage.id { // All other cases
                let sum:Double = targetImage.location!.distanceTo(allData[i].location!)
                if sum < smallestDistance {
                    smallestDistance = sum
                    currentImageRef = allData[i]
                }
            }
        }
        
        targetImage.setReferenceImage(currentImageRef!)
    }
    
    
    private func findxMax() -> CGFloat { // Finds max x coordinate in set
        var xMax:CGFloat = -CGFloat.greatestFiniteMagnitude
        for image in allData {
            if CGFloat(image.point!.x) > xMax {
                xMax = CGFloat(image.point!.x)
            }
        }
        return xMax
    }
    
    private func findxMin() -> CGFloat { // Finds min x coordinate in set
        var xMin:CGFloat = CGFloat.greatestFiniteMagnitude
        for image in allData {
            if CGFloat(image.point!.x) < xMin {
                xMin = CGFloat(image.point!.x)
            }
        }
        return xMin
    }
    
    private func findyMax() -> CGFloat { // Finds max y coordinate in set
        var yMax:CGFloat = -CGFloat.greatestFiniteMagnitude
        for image in allData {
            if CGFloat(image.point!.y) > yMax {
                yMax = CGFloat(image.point!.y)
            }
        }
        return yMax
    }
    
    private func findyMin() -> CGFloat { // Finds min y coordinate in set
        var yMin:CGFloat = CGFloat.greatestFiniteMagnitude
        for image in allData {
            if CGFloat(image.point!.y) < yMin {
                yMin = CGFloat(image.point!.y)
            }
        }
        return yMin
    }
    
    
    

}
