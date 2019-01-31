//
//  OrthoRatio.swift
//  Low-res Ortho
//
//  Created by Andre on 7/12/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation

struct AverageRatio {
    
    static var xRatio:Double = 0
    static var yRatio:Double = 0
    
    static var xStack:Double = 0
    static var yStack:Double = 0
        
    
    static func addXRatio(_ xRatio:Double ) {
        AverageRatio.xStack += xRatio
        
    }
    
    static func addYRatio(_ yRatio:Double ) {
        AverageRatio.yStack += yRatio
    }
    
    static func calcAverageXRatio(index:Int) {
        if index != 0 {
            AverageRatio.xRatio = AverageRatio.xStack / Double( index )
        }
        else {
            AverageRatio.xRatio = AverageRatio.xStack
        }
    }
    
    static func calcAverageYRatio(index:Int) {
        if index != 0 {
            AverageRatio.yRatio = AverageRatio.yStack / Double( index )
        }
        else {
            AverageRatio.yRatio = AverageRatio.yStack
        }
    }
    
    static func getRatio() -> (xRatio:Double,yRatio:Double) {
        return (xRatio:xRatio,yRatio:yRatio)
    }
    
    
    
}
