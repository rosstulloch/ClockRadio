//
//  ClockRadioTerminalTests.swift
//  ClockRadioTerminalTests
//
//  Created by Ross Tulloch on 20/11/16.
//  Copyright © 2016 Ross Tulloch. All rights reserved.
//

import XCTest
@testable import ClockRadioTerminal

class ClockRadioTerminalTests: XCTestCase, WeatherDelegate {

    var expect:XCTestExpectation?
    var noErrorsExpect:XCTestExpectation?

    func weatherDidChange(_ wp: WeatherProvider) {
        
        if wp.fullWeather.isEmpty == false && wp.temperature.isEmpty == false {
            expect!.fulfill()
        }
        
      //  XCTAssert(wc.forecast?.hiC != nil)
    }
    
    func weatherError(error: Error) {
        noErrorsExpect!.fulfill()
    }
    

  //  let weather = WeatherController()
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
      //  self.weather()
    }
    
    func testWeather() {
    
        expect = expectation(description:"weather will be downloaded.")
        
        noErrorsExpect = expectation(description:"no errors")
        noErrorsExpect!.isInverted = true

        // AusBureauOfMeteorology
        let args =  AusBureauOfMeteorology.ScrapeArguments( forecastsURL: "http://www.bom.gov.au/nsw/forecasts/sydney.shtml",
                                                            observationURL: "http://www.bom.gov.au/nsw/observations/sydney.shtml",
                                                            observationTable: "<td headers=\"tSYDNEY-tmp tSYDNEY-station-sydney-observatory-hill\">" )

        AusBureauOfMeteorology(args).delegate = self
        
        
        // OpenWeather
        OpenWeather(city: "Sydney,au", apiKey: OpenWeatherAPIKey).delegate = self

        
        expect?.expectedFulfillmentCount = 2

        
        expect!.assertForOverFulfill = false
        waitForExpectations(timeout: 5)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
