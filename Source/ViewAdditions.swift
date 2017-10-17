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
/*    func labelWithTag( _ tag:Int ) -> UILabel {
        return self.viewWithTag(tag) as! UILabel
    }   */
    
/*    func positionHorizontallyOffsetFrom( _ otherView:UIView, space:CGFloat ) {
        self.frame.origin.x = otherView.frame.origin.x + space
    }   */
    
 //   func positionFromTop( space:CGFloat ) {
 //       self.frame.origin.y = self.superview!.frame.origin
  //  }
    
    func positionHorizontallyCentered() {
        self.sizeToFit()
        self.frame.origin.x = (self.superview!.frame.width/2) - (self.frame.width/2)
    }

/*    func positionVerticallyCentered() {
        self.sizeToFit()
        self.frame.origin.y = (self.superview!.frame.height/2) - (self.frame.height/2)
    }   */

 /*   func positionAtBottom() {
        self.sizeToFit()
        self.frame.origin.y = self.superview!.frame.height - self.frame.height
    }   */
    
/*    func positionBelow( _ otherView:UIView, space:CGFloat = 0 ) {
        self.sizeToFit()
        self.frame.origin.y = otherView.frame.origin.y + otherView.frame.height + space
    }
    
    func positionLeftJustified() {
        self.frame.origin.x = 0
    }   */
    
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

