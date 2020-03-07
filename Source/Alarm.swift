//
//  Alarm.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 5/10/17.
//  Copyright © 2017 Ross Tulloch. All rights reserved.
//

import UIKit
import Foundation

protocol AlarmControllerDelegate {
    func alarmDidFire()
}

class AlarmController {
    var delegate:AlarmControllerDelegate?
    
    private var timerHasFiredAlready = false
    
    
    public func clockTick() {
         let nowComponents = Calendar.current.dateComponents([.hour,.minute], from: Date())

        if Preferences.alarmHour == nowComponents.hour && Preferences.alarmMinutes == nowComponents.minute {
            if self.timerHasFiredAlready == false {
                self.timerHasFiredAlready = true
                self.delegate?.alarmDidFire()
            }
        } else {
            self.timerHasFiredAlready = false
        }
    }
    
}
