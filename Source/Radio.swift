//
//  Radio.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 3/10/17.
//  Copyright © 2017 Ross Tulloch. All rights reserved.
//

import Foundation
import AVFoundation

fileprivate struct RadioJSON : Decodable {
    var stations:[String:String]
    var defaultStation:String
    var alarmStation:String
    var rightButtonStation:String
    var leftButtonStation:String
}

struct RadioStation {
    let key:String
    let url:URL
    let displayName:String
    
    static func ==(lhs: RadioStation, rhs: RadioStation) -> Bool {
        return lhs.url.path == rhs.url.path
    }
}

enum RadioState {
    case off, connecting, cannotConnect, playing
    
    var description:String {
        switch self {
            case .off: return ""
            case .connecting: return "Connecting..."
            case .cannotConnect: return "Cannot Connect."
            case .playing: return ""
        }
    }
}

fileprivate enum RadioErrors : Int, ErrorsHelper {
    var domain:String { return "Radio" }
    var code:Int { return self.rawValue }

    case stationsAreMissing, backupStationIsMissing, jsonCantBeRead, avPlayerFailed
    
    var description:String {
        switch(self) {
            case .stationsAreMissing: return "Stations.json is missing from bundle or cannot be loaded. Check the build settings."
            case .backupStationIsMissing: return "Backup station is missing from bundle or cannot be loaded. Check the build settings. If the network fails and the alarm fires this app won't play any sound!."
            case .jsonCantBeRead: return "Radio JSON cannot be read. Radio functions will not work correctly."
            case .avPlayerFailed: return "Couldn't create an AVPlayer."
        }
    }
}

protocol RadioControllerDelegate {
    func startedPlayingStation()
    func stoppedPlayingStation()
    func showStationName(text:String, positionInfoString:String? )
    func showStationConnectionStatus(text:String )
    func handleiTunesRecordForCurrentTrack( _ itr:iTunesStoreRecord )
    func couldntConnectToStation()
}

class RadioController : NSObject {
    var delegate:RadioControllerDelegate?
    
    private var jsonPrefs:RadioJSON?
    private var cannotConnectStation:RadioStation?
    private var allStations = [String:RadioStation]()
    private var stationPositionStrings = [String:String]()

    private (set) var state:RadioState = .off
    private var audioPlayer:AVPlayer?
    
    private var lastStation:RadioStation?
    private var cycleStationKeys = [String]()
    private var nextCycleIndex = 0

    var isPlayingOrConnecting:Bool {
        return self.state == .playing || self.state == .connecting
    }


    // MARK:- INIT

    override init() {
        super.init()
        
        do {
            // Setup a 'station' to play if the network is missing. For the alarm.
            if let backupStationPath = Bundle.main.url(forResource:"21199__acclivity__morninghasbroken", withExtension:"mp3") {
                self.cannotConnectStation = RadioStation(key: "", url: backupStationPath, displayName: "Morning!")
            } else {
                throw RadioErrors.backupStationIsMissing.nserror()
            }

            try self.loadJSON()
            guard let prefs = self.jsonPrefs else {
                return
            }

            // cycleStationKeys will contain a list of all the stations to toggle over.
            // To build it we sort all the statiosn keys/names then remove the left and right button stations from the list..
            self.cycleStationKeys = self.allStations.keys.sorted()
            self.lastStation = self.allStations[prefs.defaultStation]
            
            self.prepareStationPositionStrings()
        
        } catch ( let error as NSError ) {
            ShowErrorAlert(error)
        }
    }
    
    private func prepareStationPositionStrings() {
    
        for i in 0..<cycleStationKeys.count {
            
            let lastStation:String
            if self.cycleStationKeys.indices.contains(i-1) {
                lastStation = self.allStations[self.cycleStationKeys[i-1]]!.displayName
            } else {
                lastStation = self.allStations[self.cycleStationKeys.last!]!.displayName
            }

            let nextName:String
            if self.cycleStationKeys.indices.contains(i+1) {
                nextName = self.allStations[self.cycleStationKeys[i+1]]!.displayName
            } else {
                nextName = self.allStations[self.cycleStationKeys[0]]!.displayName
            }
            
            let currentName = self.allStations[self.cycleStationKeys[i]]!.displayName
            
            let result = "\(lastStation) • \(currentName) • \(nextName)"
            self.stationPositionStrings[cycleStationKeys[i]] = result
        }
        
        print("\(self.stationPositionStrings)")
    }
    
    private func loadJSON() throws {
        // Get the JSON data....
        guard let stationsPath = Bundle.main.path(forResource:"Stations", ofType: "json"),
                let stationsData = NSData(contentsOfFile:stationsPath) else {
            throw RadioErrors.stationsAreMissing.nserror()
        }
        
        // Load it...
        do {
            self.jsonPrefs = try JSONDecoder().decode(RadioJSON.self, from: stationsData as Data)
        } catch ( let error as NSError ) {
            throw RadioErrors.jsonCantBeRead.nserror(with: error)
        }
        
        guard let prefs = self.jsonPrefs else {
            return
        }

        // Load stations....
        for (key,value) in prefs.stations {
            self.allStations[key] = RadioStation(key: key, url:URL(string: value)!,displayName: key)
        }
    }

    // MARK:- Playback High Level

    func playAlarmStation() {
        self.playStation(withKey:self.jsonPrefs?.alarmStation)
    }

    func playLeftButtonStation() {
        self.playStation(withKey:self.jsonPrefs?.leftButtonStation)
    }
    
    func playRightButtonStation() {
        self.playStation(withKey:self.jsonPrefs?.rightButtonStation)
    }
    
    func playNextStation() {
        nextCycleIndex += 1

        // Valid Index?
        if self.cycleStationKeys.indices.contains(nextCycleIndex) == false {
            nextCycleIndex = 0
        }
        
        self.play(station:self.allStations[cycleStationKeys[nextCycleIndex]])
    }
    
    func playPreviousStation() {
        nextCycleIndex -= 1

        // Valid Index?
        if self.cycleStationKeys.indices.contains(nextCycleIndex) == false {
            nextCycleIndex = self.cycleStationKeys.count - 1
        }
        
        self.play(station:self.allStations[cycleStationKeys[nextCycleIndex]])
    }
    
    func playLastStation() {
        self.play(station:self.lastStation)
    }
    
    func playCantConnectStation() {
        self.play(station:self.cannotConnectStation)
    }
    
    private func playStation( withKey key:String? ) {
        guard let key = key else {
            return
        }
        self.play(station:self.allStations[key])
    }
    
    // MARK:- Playback Low Level
    
    func play( station:RadioStation? ) {
        guard let station = station else {
            return
        }
        
        if let lastStation = self.lastStation, station == lastStation, self.isPlayingOrConnecting {
            // Station is already playing!
            self.delegate?.showStationName(text: station.displayName, positionInfoString: self.stationPositionStrings[station.key] )
            return
        }
        
        self.stopPlaying()
        self.lastStation = station
        self.delegate?.showStationName(text: station.displayName, positionInfoString: self.stationPositionStrings[station.key] )
        
        self.audioPlayer = AVPlayer(url:station.url)
        if self.audioPlayer == nil {
            ShowErrorAlert(RadioErrors.avPlayerFailed.nserror())
        }
        
        self.audioPlayer?.isClosedCaptionDisplayEnabled = false
        self.audioPlayer?.appliesMediaSelectionCriteriaAutomatically = true
        self.audioPlayer?.play()
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.currentItem?.addObserver( self, forKeyPath: "status", options:NSKeyValueObservingOptions.new, context:nil)
        self.audioPlayer?.currentItem?.addObserver( self, forKeyPath: "timedMetadata", options:NSKeyValueObservingOptions.new, context:nil)
        
        self.state = .connecting
        self.delegate?.startedPlayingStation()
        didChange()
    }

    func stopPlaying() {
        self.state = .off

        self.audioPlayer?.pause()
        self.audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "status")
        self.audioPlayer?.currentItem?.removeObserver(self, forKeyPath: "timedMetadata")
        self.audioPlayer = nil

        self.delegate?.stoppedPlayingStation()
        didChange()
    }

    private func didChange() {
        self.delegate?.showStationConnectionStatus( text:state.description)
    }
    
    private func playerItemStatusChanged() {
        guard let playerItem = self.audioPlayer?.currentItem else {
            return
        }

        switch playerItem.status {
            case .failed:
                self.state = .cannotConnect
                self.delegate?.couldntConnectToStation()
            break
            case .readyToPlay:
                self.state = .playing
                break;
            case .unknown:
                break
        }
        
        didChange()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let object = object as? AVPlayerItem,
                let playerItem = self.audioPlayer?.currentItem,
                    object == playerItem else {
            return
        }

        switch keyPath! {
            case "status":
                playerItemStatusChanged();
                break
            case "timedMetadata":
                iTunesStore().examineTimedMetadata(object) { (itr:iTunesStoreRecord) in
                    self.delegate?.handleiTunesRecordForCurrentTrack(itr)
                }
                break;
            
            default: break
        }
    }

}
