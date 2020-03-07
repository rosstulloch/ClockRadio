//
//  iTunesStore.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 20/10/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation
import AVFoundation

struct iTunesStoreResults  : Codable {
    let resultCount:Int
    let results:[iTunesStoreRecord]
}

struct iTunesStoreRecord : Codable {
    let artistName:String
    let kind:String
    let artistViewUrl:String?
    let trackViewUrl:String
    let artworkUrl100:String
    let trackCensoredName:String
    
    enum iTunesRecordError : Int, ErrorsHelper {
        var domain:String { return "iTunesStoreRecord" }
        var code:Int { return self.rawValue }

        case wrongType, artworkUrlIsInvalid
        
        var description: String {
            switch self {
                case .wrongType: return "wrongType"
                case .artworkUrlIsInvalid: return "artwork url is invalid."
            }
        }
    }

    func fetchArtwork( _ completion:@escaping (_ artwork100:NSUIImage?,_ error:NSError?)->Void ) {
        guard let artUrl = URL(string: artworkUrl100) else {
            completion( nil, iTunesRecordError.artworkUrlIsInvalid.nserror() )
            return
        }
    
        let fn = { (data:Data?, response:URLResponse?, error:Error?) -> Void in
            var artwork100:NSUIImage? = nil
            if let data = data {
                artwork100 = NSUIImageFromData(data)
            }
            DispatchQueue.main.async {
                completion( artwork100, error as NSError?)
            }
        }
        
        let task = URLSession.shared.dataTask(with: artUrl, completionHandler:fn)
        task.resume()
    }
    
}

struct InterestingAVMetaData {
    var title:String? = nil
    var publisher:String? = nil
    var publisherData:[String:String]? = nil
}

struct iTunesStore
{
    private let appleStartOfSearchURL = "https://itunes.apple.com/search?term="

    private func normalise(_ source:String ) -> String {
        var result = source
        result = result.replacingOccurrences(of: "*", with:"")
        result = result.replacingOccurrences(of: "'", with:"")
        result = result.replacingOccurrences(of: "/", with:"")
        result = result.replacingOccurrences(of: " ", with: "+")
        return result
    }
    
    func find( title:String, completion:@escaping ([iTunesStoreRecord])->Void ) {
        let searchTerm = normalise(title)
        let finalURL = URL(string: appleStartOfSearchURL+searchTerm)!

        query(finalURL) { (records:[iTunesStoreRecord]) in
            let filtered = self.stripNonSongsFrom(records)
            completion(filtered)
        }
    }
    
    func find( publishingData pd:[String:String], completion:@escaping ([iTunesStoreRecord])->Void ) {
        guard let songTitle = pd["SongTitle"], let songArtist = pd["SongArtist"] else {
            completion([iTunesStoreRecord]())
            return
        }
        
        // First word from Artist name and song title.
        let wordsFromArtist = songArtist.components(separatedBy: " ")
        let string = "\(songTitle) \(wordsFromArtist[0])"
        let searchTerm = normalise(string)
        let finalURL = URL(string: appleStartOfSearchURL+searchTerm)!

        query(finalURL) { (records:[iTunesStoreRecord]) in
            let filtered = self.stripNonSongsFrom(records)
            completion(filtered)
        }
    }
    
    private func query(_ url:URL, completion:@escaping ([iTunesStoreRecord])->Void ) {
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            guard let data = data else {
                return
            }

            var results = [iTunesStoreRecord]()
            do {
                results = try JSONDecoder().decode(iTunesStoreResults.self, from: data).results
                completion(results)
            } catch ( let error as NSError ) {
                Debugging.LogError( error)
            }

        }
        task.resume()
    }
    
    private func stripNonSongsFrom(_ from:[iTunesStoreRecord] ) -> [iTunesStoreRecord] {
        return from.filter{ (record:iTunesStoreRecord) -> Bool in
            if  record.kind != "song" {
                return false
            }
            return true
        }
    }

    private func fetchInterestingMetaData(_ md:[AVMetadataItem] ) -> InterestingAVMetaData {
        var result = InterestingAVMetaData()
        for metadata in md {
            guard let commonKey = convertFromOptionalAVMetadataKey(metadata.commonKey) else {
                continue
            }
            switch commonKey {
                case "title":
                if let stringValue = metadata.value as? String {
                    result.title = stringValue
                }
                break
                case "publisher":
                if let stringValue = metadata.value as? String {
                    result.publisher = stringValue
                    result.publisherData = parsePublisherData(result.publisher!)
                }
                break
                default:
             //   print("fetchInterestingMetaData missed: \(commonKey)")
                break
            }
        }
        
        return result
    }
    
    private func parsePublisherData(_ data:String ) -> [String:String] {
        var results = [String:String]()
        for item in data.components(separatedBy: "|") {
            let parts = item.components(separatedBy: "=")
            if parts.count >= 2 {
                let key = parts[0]
                let value = parts[1]
                results[key] = value
            }
        }
        return results
    }

    func examineTimedMetadata(_ item:AVPlayerItem, completion:@escaping (iTunesStoreRecord)->Void ) {
        guard let metaDataItems = item.timedMetadata else {
            return
        }
        
        // Pull the metadata from the track....
        let md =  self.fetchInterestingMetaData( metaDataItems )
        guard let title = md.title else {
            return
        }
        
        // Try the search using the title...
        self.find(title:title) { records in
            if let first = records.first {
                DispatchQueue.main.async {
                    completion( first )
                }
            } else {
                // that didn't work so try a broad search....
                guard let publisherData = md.publisherData else {
                    return
                }
                self.find(publishingData:publisherData) { records in
                    guard let first = records.first else {
                        return
                    }
                    DispatchQueue.main.async {
                        completion( first )
                    }
                }
            }
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromOptionalAVMetadataKey(_ input: AVMetadataKey?) -> String? {
	guard let input = input else { return nil }
	return input.rawValue
}
