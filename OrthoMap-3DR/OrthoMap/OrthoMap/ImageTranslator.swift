//
//  TranslatorV2.swift
//  Low-res Ortho
//
//  Created by Andre on 7/2/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation
import UIKit
import Vision

class ImageTranslator {
    
    let referenceImage: CGImage! // Reference image is used by floatingImage for positioning reference
    let floatingImage: CGImage! // Second or floating image
    var imageTranslationRequest: VNTranslationalImageRegistrationRequest! // Vision image translation class\
    let vnImage = VNSequenceRequestHandler() // Allows performing translations
    var alignmentTransform:CGAffineTransform?
    
    init(referenceImage: CGImage, floatingImage: CGImage) {
        self.referenceImage = referenceImage
        self.floatingImage = floatingImage
        self.imageTranslationRequest = VNTranslationalImageRegistrationRequest(targetedCGImage: floatingImage, completionHandler: nil) //Sets target image
    }
    
    func handleImageTranslationRequest() -> CGAffineTransform {
        try? vnImage.perform([ imageTranslationRequest ], on: referenceImage) // performing translation request on referenceImage
        if let results = imageTranslationRequest.results as? [VNImageTranslationAlignmentObservation] { // translation is returned based off the ref
            results.forEach { result in
                alignmentTransform = result.alignmentTransform
                alignmentTransform!.ty = result.alignmentTransform.inverted().ty
            }
        }
        return alignmentTransform!
    }
    

    
}



