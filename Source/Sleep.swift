//
//  Sleep.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 20/09/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation
import AVFoundation

fileprivate enum SleepState:Int {
    case off, fifteenMinutes, thrityMinutes, fortyFiveMinutes, oneHour, oneAndAHalfHours
    
    var seconds:Double {
        switch self {
            case .off: return 0
            case .fifteenMinutes: return 15*60
            case .thrityMinutes: return 30*60
            case .fortyFiveMinutes: return 45*60
            case .oneHour: return 60*60
            case .oneAndAHalfHours: return 90*60
        }
    }
    
    var next:SleepState {
        if let nextValid = SleepState(rawValue: self.rawValue + 1) {
            return nextValid
        } else {
            return .off
        }
    }
    
    var description:String {
        guard self != .off else {
            return "OFF"
        }
        let minutes = Int(self.seconds / 60)
        return "\(minutes)"
    }
}

protocol SleepControllerDelegate {
    func shouldBePlaying()
    func shouldStopPlaying()
}

class SleepController
{
    var delegate:SleepControllerDelegate?
    private var state:SleepState = .off
    private var sleepTimer:Timer?
    private var sleepPipsTimer:Timer?
    var currentStateDescription:String { return self.state.description }
    var willSleep:Bool { return self.sleepTimer != nil }
    
    func setSleepTimerForLongTime() {
        self.state = .oneAndAHalfHours
        self.changedSleepState()
    }

    func nextSleepChoice() {
        GCDAdditions.cancelPreviousThenPerform(afterDelay: 15) {
            self.state = .off
        }
        self.state = state.next
        self.changedSleepState()
    }

    func clear() {
        self.state = .off
        self.cancelSleepTimer()
    }

    private func cancelSleepTimer() {
        self.sleepTimer?.invalidate()
        self.sleepTimer = nil
        self.self.sleepPipsTimer?.invalidate()
        self.self.sleepPipsTimer = nil
    }
    
    private func recreateSleepTimer() {
        self.cancelSleepTimer()
        
        self.sleepPipsTimer = Timer.scheduledTimer(withTimeInterval: state.seconds - 7, repeats: false) { [weak self] timer in
            self?.playPips()
        }
        
        self.sleepTimer = Timer.scheduledTimer(withTimeInterval: state.seconds, repeats: false) { [weak self] timer in
            self?.sleepTimer = nil
            self?.delegate?.shouldStopPlaying()
        }
    }
    
    private func changedSleepState() {
        if self.state == .off {
            cancelSleepTimer()
            delegate?.shouldStopPlaying()
        } else {
            recreateSleepTimer()
            delegate?.shouldBePlaying()
        }
    }
    
    private func playPips() {
        let tink:SystemSoundID = 1057
        
        AudioServicesPlaySystemSound(tink)
        GCDAdditions.perform(afterDelay: 0.5) {
            AudioServicesPlaySystemSound(tink)
            GCDAdditions.perform(afterDelay: 0.5) {
                AudioServicesPlaySystemSound(tink)
            }
        }
    }

}


