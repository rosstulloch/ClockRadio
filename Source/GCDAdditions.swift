//
//  GCDAdditions.swift
//  BlueHarvest
//
//  Created by Ross Tulloch on 1/09/2015.
//
//

import Foundation

struct GCDAdditions {
    fileprivate static var keysAndOperations = [String:Operation]()
    
    @discardableResult public static func cancelPreviousThenPerform( filePath:String = #file, line:Int = #line, afterDelay delay:Float, block:@escaping ()->() ) -> Operation {
        let key = filePath + ":\(line)"
        if let oldOperation = keysAndOperations[key] {
            if oldOperation.isFinished == false && oldOperation.isExecuting == false {
                oldOperation.cancel()
            }
        }

        let futureOperation = self.perform(afterDelay: delay, block: block)
        keysAndOperations[key] = futureOperation
        return futureOperation
    }

    @discardableResult public static func perform(afterDelay delay:Float = 0.1, block:@escaping ()->() ) -> Operation {
        let operation = BlockOperation(block: block)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64( delay * Float(NSEC_PER_SEC) )) / Double(NSEC_PER_SEC)) {
            if !operation.isCancelled {
                OperationQueue.current!.addOperation(operation)
            }
        }
        return operation
    }
    
}
