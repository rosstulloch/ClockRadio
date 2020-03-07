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

    func weatherDidChange() {
     //   XCTAssert(wc.forecast?.hiC != nil)
        expect!.fulfill()
    }
    
    func weatherError(error: NSError) {
    //    XCTAssert(error == nil)
        expect!.fulfill()
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
        
    //    let wc = WeatherController()
    //    wc.delegate = self
        
    //    wc.forecastQuery(Preferences.forecastUrl)
   //     waitForExpectations(timeout: 10)

     //   expect = expectation(description:"weather will NOT be downloaded.")
     //   WeatherController().forecastQuery(URL(string: "http://apple.com")!)
     //   waitForExpectations(timeout: 10)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
