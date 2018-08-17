//
//  OrthoRatio.swift
//  Low-res Ortho
//
//  Created by Andre on 7/12/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation

struct ORTHORATIO {
    
    
    static var numImages:Int = 10
    static var medianIndex:Int?
    static var allRatios:[(xRatio:Double,yRatio:Double)] = []
    static var finalRatio:(xRatio:Double,yRatio:Double)?
    
    static func getRatio() -> (xRatio:Double,yRatio:Double)?  {
        return finalRatio
    }
    
    
    static func calcMedianRatios() -> (xRatio:Double,yRatio:Double)  {
        
        var allXRatios:[Double] = []
        var allYRatios:[Double] = []
        let midIndex:Int = Int( floor( Double( allRatios.count ) - 1.0) / 2.0 )
        for ratio in allRatios {
            allXRatios.append( abs(ratio.xRatio) )
            allYRatios.append(abs(ratio.yRatio) )
        }
        
        allXRatios.sort()
        allYRatios.sort()
    
        
        medianIndex = midIndex
        
        return (xRatio:allXRatios[midIndex],yRatio:allYRatios[midIndex])
    }
    
}
