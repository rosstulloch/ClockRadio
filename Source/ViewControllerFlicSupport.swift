//
//  ViewControllerFlicSupport.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 7/3/20.
//  Copyright © 2020 Ross Tulloch. All rights reserved.
//

import Foundation
import fliclib

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
                    case .hold: self.leftClickDouble(self)
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
                    case .doubleClick: break
                    case .hold: self.rightClickDouble(self)
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




