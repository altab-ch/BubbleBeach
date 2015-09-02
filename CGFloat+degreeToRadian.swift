//
//  CGFloat+degreeToRadian.swift
//  BubbleBeach
//
//  Created by Mathieu Knecht on 21.07.15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

import Foundation
extension CGFloat {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}