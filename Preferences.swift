//
//  Preferences.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 6/10/17.
//  Copyright © 2017 Ross Tulloch. All rights reserved.
//

import Foundation

struct Preferences {

    static let forecastUrl = URL(string: "http://api.wunderground.com/api/" + weatherUndergroundKey + "/forecast/q/AU/Sydney.json")!
    static let currentUrl = URL(string: "http://api.wunderground.com/api/" + weatherUndergroundKey + "/conditions/q/AU/Sydney.json")!
    static let radarUrl = URL(string: "http://www.bom.gov.au/radar/IDR714.gif")!

    static let alarmHour:Int? = 6       // Set to nil to deactivate alarm.
    static let alarmMinutes:Int? = 50
    
    static let nightTime = [20,21,22,23,0,1,2,3,4,5]
    static let morning = (6...9)
    
}
