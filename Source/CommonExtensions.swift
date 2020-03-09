//
//  CommonExtensions.swift
//  ClockRadioTerminal
//
//  Created by Ross Tulloch on 7/3/20.
//  Copyright © 2020 Ross Tulloch. All rights reserved.
//

import Foundation
import UIKit

extension String {

    func substring(from s:String ) -> String? {
        guard let startRange = self.range(of: s) else {
            return nil
        }
        let t = self.suffix(from: startRange.upperBound)
        return String(t)
    }

    func substring(upTo s:String ) -> String? {
        guard let range = self.range(of: s) else {
            return nil
        }
        let t = self.prefix(upTo: range.lowerBound)
        return String(t)
    }

    func substring(from:String, upTo:String ) -> String? {
        guard let textFrom = self.substring(from: from) else {
            return nil
        }
        guard let textEnd = textFrom.substring(upTo: upTo) else {
            return nil
        }
        return textEnd
    }

}

extension URL {

    func load( handler:@escaping (String)->Void ) {
        URLSession.shared.dataTask(with:URLRequest(url: self)) { data, response, error in
            guard let data = data else {
                return
            }
            guard let html = String(data: data, encoding: .utf8) else {
                return
            }
            DispatchQueue.main.async {
                handler(html)
            }
        }.resume()
    }

}


extension UIImage {

    func changeWhiteColorTransparent() -> UIImage? {
        UIGraphicsBeginImageContext(self.size)

        guard let currentContext = UIGraphicsGetCurrentContext() else { return nil }
        
        guard let rawImageRef = self.cgImage else { return nil }
        guard let maskedImageRef = rawImageRef.copy(maskingColorComponents:[0.0, 4.0, 0.0, 4.0, 0.0, 4.0]) else { return nil }

        let r = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        
        currentContext.translateBy(x:  0.0, y: self.size.height)
        currentContext.scaleBy(x: 1.0, y: -1.0)
        currentContext.draw( maskedImageRef, in: r)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    func tintWithColor(_ color:UIColor ) -> UIImage? {
        let renderRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        
        // New image...
        UIGraphicsBeginImageContext(renderRect.size)
        
        // Fill with color...
        color.setFill()
        UIBezierPath(rect: renderRect).fill()
        
        self.draw(in: renderRect, blendMode: .destinationAtop, alpha: 1.0)
        self.draw(in: renderRect, blendMode: .darken, alpha: 1.0)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }


}

extension UILabel {

    var isTruncated: Bool {

        guard let labelText = text else {
            return false
        }

        let labelTextSize = (labelText as NSString).boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: self.font as Any],
            context: nil).size

        return labelTextSize.height > bounds.size.height
    }
}
