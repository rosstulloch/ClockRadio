//
//  Preferences.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 6/10/17.
//  Copyright © 2017 Ross Tulloch. All rights reserved.
//

import Foundation

struct Preferences {

    static let radarUrl = URL(string: "http://www.bom.gov.au/radar/IDR714.gif")!

    static let alarmHour:Int? = 6       // Set to nil to deactivate alarm.
    static let alarmMinutes:Int? = 30
    
    static let nightTime = [20,21,22,23,0,1,2,3,4,5]
    static let morning = (6...9)
    
    static var weatherProvider:WeatherProvider {
      //  AusBureauOfMeteorology()
        /* or */
        OpenWeather(city: "Sydney,au", apiKey: OpenWeatherAPIKey)
    }
    
    static var ausScrapeArguments:AusBureauOfMeteorology.ScrapeArguments {
        AusBureauOfMeteorology.ScrapeArguments( forecastsURL: "http://www.bom.gov.au/nsw/forecasts/sydney.shtml",
                                                observationURL: "http://www.bom.gov.au/nsw/observations/sydney.shtml",
                                                observationTable: "<td headers=\"tSYDNEY-tmp tSYDNEY-station-sydney-observatory-hill\">" )
    }
}
