//
//  ViewController.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 20/11/16.
//  Copyright © 2016 Ross Tulloch. All rights reserved.
//

import UIKit
import AVFoundation
import fliclib



class ViewController: UIViewController, UIApplicationDelegate {

    @IBOutlet weak var status:UITextField?
    @IBOutlet weak var timeAndDateContainer: UIView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var timeBehind: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var bottomRightImage: UIImageView!
    @IBOutlet weak var bottomRightLabel: UILabel!
    @IBOutlet weak var debugButtonsContainer: UIStackView!
    
    var albumImage:UIImage? = nil
    var albumText:String? = nil
    var lastTimeString = ""

	let clock = ClockController()
    let radio = RadioController()
    let sleep = SleepController()
    let weather = WeatherController()
    let alarm = AlarmController()

    var watchingForAlarmPlayStationError = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view!.backgroundColor = UIColor.black
        self.view.addSubview( self.timeAndDateContainer )

        self.radio.delegate = self
        self.alarm.delegate = self
        self.sleep.delegate = self
        self.clock.delegate = self
        
        
        self.weather.delegate = self
        self.weather.checkWeatherRegularly()
    
        Timer.scheduledTimer(timeInterval:60.0, target: self, selector:#selector(ViewController.flipBetweenWeatherAndAlbumDetails(timer:)),
                             userInfo: nil, repeats: true).tolerance = 1.0
        
    #if IOS_SIMULATOR
    #else
        setupFlic()
        self.debugButtonsContainer.isHidden = true
    #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        animateTime()
    }

    override func viewDidLayoutSubviews() {
        self.info.positionDownByThird()
        layoutTimeSubviews()
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

// MARK: Buttons
extension ViewController {

    @IBAction func leftClickOnce(_ sender: Any) {
        self.radio.playLeftButtonStation()
    }

    @IBAction func rightClickOnce(_ sender: Any) {
        self.radio.playRightButtonStation()
    }

    @IBAction func rightClickDouble(_ sender: Any) {
        self.radio.playNextStation()
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


// MARK: Radio
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
    
    func showStationName( text:String ) {
        self.showBigInfo(text: text)
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

        self.albumText = "\(itr.trackCensoredName)\n\(itr.artistName)"
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

    func layoutTimeSubviews() {
        let rootViewFrame = self.view!.frame
        
        timeAndDateContainer.setWidth( rootViewFrame.width )
        timeAndDateContainer.positionDownByThird()
        info.positionHorizontallyCentered()
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

    func weatherDidChange(_ wc:WeatherController) {

        if self.isNight {
            // Just show temp...
            if let tempC = self.weather.current?.currentC {
                self.bottomRightLabel.text = String(describing: tempC) + "c"
            }
        } else {
            // Show long description....
            self.bottomRightLabel.text = self.weather.description
        }
        
        if self.isWakeUpTime {
            // Show radar in the morning...
            self.bottomRightImage.image = self.weather.radarImage
        } else {
            self.bottomRightImage.image = nil
        }
    }
    
    func weatherError(_ wc:WeatherController, error: NSError) {
   //     ShowErrorAlert(error)
        // Showing errors via an alert is a poor idea since it will block the hide UI til dismissed.
        // Just log the errors.
        Debugging.LogError(error)
    }

}

// MARK:- Flic
#if IOS_SIMULATOR
#else
extension ViewController : SCLFlicManagerDelegate, SCLFlicButtonDelegate {

    fileprivate enum FlicErrors : Int, ErrorsHelper {
        var domain:String { return "Flic" }
        var code:Int { return self.rawValue }
        case unknownButtonName
        var description:String {
            switch(self) {
                case .unknownButtonName: return "Unknown button name:"
            }
        }
        var suggestion: String? {
            return "Valid button names are: left, middle and right. They're case insensitive."
        }
    }

    enum FlicAction {
        case click, doubleClick, hold
    }

    func setupFlic() {
        SCLFlicManager.configure(with: self, defaultButtonDelegate: self, appID:"0d386b2b-ad9c-4d6f-ae88-781741e2edce", appSecret:"2435924c-b8b0-4e71-9589-b9ff083893b5", backgroundExecution: false)
    }
    
    func handlePress( ofButton button: SCLFlicButton, action:FlicAction ) {
    
        switch button.userAssignedName.lowercased() {
            case "left":
                switch action {
                    case .click: self.leftClickOnce(self)
                    case .doubleClick: break
                    case .hold: break
                }
            case "middle":
                switch action {
                    case .click: self.middleOnce(self)
                    case .doubleClick: break
                    case .hold: self.middleHold(self)
                }
            case "right":
                switch action {
                    case .click: self.rightClickOnce(self)
                    case .doubleClick: self.rightClickDouble(self)
                    case .hold: break
                }
            default:
                ShowErrorAlert(FlicErrors.unknownButtonName.nserror(), extraMessage: "\(button.userAssignedName).")
        }
    }

    @IBAction public func grabFlicAction(_ sender: AnyObject? ) {
        SCLFlicManager.shared()?.grabFlicFromFlicApp(withCallbackUrlScheme: "rcr")
    }
    
    func flicManager(_ manager: SCLFlicManager, didGrab button: SCLFlicButton?, withError error: Error?) {
    }
    
    func flicButton(_ button: SCLFlicButton, didReceiveButtonClick queued: Bool, age: Int) {
        button.triggerBehavior = .clickAndDoubleClickAndHold // Must be a better place to set this?
        guard queued == false else {
            return
        }
        handlePress( ofButton:button, action:.click )
    }

    func flicButton(_ button: SCLFlicButton, didReceiveButtonDoubleClick queued: Bool, age: Int) {
        guard queued == false else {
            return
        }
        handlePress( ofButton:button, action:.doubleClick )
    }

    func flicButton(_ button: SCLFlicButton, didReceiveButtonHold queued: Bool, age: Int) {
        guard queued == false else {
            return
        }
        handlePress( ofButton:button, action:.hold )
    }
}
#endif




