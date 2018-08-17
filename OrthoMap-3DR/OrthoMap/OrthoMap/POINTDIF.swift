//
//  File.swift
//  OrthoMap
//
//  Created by Andre on 7/27/18.
//  Copyright © 2018 3DRobotics. All rights reserved.
//

import Foundation


struct POINTDIF {
    
    static var allDiffs:[Double] = []
    static var difference:Double?
    
    static func getMedianDifference() -> Double? {
        return difference
    }
    
    
    static func calcMedianDiff() -> Double  {

        let midIndex:Int = Int( ceil( Double( allDiffs.count ) - 1.0) / 2.0 )
        allDiffs.sort()
        
        return allDiffs[midIndex]
    }
    
    
    
    
    
}
