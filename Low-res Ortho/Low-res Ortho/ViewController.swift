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
        
        configureImageData(imagePath: "/Images/Set 6")

        let orthoBuilder = OrthoImageBuilder(pathArray: ImageData.all)
        orthoBuilder.build()
        imageView.image = orthoBuilder.createImage()

        
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
