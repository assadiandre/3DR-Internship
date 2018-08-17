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
    var storedImage:UIImage?
    
    // MARK: - Initializes OrthoImageBuilder with an array of OrthoImage objects
    init(pathArray:[String]) {
        
        
        for (index, path) in pathArray.enumerated() {
            
            let orthoImage = OrthoImage(imagePath: path, id: allData.count)

            if checkImageRotation(orthoImage,index) {
                allData.append(orthoImage)
                ///  RATIO BUILDER
                print(orthoImage.id)
                self.pairGPSImageRefLinear(targetImage: orthoImage, index:index)
                orthoImage.determineImageTranslation()
                self.addRatioFromImage(orthoImage)
            }

        }
        
    }

    
    // MARK: - Builds the Ortho, pairs all images, finds all translations, sets points...
    func build() {
        ORTHORATIO.finalRatio = ORTHORATIO.calcMedianRatios()
        self.pairAllGPSImageRef()
        self.findAllTranslationsPoints()
    
        let newOrigin = self.findNewOrigin()
        self.translateAllPoints(newOrigin: newOrigin)
    }
    
    // MARK: - Adds OrthoImage objects to allData
    func addImage(imagePath:String) {
        let index = allData.count
        let orthoImage = OrthoImage(imagePath: imagePath, id: index)
        
        if checkImageRotation(orthoImage,index) {
            allData.append(orthoImage)
            ///  RATIO BUILDER
            if allData.count <= ORTHORATIO.numImages {
                self.pairGPSImageRefLinear(targetImage: orthoImage, index:index)
                orthoImage.determineImageTranslation()
                self.addRatioFromImage(orthoImage)
            }
        }

    }
    
    
    
    func findNearestPoints(_ targetImage:OrthoImage) -> [OrthoImage] {
        
        let targetCoords = targetImage.point
        var shortestDistance:Double = Double.greatestFiniteMagnitude
        var selectedOrtho:OrthoImage?
        var selectedOrthos:[OrthoImage] = []
        var selectedOrthoIDS:[Int] = []
        
        
        for _ in 0 ..< 4 {
            for orthoImage in allData {
                if orthoImage.point != nil {
                    let distance:Double = targetCoords!.distanceTo(orthoImage.point!)
                    
                    
                    if distance < shortestDistance && selectedOrthoIDS.contains(orthoImage.id) == false && orthoImage.id  != targetImage.id {
                        shortestDistance = distance
                        selectedOrtho = orthoImage
                    }
                    
                }
                
            }
            
            
            if selectedOrtho != nil {
                selectedOrthos.append(selectedOrtho!)
                selectedOrthoIDS.append(selectedOrtho!.id)
                shortestDistance = Double.greatestFiniteMagnitude
                selectedOrtho = nil
            }
        }
        
        return selectedOrthos
    }
    
    
    // MARK: - Checks the image rotation, and acts accordingly
    func checkImageRotation(_ image:OrthoImage, _ index:Int) -> Bool {
        let rotation = image.rotation!
        
        if abs( rotation.pitch ) <= 88.8 {
            return false
        }
        return true
    }

    // MARK: - Adds a ratio to ORTHORATIO
    func addRatioFromImage(_ orthoImage:OrthoImage) {
        if let ratio = orthoImage.calcRatio() {
             ORTHORATIO.allRatios.append(ratio)
        }
    }
    
    // MARK: - Adds a difference to POINTDIF
    func addDifFromImage(_ orthoImage:OrthoImage) {
        if let difference = orthoImage.getPointDif() {
            POINTDIF.allDiffs.append(difference)
            POINTDIF.difference = POINTDIF.calcMedianDiff()
        }
    }
    
    
    // MARK: - Finds other possible image Refs in allData
    func findAlternativeImageRef(_ targetImage:OrthoImage) -> OrthoImage? {
        var smallestDistance:Double = Double.greatestFiniteMagnitude
        var storedImage:OrthoImage?
        for orthoImage in allData {
            
            if orthoImage.point != nil {
                let currentDistance = targetImage.point!.distanceTo( orthoImage.point! )
                if currentDistance < smallestDistance && targetImage.id != orthoImage.id && targetImage.referenceImage!.id != orthoImage.id && targetImage.referenceImage!.id - 1 != orthoImage.id  {
                    
                    smallestDistance = currentDistance
                    storedImage = orthoImage
                }
            }
        }
        return storedImage
    }

    
    // MARK: - Draws the Ortho
    func createImage() -> UIImage? {
        let size = self.getFrameSize()
        let renderer = UIGraphicsImageRenderer(size: size)
        if storedImage == nil {
            /** If the storedImage has not already been created,
             this section renders all the images and their points.*/
            storedImage = renderer.image { context in
                for (orthoImage) in self.allData {
                    orthoImage.getImage().opacitySides(cutOff: 30).draw(at: orthoImage.point!)
                }
            }
            
        }
        else {
            /** As opposed to re-rendering all the images at once,
             the following code simply adds the image to the existing storedImage*/
            storedImage = storedImage!.addImage(newImagePoint: allData.last!.rawPoint!, newImage: allData.last!.getImage().opacitySides(cutOff: 30) )
        }
        

        return storedImage!.reRender() /// Fixes CGImage size problem
    }
    
    


    
    // MARK: - Mass pairs all image references
    func pairAllGPSImageRef() {
        for (index,image) in allData.enumerated() {
            self.pairGPSImageRefLinear(targetImage: image, index:index)
        }
    }
    

    // MARK: - Finds the translation needed for all the images + points
    func findAllTranslationsPoints() {
        for image in allData {
            if image.referenceImage?.id != nil && image.point == nil {
                image.determineImageTranslation()
            
                if ORTHORATIO.getRatio() != nil {
                    image.calcPointsForImage()
                    self.addDifFromImage(image)
                }

                //findMorePoints(targetImage: image)

                let allSet = findNearestPoints(image)

                for orthoimage in allSet {

                    image.addAlternativeRef(orthoimage)

                }

            }
        }
    }
    
    
    // MARK: - Finds Origin in allData / Top left most point
    func findNewOrigin() -> CGPoint {
        return CGPoint(x:findxMin(),y:findyMin())
    }
    
    // MARK: - Image Point Translation
    func translateAllPoints(newOrigin:CGPoint) {
        /**
         - parameters:
            - newOrigin: The top left most point, the origin, as generated by findNewOrigin()
         */
        for orthoImage in allData {
            orthoImage.rawPoint = orthoImage.point!
            orthoImage.setTranslatedPoint(newOrigin)
        }
    }
    
    // MARK: - Finds Final Image Size
    func getFrameSize() -> CGSize {
        let width:CGFloat = (self.findxMax() + self.allData[0].getImage().size.width/2) - (self.findxMin() - self.allData[0].getImage().size.width/2)
        let height:CGFloat = (self.findyMax() + self.allData[0].getImage().size.height/2) - (self.findyMin() - self.allData[0].getImage().size.height/2)
        return CGSize(width:width,height:height)
    }

    // MARK: - Finds smallest GPS distance in array and pairs image
    private func pairGPSImageRefLinear(targetImage:OrthoImage, index:Int)  {
        var smallestDistance:Double = Double.greatestFiniteMagnitude
        var currentImageRef:OrthoImage?
        /**
         - parameters:
            - targetImage: The OrthoImage object that is being paired
            - index: The cap index so that the pairing doesn't match with image that is ahead.
         */
        if targetImage.referenceImage == nil {
            for i in 0 ... index  {
                if targetImage.id == 0 { /// Sets points for first image
                    targetImage.setPoint(CGPoint.zero)
                    targetImage.setRefPoint(CGPoint.zero)
                    currentImageRef = targetImage
                }
                else if allData[i].id != targetImage.id { /// All other cases
                    let sum:Double = targetImage.location!.distanceTo(allData[i].location!)
                    if sum < smallestDistance {
                        smallestDistance = sum
                        currentImageRef = allData[i]
                    }
                }
            }
            targetImage.setReferenceImage(currentImageRef!)
        }
    }
    
    
    // MARK: - Loops through all data to find bottom left image
    func findBottomLeftImage() -> (coordinates:CLLocationCoordinate2D, point:CGPoint, image:OrthoImage) {
        let bottomLeft:CGPoint = CGPoint(x:findxMin(),y:findyMax())
        var smallestDistance:CGFloat = CGFloat.greatestFiniteMagnitude
        var bottomLeftImage:OrthoImage?
        
        for orthoImage in allData  {
            if orthoImage.point!.distanceTo(bottomLeft) < Double( smallestDistance ) {
                bottomLeftImage = orthoImage
                smallestDistance = CGFloat(orthoImage.point!.distanceTo(bottomLeft))
            }
        }
        let imagePoint:CGPoint = CGPoint(x:bottomLeftImage!.point!.x + (bottomLeftImage!.getImage().size.width / 2)   ,y:bottomLeftImage!.point!.y + (bottomLeftImage!.getImage().size.height / 2) )
        return (coordinates: bottomLeftImage!.location! ,point: imagePoint,image:bottomLeftImage! )
    }

    
    
    // MARK: - Loops through all data to find top right image
    func findTopRightImage() -> (coordinates:CLLocationCoordinate2D, point:CGPoint, image:OrthoImage) {
        let topRight:CGPoint = CGPoint(x:findxMax(),y:findyMin())
        var smallestDistance:CGFloat = CGFloat.greatestFiniteMagnitude
        var topRightImage:OrthoImage?
        
        for orthoImage in allData  {
            if orthoImage.point!.distanceTo(topRight) < Double( smallestDistance ) {
                topRightImage = orthoImage
                smallestDistance = CGFloat(orthoImage.point!.distanceTo(topRight))
            }
        }
        let imagePoint:CGPoint = CGPoint(x:topRightImage!.point!.x + (topRightImage!.getImage().size.width / 2)   ,y:topRightImage!.point!.y + (topRightImage!.getImage().size.height / 2) )
        return (coordinates: topRightImage!.location! ,point: imagePoint,image:topRightImage! )
    }
    
    
    func findBottomRightImage() -> (coordinates:CLLocationCoordinate2D, point:CGPoint, image:OrthoImage) {
        let bottomRight:CGPoint = CGPoint(x:findxMax(),y:findyMax())
        var smallestDistance:CGFloat = CGFloat.greatestFiniteMagnitude
        var bottomRightImage:OrthoImage?
        
        for orthoImage in allData  {
            if orthoImage.point!.distanceTo(bottomRight) < Double( smallestDistance ) {
                bottomRightImage = orthoImage
                smallestDistance = CGFloat(orthoImage.point!.distanceTo(bottomRight))
            }
        }
        let imagePoint:CGPoint = CGPoint(x:bottomRightImage!.point!.x + (bottomRightImage!.getImage().size.width / 2)   ,y:bottomRightImage!.point!.y + (bottomRightImage!.getImage().size.height / 2) )
        return (coordinates: bottomRightImage!.location! ,point: imagePoint,image:bottomRightImage! )
    }
    
    func findTopLeftImage() -> (coordinates:CLLocationCoordinate2D, point:CGPoint, image:OrthoImage) {
        let topLeft:CGPoint = CGPoint(x:findxMax(),y:findyMax())
        var smallestDistance:CGFloat = CGFloat.greatestFiniteMagnitude
        var topLeftImage:OrthoImage?
        
        for orthoImage in allData  {
            if orthoImage.point!.distanceTo(topLeft) < Double( smallestDistance ) {
                topLeftImage = orthoImage
                smallestDistance = CGFloat(orthoImage.point!.distanceTo(topLeft))
            }
        }
        let imagePoint:CGPoint = CGPoint(x:topLeftImage!.point!.x + (topLeftImage!.getImage().size.width / 2)   ,y:topLeftImage!.point!.y + (topLeftImage!.getImage().size.height / 2) )
        return (coordinates: topLeftImage!.location! ,point: imagePoint,image:topLeftImage! )
    }
    
    
    // MARK: - Finds largest X coordinate in allData
    private func findxMax() -> CGFloat {
        var xMax:CGFloat = -CGFloat.greatestFiniteMagnitude
        for image in allData {
            
            if let point = image.point {
                if CGFloat(point.x) > xMax {
                    xMax = CGFloat(point.x)
                }
            }

        }
        return xMax
    }
    
    // MARK: - Finds smallest X coordinate in allData
    private func findxMin() -> CGFloat {
        var xMin:CGFloat = CGFloat.greatestFiniteMagnitude
        for image in allData {
            
            
            if let point = image.point {
                if CGFloat(point.x) < xMin {
                    xMin = CGFloat(point.x)
                }
            }

        }
        return xMin
    }
    
    // MARK: - Finds largest Y coordinate in allData
    private func findyMax() -> CGFloat {
        var yMax:CGFloat = -CGFloat.greatestFiniteMagnitude
        for image in allData {
            if let point = image.point {
                if CGFloat(point.y) > yMax {
                    yMax = CGFloat(point.y)
                }
            }
        }
        return yMax
    }
    
    // MARK: - Finds smallest Y coordinate in allData
    private func findyMin() -> CGFloat {
        var yMin:CGFloat = CGFloat.greatestFiniteMagnitude
        for image in allData {
            if let point = image.point {
                if CGFloat(point.y) < yMin {
                    yMin = CGFloat(point.y)
                }
            }
        }
        return yMin
    }
    
    
    

}



//func findMorePoints(targetImage:OrthoImage) {
//
//
//    var allDistances:[ String:[ (distance:CGFloat, image:OrthoImage) ] ] = [:]
//    //var smallestDistances:[ String:[ Int? ] ] = [:]
//    var allPoints:[String:CGPoint] = [:]
//
//    allPoints["leftMostPoint"] =  CGPoint(x:targetImage.point!.x - 300 ,y:targetImage.point!.y + targetImage.getImage().size.height/2)
//    allPoints["rightMostPoint"] = CGPoint(x:targetImage.point!.x + targetImage.getImage().size.width + 300,y:targetImage.point!.y + targetImage.getImage().size.height/2)
//    allPoints["topMostPoint"] = CGPoint(x:targetImage.point!.x + targetImage.getImage().size.width/2,y:targetImage.point!.y - 300 )
//    allPoints["bottomMostPoint"] = CGPoint(x:targetImage.point!.x + targetImage.getImage().size.width/2,y:targetImage.point!.y + targetImage.getImage().size.height + 300)
//
//
//    for image in allData {
//        if image.point != nil && image.id != targetImage.id {
//            for (key,point) in allPoints {
//                let distance:CGFloat = CGFloat( point.distanceTo(image.point!) )
//
//                if allDistances[key] == nil {
//                    allDistances[key] = []
//                }
//
//                if allDistances[key]!.count == 2 {
//
//                    let firstImage = allDistances[key]![0]
//                    let secondImage = allDistances[key]![1]
//
//                    if firstImage.distance > distance {
//                        allDistances[key]![0] = ( (distance: distance, image: image) )
//                    }
//
//                    if secondImage.distance > distance && secondImage.distance != firstImage.distance {
//                        allDistances[key]![1] = ( (distance: distance, image: image) )
//                    }
//
//                }
//                else {
//                    allDistances[key]!.append( (distance: distance, image: image) )
//                }
//
//            }
//        }
//    }
//
//    for (key,value) in allDistances {
//        for tuple in value {
//            print("Distance: \(tuple.distance), Image: \(tuple.image.id)")
//
//            targetImage.addAlternativeRef(tuple.image)
//
//        }
//
//
//    }
//
//    print()
//
//}
//
//
//
//
//
//
//
//func distancePointLine( distanceFromPoint P:CGPoint, toLineStartPoint A:CGPoint,  toLineEndPoint B:CGPoint) -> CGFloat {
//    if ((P.x - A.x) * (B.x - A.x) + (P.y - A.y) * (B.y - A.y) < 0) {
//        return sqrt(pow((P.x - A.x), 2) + pow((P.y - A.y), 2))
//    }
//
//    if ((P.x - B.x) * (A.x - B.x) + (P.y - B.y) * (A.y - B.y) < 0) {
//        return sqrt(pow(P.x - B.x, 2) + pow(P.y - B.y, 2))
//    }
//
//    return abs((P.x * (A.y - B.y) + P.y * (B.x - A.x) + (A.x * B.y - B.x * A.y)) / sqrt(pow(B.x - A.x, 2) + pow(B.y - A.y, 2)))
//}


/** Some not useful as of now code: */

/**
func updateAllIDs() {
    for (index,image) in allData.enumerated() {
        image.setID(index)
    }
}
**/


/**
 func findNearestPoints(_ targetImage:OrthoImage) -> [OrthoImage] {
 
 let targetCoords = targetImage.point
 var shortestDistance:Double = Double.greatestFiniteMagnitude
 var selectedOrtho:OrthoImage?
 var selectedOrthos:[OrthoImage] = []
 var selectedOrthoIDS:[Int] = []
 
 for i in 0 ..< 10 {
 for orthoImage in allData {
 if orthoImage.point != nil {
 var distance:Double = targetCoords!.distanceTo(orthoImage.point!)
 
 
 if distance < shortestDistance && selectedOrthoIDS.contains(orthoImage.id) == false && orthoImage.id  != targetImage.id {
 shortestDistance = distance
 selectedOrtho = orthoImage
 }
 
 
 }
 
 }
 
 
 if selectedOrtho != nil {
 selectedOrthos.append(selectedOrtho!)
 selectedOrthoIDS.append(selectedOrtho!.id)
 shortestDistance = Double.greatestFiniteMagnitude
 selectedOrtho = nil
 }
 }
 
 return selectedOrthos
 }

 
 
 
 */

/** func findNearestImagesGPS(_ targetImage:OrthoImage) {
    
    let targetCoords = targetImage.location
    var shortestDistance:Double = Double.greatestFiniteMagnitude
    var selectedOrtho:OrthoImage?
    var selectedOrthos:[OrthoImage] = []
    var selectedOrthoIDS:[Int] = []
    
    for i in 0 ..< 3 {
        for orthoImage in allData {
            
            var distance:Double = targetCoords!.distanceTo(orthoImage.location!)
            
            
            if distance < shortestDistance && selectedOrthoIDS.contains(orthoImage.id) == false && orthoImage.id  != targetImage.id {
                shortestDistance = distance
                selectedOrtho = orthoImage
            }
            
            
        }
        
        if selectedOrtho != nil {
            selectedOrthos.append(selectedOrtho!)
            selectedOrthoIDS.append(selectedOrtho!.id)
            shortestDistance = Double.greatestFiniteMagnitude
            selectedOrtho = nil
        }
        
        
    }
    
    for orthoImage in selectedOrthos {
        print("-/\(targetImage.id): \(orthoImage.id)")
    }
    
} */
























