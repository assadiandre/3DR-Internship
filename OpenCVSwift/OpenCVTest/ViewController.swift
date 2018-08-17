//
//  ViewController.swift
//  OpenCVTest
//
//  Created by Andre on 8/15/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MainViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let referenceImage = UIImage(named:"VideoFrame-23")
        let floatingImage = UIImage(named:"VideoFrame-25")
        
        
        let opencvAlign = OpenCVImageAlignment()!
        opencvAlign.findHomography(ofReferenceImage: referenceImage, andFloating: floatingImage)
        
        imageView.image = opencvAlign.getImage()

        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func foundHomography() {
        
    }
    


}

