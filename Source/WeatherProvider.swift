//
//  WeatherProvider.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 7/3/20.
//  Copyright © 2020 Ross Tulloch. All rights reserved.
//

import Foundation


protocol WeatherDelegate {
    func weatherDidChange(_ wp:WeatherProvider )
    func weatherError(error:Error)
}

protocol WeatherProvider {
    var delegate:WeatherDelegate? { get set }
    var temperature:String { get }
    var fullWeather:String { get }
    var weatherImage:NSUIImage? { get }
}

extension WeatherProvider {

    func makeTimerWhichFiresOnMinuteChange( minutes:TimeInterval, handler:@escaping ()->Void ) -> Timer? {
        // Make sure timer fires every N minutes from just before the hour.
        var minutesTillNextInterval:TimeInterval = minutes
        if let currentMinute = Calendar.current.dateComponents([.minute], from: Date()).minute {
            let minutesInCurrentHourRemaining = TimeInterval(60 - currentMinute)
            if minutesInCurrentHourRemaining < minutesTillNextInterval {
                minutesTillNextInterval = minutesInCurrentHourRemaining
            }
        }
        return Timer.scheduledTimer(withTimeInterval: minutesTillNextInterval*60, repeats: false) { timer in
            handler()
        }
    }

    func weatherDidChangeDelegate() {
        OperationQueue.main.addOperation {
            self.delegate?.weatherDidChange(self)
        }
    }

    func weatherErrorDelegate(_ error:Error) {
        DispatchQueue.main.async {
            self.delegate!.weatherError(error: error)
        }
    }


}
