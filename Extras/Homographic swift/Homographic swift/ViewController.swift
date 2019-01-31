//
//  ViewController.swift
//  Homographic swift
//
//  Created by Andre on 7/24/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import UIKit
import Vision
import CoreImage


class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    let warpKernel = CIWarpKernel(source:
        """
    kernel vec2 warp(mat3 homography)
    {
        vec3 homogen_in = vec3(destCoord().x, destCoord().y, 1.0); // create homogeneous coord
        vec3 homogen_out = homography * homogen_in; // transform by homography
        return homogen_out.xy / homogen_out.z; // back to normal 2D coordinate
    }
    """
    )
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    
    func homographicTransform(floatingImage:UIImage,referenceImage:UIImage) -> CIImage? {
        
        let request = VNHomographicImageRegistrationRequest(targetedCGImage: floatingImage.cgImage!, options: [:])
        var resultImage:CIImage?
        let handler = VNSequenceRequestHandler()
        try! handler.perform([request], on: referenceImage.cgImage!)
        if let results = request.results as? [VNImageHomographicAlignmentObservation] {
            print("Perspective warp found: \(results.count)")
            results.forEach { observation in
                // A matrix with 3 rows and 3 columns.
                
                
                let homography = observation.warpTransform
                print(homography)
                let (col0, col1, col2) = homography.columns
                let homographyCIVector = CIVector(values:[CGFloat(col0.x), CGFloat(col0.y), CGFloat(col0.z),
                                                          CGFloat(col1.x), CGFloat(col1.y), CGFloat(col1.z),
                                                          CGFloat(col2.x), CGFloat(col2.y), CGFloat(col2.z)], count: 9)
                
                let ciFloatingImage = CIImage(image: floatingImage)!
                let ciReferenceImage = CIImage(image: referenceImage)!
                
                let warpedExtent = computeExtentAfterTransforming(ciFloatingImage.extent, with: homography)
                let outputExtent = warpedExtent.union(ciFloatingImage.extent)
                
                let ciWarpedImage = warpKernel!.apply(extent: outputExtent, roiCallback:
                {
                    (index, rect) in
                    return self.computeExtentAfterTransforming(rect, with: homography)
                },
                                                      image: ciFloatingImage,
                                                      arguments: [homographyCIVector])!
                
                let ciResultImage = ciWarpedImage //.composited(over: ciReferenceImage)
                resultImage =  ciResultImage
            }
        }
        return resultImage
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let floatingImage = UIImage(named: "panorama_image2")!
        let referenceImage = UIImage(named:"panorama_image1")!
        
        
        /// To Perform Homographic translation
//        let referenceImageCIImage = CIImage(image: referenceImage)!
//        let firstImage = homographicTransform(floatingImage: floatingImage, referenceImage: referenceImage)
//        self.imageView.image = convert(cmage: firstImage!.composited(over: referenceImageCIImage))
//
        let imageTranslator = ImageTranslator(referenceImage: referenceImage.cgImage!, floatingImage: floatingImage.cgImage!)
        let translation = imageTranslator.handleImageTranslationRequest()

        UIGraphicsBeginImageContext(CGSize(width:1400,height:1400))

        floatingImage.draw(at: CGPoint(x:100,y:100).applying(translation))
        referenceImage.draw(at: CGPoint(x:100,y:100))

        let myImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        
        saveImageDocumentDirectory(image:myImage!,saveName:"image.jpg")
        self.imageView.image = myImage
    }
    
    
    func saveImageDocumentDirectory(image:UIImage,saveName:String){
        let fileManager = FileManager.default
        let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(saveName)
        let image = image
        print(paths)
        let imageData = UIImageJPEGRepresentation(image, 0.5)
        fileManager.createFile(atPath: paths as String, contents: imageData, attributes: nil)
    }
    
    
    /**
     * Convert a 2D point to a homogeneous coordinate, transform by the provided homography,
     * and convert back to a non-homogeneous 2D point.
     */
    func transform(_ point:CGPoint, by homography:matrix_float3x3) -> CGPoint
    {
        let inputPoint = float3(Float(point.x), Float(point.y), 1.0)
        var outputPoint = homography * inputPoint
        outputPoint /= outputPoint.z
        return CGPoint(x:CGFloat(outputPoint.x), y:CGFloat(outputPoint.y))
    }
    
    func computeExtentAfterTransforming(_ extent:CGRect, with homography:matrix_float3x3) -> CGRect
    {
        let points = [transform(extent.origin, by: homography),
                      transform(CGPoint(x: extent.origin.x + extent.width, y:extent.origin.y), by: homography),
                      transform(CGPoint(x: extent.origin.x + extent.width, y:extent.origin.y + extent.height), by: homography),
                      transform(CGPoint(x: extent.origin.x, y:extent.origin.y + extent.height), by: homography)]
        
        var (xmin, xmax, ymin, ymax) = (points[0].x, points[0].x, points[0].y, points[0].y)
        points.forEach { p in
            xmin = min(xmin, p.x)
            xmax = max(xmax, p.x)
            ymin = min(ymin, p.y)
            ymax = max(ymax, p.y)
        }
        let result = CGRect(x: xmin, y:ymin, width: xmax-xmin, height: ymax-ymin)
        return result
    }
    

    
    
    


}

