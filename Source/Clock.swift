//
//  ClockModel.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 10/09/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

protocol ClockControllerDelegate {
    func clockTick()
}

class ClockController {
    var delegate:ClockControllerDelegate?
    private var everySecondTimer:Timer?
    
    init() {
        self.everySecondTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            self?.delegate?.clockTick()
        }
        self.everySecondTimer?.tolerance = 0.5
    }
    
    deinit {
        self.everySecondTimer?.invalidate()
    }    
}

struct TimeString
{
    private static let dateFormatter = DateFormatter()
    private static let timeFormatter = DateFormatter()

    let time:String
    
    init () {
        if TimeString.dateFormatter.dateFormat != "EEEEdMMMM" {
            TimeString.dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "EEEEdMMMM", options: 0, locale: Locale.current)
            TimeString.timeFormatter.timeStyle = DateFormatter.Style.short
            TimeString.timeFormatter.dateStyle = DateFormatter.Style.none
            TimeString.timeFormatter.amSymbol = ""
            TimeString.timeFormatter.pmSymbol = ""
        }

        let time = TimeString.timeFormatter.string(from: Date())
        self.time = time.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func lengthOfTimeStringToSeparator(_ string:String ) -> Int? {
        if let range = string.rangeOfCharacter(from: CharacterSet(charactersIn: ":-.")) {
            return string.characters.distance(from: string.startIndex, to: range.lowerBound)
        }
        return nil
    }
 
    func attributed(_ size:CGFloat, colonColor:NSUIColor ) -> NSAttributedString {
        let result = NSMutableAttributedString(string:self.time)
        result.addAttribute(NSFontAttributeName, value:NSUIFont.systemFont(ofSize: size), range:NSMakeRange(0,result.length))
        if let lengthToSeparator = lengthOfTimeStringToSeparator(self.time) {
            result.addAttribute(NSForegroundColorAttributeName, value:colonColor, range:NSMakeRange(lengthToSeparator,1))
        }
        return result
    }
    

}















