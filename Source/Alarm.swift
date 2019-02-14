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
    private var alarm:Timer?
    
    init() {
        self.setupAlarm()

        NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: nil) { [weak self] notification in
            self?.setupAlarm()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] notification in
            self?.setupAlarm()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] notification in
            self?.alarm?.invalidate()
        }
    }
    
    deinit {
        self.alarm?.invalidate()
    }
    
    private func setupAlarm() {
        guard let alarmHour = Preferences.alarmHour, let alarmMinutes = Preferences.alarmMinutes else {
            return
        }
    
        let nowComponents = Calendar.current.dateComponents([.timeZone,.calendar,.minute,.year,.month,.day], from: Date())
        
        var newComponents = DateComponents()
        newComponents.year = nowComponents.year
        newComponents.month = nowComponents.month
        newComponents.day = nowComponents.day
        newComponents.hour = alarmHour
        newComponents.minute = alarmMinutes
        
        if var timerWillFireAt = Calendar.current.date(from: newComponents) {
            if timerWillFireAt.timeIntervalSinceNow < 0 {
                timerWillFireAt = timerWillFireAt.addingTimeInterval(60*60*24)
            }
            
            let secondsInTheFuture = timerWillFireAt.timeIntervalSinceNow
            if secondsInTheFuture > 0 {
                self.alarm = Timer.scheduledTimer(withTimeInterval: secondsInTheFuture, repeats: false) { [weak self] timer in
                    self?.delegate?.alarmDidFire()
                    self?.setupAlarm()
                }
            }
        }
    }

}
