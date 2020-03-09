//
//  OpenWeather.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 7/3/20.
//  Copyright © 2020 Ross Tulloch. All rights reserved.
//

import Foundation


class OpenWeather : WeatherProvider {
    public var delegate: WeatherDelegate? { didSet { checkWeatherRegularly() } }
    public var temperature: String = ""
    public var fullWeather: String = ""
    public var weatherImage: NSUIImage?

    private var checkWeatherTimer:Timer?
    private var current:OWCurrent?
    private var forecast:OWForecast?

    let cityString:String
    let apiKey:String

    
    init( city:String, apiKey:String ) {
        self.cityString = city
        self.apiKey = apiKey
    }
    
    private func checkWeatherRegularly() {
        self.currentQuery()
        
        self.checkWeatherTimer = self.makeTimerWhichFiresOnMinuteChange(minutes: 10, handler: { [weak self] in
            self?.checkWeatherRegularly()
        })
    }

    private func currentQuery() {
        let url = URL(string: "http://api.openweathermap.org/data/2.5/weather?units=metric&q=\(cityString)&appid="+apiKey )!
        
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard let data = data else { return }
            
            do {
                self.current = try JSONDecoder().decode(OWCurrent.self, from: data)
                self.updateWeatherStrings()
                self.weatherDidChangeDelegate()
            } catch (let error as NSError) {
                self.weatherErrorDelegate(error)
            }
        }.resume()
    }

    private func updateWeatherStrings() {
        self.temperature = ""
        
        if let temp = self.current?.main.temp {
            self.temperature = "\(temp)"
        }

        if let temp_max = self.current?.main.temp_max {
            self.temperature += " / \(temp_max)"
        }

        self.fullWeather = "\(self.temperature)"
        
        if let description = self.current?.weather.first?.description {
            self.fullWeather += " \(description)"
        }
    }
    
}


// JSON
fileprivate struct OWCurrent : Codable {
    struct WeatherDescription : Codable {
        let description:String
    }
    struct Main : Codable {
        let temp:Double
        let feels_like:Double
        let temp_min:Double
        let temp_max:Double
        let pressure:Int
        let humidity:Int
    }
    
    let weather:[WeatherDescription]
    let main:Main
}

fileprivate struct OWForecast : Codable {
    struct ListElement : Codable {
        let dt:Int
        let main:Main
    }
    struct Main : Codable {
        let temp:Double
        let feels_like:Double
        let temp_min:Double
        let temp_max:Double
        let pressure:Int
        let humidity:Int
    }
    
    let message:Int
    let list:[ListElement]
}
