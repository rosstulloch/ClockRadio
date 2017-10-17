//
//  DebuggingAdditions.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 15/10/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation

struct Debugging {

    static func LogError( _ error:NSError? = nil, message:String = "Error: ", function: String = #function, file: String = #file, line: Int = #line ) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            NSLog("%@ %@ %@ in %@ line %d", message, error, function, fileName, line)
        } else {
            NSLog("%@ in %@ in %@ line %d", message, function, fileName, line)
        }
    }

}

func debugprint(_ s:String) {
#if DEBUG
    print(s)
#endif
}
