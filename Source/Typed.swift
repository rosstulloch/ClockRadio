//
//  Typed.swift
//  ClockRadio
//
//  Created by Ross Tulloch on 20/10/2015.
//  Copyright © 2015 Ross Tulloch. All rights reserved.
//

import Foundation

struct Typed {

    enum TypeValueError: Error {
        case failedToFetchValue( keyPath:String, target:NSObject )
    }

    static func stringForKeyPath(_ path:String, from target:NSObject ) throws -> String {
        if let obj = target.value(forKeyPath: path) as? String {
            return obj
        } else {
            Debugging.LogError(nil, message: "Error: Path:\(path) Target:\(target)")
            throw TypeValueError.failedToFetchValue(keyPath: path, target: target)
        }
    }

    static func valueForKeyPath<T>(_ path:String, from target:NSObject, asType type:T ) throws -> T {
        if let obj = target.value(forKeyPath: path) as? T {
            return obj
        } else {
            Debugging.LogError(nil, message: "Error: Path:\(path) Target:\(target)")
            throw TypeValueError.failedToFetchValue(keyPath: path, target: target)
        }
    }

}

