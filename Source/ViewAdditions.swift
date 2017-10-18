//  UIViewAdditions.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 15/09/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation
import UIKit


extension UIView
{
    
    func positionHorizontallyCentered() {
        self.sizeToFit()
        self.frame.origin.x = (self.superview!.frame.width/2) - (self.frame.width/2)
    }
    
    func positionDownByThird( _ fraction:Int = 1 ) {
        let third = self.superview!.frame.height / 3
        self.frame.origin.y = third - (self.frame.height/2)
    }
    
    func setWidth( _ width:CGFloat ) {
        self.frame.size.width = width
    }

    func debugBorder() {
        #if DEBUG
        #if true
        self.layer.borderColor = UIColor.green.cgColor
        self.layer.borderWidth = 2.0
        #endif
        #endif
    }
}

