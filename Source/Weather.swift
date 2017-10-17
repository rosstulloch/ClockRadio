//
//  Weather.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 21/4/17.
//  Copyright © 2017 Ross Tulloch. All rights reserved.
//

import Foundation
import UIKit

protocol WeatherDelegate {
    func weatherDidChange(_ wc:WeatherController)
    func weatherError(_ wc:WeatherController, error:NSError)
}

///// JSON blobs from WeatherUnderground...
fileprivate struct ForecastJSON:Decodable {
    var forecast:ForecastConatiner
    
    struct ForecastConatiner:Decodable {
        var simpleforecast:SimpleforecastContainer
        var txt_forecast:Txt_forecastContainer

        struct SimpleforecastContainer:Decodable {
            var forecastday:[ForecastdayContainer]

            struct ForecastdayContainer:Decodable {
                var high:Temps
                var low:Temps

                struct Temps:Decodable {
                    var celsius:String
                    var fahrenheit:String
                }
            }
        }
        
        struct Txt_forecastContainer:Decodable {
            var forecastday:[TextForecastdayContainer]
            
            struct TextForecastdayContainer:Decodable {
                var fcttext:String
                var fcttext_metric:String
            }
        }
    }
}

fileprivate struct CurrentJSON:Decodable {
    var current_observation:CurrentObservation
    
    struct CurrentObservation:Decodable {
        var temp_c:Double
        var temp_f:Double
        var icon_url:String
    }
}
/////////////////////

class WeatherController {
    var delegate:WeatherDelegate?
    private var checkWeatherTimer:Timer?
    private(set) var current:Current?
    private(set) var forecast:Forecast?
    private(set) var radarImage:NSUIImage?
    private let weatherUpdateTimeInMinutes:TimeInterval = 20
    
    private var delegateWarn:WeatherDelegate? {
        if self.delegate == nil { Debugging.LogError(message: "WeatherController doesn't have a delegate.") }
        return self.delegate
    }
    
    enum JSONErrors : Error {
        case missingField(msg:String)
    }

    struct Current {
        let currentC:Double
        let currentF:Double
        
        fileprivate init (json:CurrentJSON) throws {
            self.currentC = json.current_observation.temp_c
            self.currentF = json.current_observation.temp_f
        }
    }
    
    struct Forecast {
        let hiC:String
        let lowC:String
        let hiF:String
        let lowF:String
        let textF:String
        let textC:String

        fileprivate init (json:ForecastJSON) throws {
            guard let firstForecast = json.forecast.simpleforecast.forecastday.first else {
                throw JSONErrors.missingField(msg:"simpleforecast forecastday is empty.")
            }
            self.hiC = firstForecast.high.celsius
            self.hiF = firstForecast.high.fahrenheit
            self.lowC = firstForecast.low.celsius
            self.lowF = firstForecast.low.celsius

            guard let firstForecastText = json.forecast.txt_forecast.forecastday.first else {
                throw JSONErrors.missingField(msg:"txt_forecast forecastday is empty.")
            }
            self.textF = firstForecastText.fcttext
            self.textC = firstForecastText.fcttext_metric
        }
    }
    
    deinit {
        self.checkWeatherTimer?.invalidate()
    }

    func checkWeatherRegularly() {
        self.downloadWeather()
        self.setupCheckWeatherTimer()
    }
    
    private func setupCheckWeatherTimer() {
        // Make sure timer fires every 20 minutes from just before the hour.
        var minutesTillNextInterval:TimeInterval = self.weatherUpdateTimeInMinutes
        if let currentMinute = Calendar.current.dateComponents([.minute], from: Date()).minute {
            let minutesInCurrentHourRemaining = TimeInterval(60 - currentMinute)
            if minutesInCurrentHourRemaining < minutesTillNextInterval {
                minutesTillNextInterval = minutesInCurrentHourRemaining
            }
        }
        self.checkWeatherTimer = Timer.scheduledTimer(withTimeInterval: minutesTillNextInterval*60, repeats: false) { [weak self] timer in
            self?.checkWeatherRegularly()
        }
    }

    private func downloadWeather() {
        self.forecastQuery(Preferences.forecastUrl)
        self.currentQuery(Preferences.currentUrl)
        self.loadRadar(Preferences.radarUrl)
    }
    
    var description:String {
        let tempC:String
        if let _temp = self.current?.currentC {
            tempC = String(_temp) + "c. "
        } else {
            tempC = ""
        }
        let forecastTextC = self.forecast?.textC ?? ""
        let weatherString = "\(tempC) \(forecastTextC)"
        return weatherString
    }
    
    internal func forecastQuery(_ url:URL ) {
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard let data = data else {
                return
            }

            do {
                let forecast = try JSONDecoder().decode(ForecastJSON.self, from: data as Data)
                self.forecast = try Forecast(json:forecast)
                self.callWeatherDidChange()
                
            } catch (let error as NSError) {
                self.callWeatherError(error: error)
            }
        }.resume()
    }
    
    private func currentQuery(_ url:URL ) {
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard let data = data else {
                return
            }

            do {
                let current = try JSONDecoder().decode(CurrentJSON.self, from: data as Data)
                self.current = try Current(json:current)
                self.callWeatherDidChange()
                
            } catch (let error as NSError) {
                self.callWeatherError(error: error)
            }
            
        }.resume()
    }
    
    func callWeatherError(error:NSError) {
        DispatchQueue.main.async {
            self.delegateWarn?.weatherError(self, error: error)
        }
    }
    
    func callWeatherDidChange() {
        DispatchQueue.main.async {
            self.delegateWarn?.weatherDidChange(self)
        }
    }

    private func loadRadar(_ url:URL ) {
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard let data = data else {
                return
            }
            self.radarImage = UIImage(data: data)
            self.callWeatherDidChange()
        }.resume()
    }

}
