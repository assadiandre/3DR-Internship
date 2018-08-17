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


class OrthoImageBuilder {
    
    var allData:[OrthoImage] = []
    
    init(pathArray:[String]) { // Initializes OrthoImageBuilder with an array of OrthoImage objects
        for (index, path) in pathArray.enumerated() {
            let orthoImage = OrthoImage(imagePath: path, id: index)
            allData.append(orthoImage)
        }
        
       let imageLegs = sortLocationsIntoLegs(images:allData)
        
        
        for (set ,leg) in imageLegs.enumerated() {
            
            for image in leg {
                findImageWithID(image.id)!.set = set + 1
                
                
                print("Image\(image.path.components(separatedBy: "VideoFrame-").last!) is in set \(set + 1)")
                
            }
        }

        
    }
    
    func findImageWithID(_ id:Int) -> OrthoImage? {
        for image in allData {
            
            if image.id == id {
                return image
            }
            
        }
        return nil
    }
    
    func build() { // Builds the ortho
        //self.filterAllByPitch()
 
        self.pairAllGPSImageRef()
        self.findAllTranslations()
        self.pairAllSetImageRef()
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
                
                print(index)
                orthoImage.getImage().draw(at: orthoImage.point!)
                
                
            }
            
        }
        
        return returnValue
    }
    
    func sortLocationsIntoLegs(images: [OrthoImage]) -> [[OrthoImage]] {
        guard images.count > 2 else {
            return [images]
        }
        
        var allLegs: [Leg] = []
        
        
        var currentLeg: Leg! {
            didSet {
                allLegs.append(currentLeg)
            }
        }
        
        currentLeg = Leg(index: 0, images: [images[0], images[1]])
        
        var currentLocationIndex = 2
        
        while currentLocationIndex < images.count {
            let currentImage =  images[currentLocationIndex]
            if currentLeg.isPointInLeg(location: currentImage.location!) {
                currentLeg.addImage(image: images[currentLocationIndex])
            } else {
                let lastLocationInPreviousLeg = currentLeg.images.last!
                currentLeg = Leg(index: allLegs.count - 1, images: [lastLocationInPreviousLeg, currentImage])
            }
            currentLocationIndex += 1
        }
        
        
        return allLegs.map{ $0.images }
    }
    
    func setAllYaw(yaw:Double) {
        for image in allData {
            image.setYaw(yaw)
            image.update()
        }
    }
    
    func findMedianYaw() -> Double {
        var allYaws:[Double] = []
        for image in allData {
            allYaws.append(image.yaw!)
        }
        allYaws.sort()
        return allYaws[ Int( Double(allYaws.count)/2 ) ]
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
    
    func pairAllSetImageRef() {
        for image in allData {
            self.pairSeperateSetImage(targetImage: image)
        }
    }
    
    func filterAllByPitch() {
        for (index,image) in allData.enumerated().reversed() {
            if abs(image.pitch! + 90) > 1 {
                allData.remove(at: index)
            }
        }
        updateAllIDs() // Updates all IDs in array, need because we remove values
    }
    
    func updateAllIDs() {
        for (index,image) in allData.enumerated() {
            image.setID(index)
        }
    }
    
    func findAllTranslations() { // Finds the translation needed for all the images
        for (image) in allData {
            print( "Image ID: \(image.id), Reference IDs: \(image.referenceImages[0].id)" )
            print("TargetImage: \(image.path.components(separatedBy: "VideoFrame-").last!) CurrentImageRef: \(image.referenceImages[0].path.components(separatedBy: "VideoFrame-").last!) ")
            image.determineImageTranslation()
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
                targetImage.point = CGPoint.zero
                targetImage.points.append(CGPoint.zero)
                targetImage.referencePoints.append(CGPoint.zero)
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
        
        targetImage.referenceImages.append( currentImageRef! )
    }
    
    
    func pairSeperateSetImage(targetImage:OrthoImage) {
        
        if targetImage.id == 0 {
            targetImage.points.append(CGPoint.zero )
            targetImage.referencePoints.append(CGPoint.zero)
            targetImage.referenceImages.append( targetImage )
        }
        else if targetImage.set! % 2 != 0 { // if the image set is odd
            
            let opposingSet:Int = targetImage.set! + 2
            var smallestDistance:Double = Double.greatestFiniteMagnitude
            var currentImageRef:OrthoImage?
            
            for image in allData {
                if image.set == opposingSet {
                    let sum:Double = targetImage.location!.distanceTo(image.location!)
                    
                    if sum < smallestDistance {
                        smallestDistance = sum
                        currentImageRef = image
                    }
                }
            }
            
            if currentImageRef != nil {
                targetImage.referenceImages.append(currentImageRef!)
                targetImage.referencePoints.append(currentImageRef!.point!)
                
                print( "Target Image : \(targetImage.path)"  )
                print( "Reference Image 0: \(targetImage.referenceImages[0].path)"  )
                print( "Reference Image 1: \(targetImage.referenceImages[1].path)"  )
                
            }
            
        }
    }
    
//    func pairGPSImageRefNonLinear(targetImage:OrthoImage) {
//
//        if targetImage.id == 0 {
//            targetImage.setPoint(  CGPoint.zero )
//            targetImage.setRefPoint( CGPoint.zero )
//            targetImage.setReferenceImage( targetImage )
//        }
//        var possiblePairs:[OrthoImage] = []
//        var currentImageRef:OrthoImage?
//        var smallestDistance:Double = Double.greatestFiniteMagnitude
//
//        for index in 0 ..< 12 {
//
//            for image in self.allData {
//
//                var allowSearch:Bool = true
//                for possibleImage in possiblePairs {
//                    if possibleImage.id == image.id  {
//                        allowSearch = false
//                    }
//                }
//
//                if targetImage.id != image.id && allowSearch {
//                    print(abs( targetImage.location!.latitude - image.location!.latitude) )
//                    let sum:Double = targetImage.location!.distanceTo(image.location!)
//                    if sum < smallestDistance {
//                        smallestDistance = sum
//                        currentImageRef = image
//                    }
//
//                }
//
//            }
//            print()
//            possiblePairs.append(currentImageRef!)
//            smallestDistance = Double.greatestFiniteMagnitude
//
//        }
//
//
//        for image in possiblePairs {
//            print(image.id)
//        }
//
//
//
//    }
    
    
    
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
