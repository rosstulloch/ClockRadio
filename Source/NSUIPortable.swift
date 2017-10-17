//
//  NSUIPortable.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 17/09/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation

protocol ErrorsHelper {
    var domain:String { get }
    var code:Int { get }
    var description:String { get }
    var suggestion:String? { get }
}

extension ErrorsHelper {
    var suggestion:String? { return nil }

    func nserror(with error:NSError? = nil) -> NSError {
        Debugging.LogError(error)
        var description = self.description
        if let error = error {
            description = " " + error.localizedDescription
        }
        var suggestion = ""
        if let _suggestion = self.suggestion {
            suggestion = _suggestion
        }
        return NSError(domain: self.domain, code: self.code, userInfo:[NSLocalizedDescriptionKey:description, NSLocalizedRecoverySuggestionErrorKey:suggestion])
    }
}

/*

 Example stub:
 
fileprivate enum MyErrors : Int, ErrorsHelper {
    var domain:String { return "MyErrors" }
    var code:Int { return self.rawValue }

    case errorOne
 
    var description:String {
        switch(self) {
            case .errorOne: return "Description"
        }
    }
}

 let error:NSError = MyErrors.errorOne.error()

*/

#if os(iOS) || os(watchOS)
  
    import UIKit  
    public typealias NSUIFont=UIFont
    public typealias NSUIColor=UIColor
    public typealias NSUIViewController=UIViewController
    public typealias NSUIView=UIView
    public typealias NSUIImage=UIImage
    
    func NSUIImageFromData(_ data:Data) -> NSUIImage? {
        return UIImage(data:data)
    }
    
    func ShowErrorAlert(_ error:NSError, extraMessage:String? = nil, function: String = #function, file: String = #file, line: Int = #line, showSourceDetails:Bool = true ) {
        // Write to disk....
        Debugging.LogError(error)

        // Build a message....
        var message = error.localizedDescription
        if let localizedFailureReason = error.localizedFailureReason {
            message += " " + localizedFailureReason
        }
        if let extraMessage = extraMessage {
            message += " " + extraMessage
        }
        if let localizedRecoverySuggestion = error.localizedRecoverySuggestion {
            message += " " + localizedRecoverySuggestion
        }

        // Should we show the details of where the code failed in the source?
        if showSourceDetails {
            var fileName = (file as NSString).lastPathComponent
            if fileName.hasSuffix(".swift") {
                fileName = String(fileName.dropLast(".swift".characters.count))
            }
            message += " [\(fileName):\(function):\(line)]"
        }
        
        // Make alert...
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil ))
        
        // Try to show...
        if let vc = UIApplication.shared.keyWindow?.rootViewController {
            vc.present(alert, animated: true, completion: nil)
        } else {
            // No view controller. The app is probably starting. Schedule this to try again...If it fails again halt.
            GCDAdditions.perform {
                UIApplication.shared.keyWindow!.rootViewController!.present(alert, animated: true, completion: nil)
            }
        }
    }
    
#endif

#if os(OSX)

    import AppKit
    public typealias NSUIFont=NSFont
    public typealias NSUIColor=NSColor
    public typealias NSUIViewController=NSViewController
    public typealias NSUIView=NSView
    public typealias NSUIImage=NSImage

#endif
