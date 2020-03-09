//
//  ViewController.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 20/11/16.
//  Copyright © 2016 Ross Tulloch. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController, UIApplicationDelegate {
    @IBOutlet weak var status:UITextField!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var timeBehind: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var bottomRightImage: UIImageView!
    @IBOutlet weak var bottomRightLabel: UILabel!
    @IBOutlet weak var belowText: UILabel!

    var albumImage:UIImage? = nil
    var albumText:String? = nil
    var lastTimeString = ""

	let clock = ClockController()
    let radio = RadioController()
    let sleep = SleepController()
    var weather = Preferences.weatherProvider
    let alarm = AlarmController()

    var watchingForAlarmPlayStationError = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black

        self.radio.delegate = self
        self.alarm.delegate = self
        self.sleep.delegate = self
        self.clock.delegate = self
        self.clock.alarm = self.alarm
        
        self.weather.delegate = self
    
        Timer.scheduledTimer(timeInterval:60.0, target: self, selector:#selector(ViewController.flipBetweenWeatherAndAlbumDetails(timer:)),
                             userInfo: nil, repeats: true).tolerance = 1.0
        
    #if IOS_SIMULATOR
    #else
        setupFlic()
    #endif
        
        addGestures()
    }
    
    private func addGestures() {

        func addSwipe(_ direction:UISwipeGestureRecognizer.Direction, action: Selector ) {
            let swipe = UISwipeGestureRecognizer(target: self, action: action)
            swipe.direction = direction
            self.view.addGestureRecognizer(swipe)
        }

        addSwipe( .right, action: #selector(rightClickOnce(_:)))
        addSwipe( .left, action: #selector(leftClickOnce(_:)))
        addSwipe( .up, action: #selector(middleOnce(_:)))
        addSwipe( .down, action: #selector(middleHold(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        animateTime()
    }

    @objc func flipBetweenWeatherAndAlbumDetails( timer:Timer ) {
        guard self.albumText != nil, self.albumImage != nil else {
            return
        }
        self.bottomRightLabel.text = self.albumText
        self.bottomRightImage.image = self.albumImage
        
        GCDAdditions.perform(afterDelay:30.0) {
            self.weatherDidChange(self.weather)
        }
    }
}


// MARK:- Buttons
extension ViewController {

    @IBAction func leftClickOnce(_ sender: Any) {
        self.radio.playNextStation()
    }

    @IBAction func leftClickDouble(_ sender: Any) {
        self.radio.playLeftButtonStation()
    }

    @IBAction func rightClickOnce(_ sender: Any) {
        self.radio.playPreviousStation()
    }

    @IBAction func rightClickDouble(_ sender: Any) {
        self.radio.playRightButtonStation()
    }

    @IBAction func middleOnce(_ sender: Any) {
        self.sleepButton()
    }

    @IBAction func middleHold(_ sender: Any) {
        if self.radio.isPlayingOrConnecting {
            self.off()
        }
    }

    func off() {
        self.showBigInfo(text: "OFF")
        self.sleep.clear()
        self.radio.stopPlaying()
    }

}


// MARK:- Radio
extension ViewController : RadioControllerDelegate {

    func startedPlayingStation() {
        if self.sleep.willSleep == false {
            self.sleep.setSleepTimerForLongTime()
        }
    }
    
    func stoppedPlayingStation() {
        self.clearAlbumArt()
    }

    func clearAlbumArt() {
        self.albumImage = nil
        self.albumText = nil
    }
    
    func showStationName( text:String, positionInfoString:String? )  {
        self.showBigInfo(text: text)
        
        if let positionInfoString = positionInfoString {
            self.belowText.text = positionInfoString
            GCDAdditions.cancelPreviousThenPerform(afterDelay: 5.0) {
                self.belowText.text = ""
            }
        }
    }

    func showBigInfo( text:String ) {
        guard text.count > 0 else {
            return
        }
    
        // Hide the time and show the text...
        self.info.text = text
        self.info.isHidden = false
        self.time.isHidden = true
        self.timeBehind.isHidden = true
    
        // After a delay, show the time and hide the text...
        GCDAdditions.cancelPreviousThenPerform(afterDelay: 4) {
            self.info.isHidden = true
            self.time.isHidden = false
            self.timeBehind.isHidden = false
        }
    }

    func showStationConnectionStatus( text:String ) {
        self.status?.text = text
    }

    func couldntConnectToStation() {
        if self.watchingForAlarmPlayStationError {
            self.watchingForAlarmPlayStationError = false
            self.radio.playCantConnectStation()
        }
    }

    func handleiTunesRecordForCurrentTrack(_ itr:iTunesStoreRecord ) {
        print(itr)

        self.albumText = "\(itr.trackCensoredName ?? "")\n\(itr.artistName ?? "")"
        self.bottomRightLabel.text = self.albumText

        itr.fetchArtwork { image, error in
            guard let image = image, error == nil else {
                return
            }
            self.albumImage = image
            self.bottomRightImage.image = self.albumImage
        }
    }

}

// MARK:- Time
extension ViewController : ClockControllerDelegate {

    func clockTick() {
        let ts = TimeString()
        self.time.attributedText = ts.attributed(self.time.font.pointSize, colonColor:self.time.textColor)
        self.timeBehind.attributedText = ts.attributed(self.time.font.pointSize, colonColor:UIColor.clear)
    }
    
    func animateTime() {
        let raw = UIView.KeyframeAnimationOptions.repeat.rawValue |
                  UIView.AnimationOptions.autoreverse.rawValue
        
        UIView.animateKeyframes(withDuration: 0.75, delay: 0, options: UIView.KeyframeAnimationOptions(rawValue: raw), animations: {
                self.time.alpha = 0.0
                self.timeBehind.alpha = 1.0
            }, completion:nil)
    }
    
}

// MARK:- Sleep
extension ViewController : SleepControllerDelegate {

    func shouldBePlaying() {
        if self.radio.isPlayingOrConnecting == false {
            self.radio.playLastStation()
        }
    }

    func shouldStopPlaying() {
        self.off()
    }

    func sleepStateChanged() {
    }

    func sleepButton() {
        self.sleep.nextSleepChoice()
        self.showBigInfo(text:self.sleep.currentStateDescription )
    }
    
}

// MARK:- Alarm
extension ViewController : AlarmControllerDelegate {

    func alarmDidFire() {
        self.sleep.clear()
        self.sleep.setSleepTimerForLongTime()
        self.watchingForAlarmPlayStationError = true
        self.radio.playAlarmStation()
    }

}

// MARK:- Weather
extension ViewController : WeatherDelegate {

    var isNight:Bool {
        if let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour {
            return Preferences.nightTime.contains(currentHour)
        }
        return false
    }

    var isWakeUpTime:Bool {
        if let currentHour = Calendar.current.dateComponents([.hour], from: Date()).hour {
            return Preferences.morning.contains(currentHour)
        }
        return false
    }

    func weatherDidChange(_ wp:WeatherProvider ) {

        if self.isNight == true {
            self.bottomRightLabel.text = self.weather.temperature
        } else {
            self.bottomRightLabel.text = self.weather.fullWeather
        }
        
    #if IOS_SIMULATOR
        self.bottomRightImage.image = self.weather.weatherImage
    #else
        if self.isWakeUpTime {
            // Show radar in the morning...
            self.bottomRightImage.image = self.weather.weatherImage
        } else {
            self.bottomRightImage.image = nil
        }
    #endif
    }
    
    func weatherError(error: Error) {
        #if IOS_SIMULATOR
            ShowErrorAlert(error as NSError)
        #endif
        Debugging.LogError(error as NSError)
    }

}

