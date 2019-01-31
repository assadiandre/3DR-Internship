//
//  ViewController.swift
//  Low-res Ortho
//
//  Created by Andre on 7/2/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureImageData(imagePath: "/Images/Set 4")

        let orthoBuilder = OrthoImageBuilder(pathArray: ImageData.all)
        orthoBuilder.build()
        imageView.image = orthoBuilder.createImage()
        
        
//        let translator = ImageTranslator(referenceImage: orthoBuilder.allData[0].getImage().cgImage!, floatingImage: orthoBuilder.allData.last!.getImage().cgImage!)
//        var transformation = translator.handleImageTranslationRequest()
//        transformation.ty = transformation.inverted().ty
//
//        let size =  CGSize(width: 1000, height: 1000)
//        let returnValue:UIImage?
//        let renderer = UIGraphicsImageRenderer(size: size)
//
//        returnValue = renderer.image { context in
//            ///Uncomment to see border
//            //UIColor.darkGray.setStroke()
//            //context.stroke(renderer.format.bounds)
//
//
//            orthoBuilder.allData[0].getImage().draw(at: CGPoint(x:100,y:100))
//            orthoBuilder.allData.last!.getImage().draw(at: CGPoint(x:100,y:100).applying(transformation) )
//
//
//        }
//
//        imageView.image = returnValue
        
        // Do any additional setup after loading the view.
    }
    
    
    func configureImageData(imagePath:String) {
        if let path = Bundle.main.resourcePath {
            let imagePath = path + imagePath
            let url = URL(fileURLWithPath: imagePath)
            let fileManager = FileManager.default
            let properties = [URLResourceKey.localizedNameKey,URLResourceKey.creationDateKey, URLResourceKey.localizedTypeDescriptionKey]
            do {
                let imageURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: properties, options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                
                print(imageURLs.count)
                for imageURL in imageURLs {
                    ImageData.all.append( imageURL.path )
                }
                ImageData.all = ImageData.all.sorted {$0.localizedStandardCompare($1) == .orderedAscending} // Sorts images in ascending order
                
            } catch let error  {
                print(error)
            }
        }

        
    }



}
