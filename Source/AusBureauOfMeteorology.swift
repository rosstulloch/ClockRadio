//
//  AusBureauOfMeteorology.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 7/3/20.
//  Copyright © 2020 Ross Tulloch. All rights reserved.
//

import Foundation
import UIKit

//
//  Scrapes weather details from http://www.bom.gov.au.
//

class AusBureauOfMeteorology : WeatherProvider {
    struct ScrapeArguments {
        let forecastsURL:String
        let observationURL:String
        let observationTable:String
    }

    enum Errors : Error {
        case noData, missingForecast, missingObservation, missingImage
    }

    var delegate:WeatherDelegate? { didSet { checkWeatherRegularly() } }
    var temperature:String = ""
    var fullWeather:String = ""
    var weatherImage:NSUIImage?

    private let scrapeArguments:ScrapeArguments
    private var checkWeatherTimer:Timer? = nil
    private var currentTemp:Double?
    private var sydneyBOMforecast:String?
    private var sydneyBOMforecastMaxC:String?

    init() {
        self.scrapeArguments = Preferences.ausScrapeArguments
    }

    init(_ scrapeArguments:ScrapeArguments ) {
        self.scrapeArguments = scrapeArguments
    }
    
    private func checkWeatherRegularly() {
        self.ausBOMSydneyforecastQuery()
        self.ausBOMSydneyTempQuery()

        self.checkWeatherTimer = self.makeTimerWhichFiresOnMinuteChange(minutes: 10, handler: { [weak self] in
            self?.checkWeatherRegularly()
        })
    }

    private func ausBOMSydneyforecastQuery() {
        let url = URL(string: self.scrapeArguments.forecastsURL)!
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard error == nil else { self.weatherErrorDelegate(error!); return }
            
            do {
                guard let data = data, let html = String(data: data, encoding: .utf8), html.isEmpty == false else {
                    throw Errors.noData
                }
                
                guard let sydneyForcastBlockStart = html.substring(from: "<div class=\"forecast\">") else {
                    throw Errors.missingForecast
                }

                self.sydneyBOMforecast = sydneyForcastBlockStart.substring(from: "<p>", upTo: "</p>")
                self.sydneyBOMforecastMaxC = sydneyForcastBlockStart.substring(from: "<em class=\"max\">", upTo: "</em>")
                

                guard let imageHTML = html.substring(from: "<dd class=\"image\">") else {
                    throw Errors.missingForecast
                }
                
                if let imageURLText = imageHTML.substring(from: "<img src=\"", upTo: "\"") {
                     if let imageURL = URL(string: "http://www.bom.gov.au" + imageURLText ) {
                         self.loadWeatherImage(imageURL)
                     }
                } else {
                    throw Errors.missingImage
                }

                self.updateWeatherStrings()
                self.weatherDidChangeDelegate()
                
            } catch {
                self.weatherErrorDelegate(error)
            }
        }.resume()
    }

    private func ausBOMSydneyTempQuery() {
        let url = URL(string: self.scrapeArguments.observationURL)!
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard error == nil else { self.weatherErrorDelegate(error!); return }
            
            do {
                guard let data = data, let html = String(data: data, encoding: .utf8), html.isEmpty == false else {
                    throw Errors.noData
                }

                guard let sydneyTempText = html.substring(from:self.scrapeArguments.observationTable, upTo: "</td>") else {
                    throw Errors.missingObservation
                }
                guard let sydneyTempC = Double(sydneyTempText) else {
                    throw Errors.missingObservation
                }
                
                self.currentTemp = sydneyTempC

                self.updateWeatherStrings()
                self.weatherDidChangeDelegate()
            } catch {
                self.weatherErrorDelegate(error)
            }
        }.resume()
    }

    private func updateWeatherStrings() {
        if let currentTemp = self.currentTemp {
            self.temperature = String(currentTemp)
        } else {
            self.temperature = ""
        }
        
        let forecastText = self.sydneyBOMforecast ?? ""
        let maxC = self.sydneyBOMforecastMaxC ?? ""
        fullWeather = "\(self.temperature) / \(maxC). \(forecastText)"
    }

    private func loadWeatherImage(_ url:URL ) {
        URLSession.shared.dataTask(with:URLRequest(url: url)) { data, response, error in
            guard let data = data else { return }
            
            self.weatherImage = UIImage(data: data)?.changeWhiteColorTransparent()
            self.weatherDidChangeDelegate()
        }.resume()
    }

}

