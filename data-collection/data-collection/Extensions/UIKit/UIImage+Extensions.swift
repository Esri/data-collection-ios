//// Copyright 2017 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

extension UIImage {
    
    /**
     This UIImage extension function returns a new copy of an image that is resized, circled and given a white stroke weight.
     */
    func circularThumbnail(ofSize desiredWH: CGFloat, strokeColor: UIColor) -> UIImage? {
        
        let scale = min(size.width/desiredWH, size.height/desiredWH)
        
        let newSize = CGSize(width: size.width/scale, height: size.height/scale)
        let newOrigin = CGPoint(x: (desiredWH - newSize.width)/2, y: (desiredWH - newSize.height)/2)
        
        let thumbRect = CGRect(origin: newOrigin, size: newSize).integral
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: desiredWH, height: desiredWH), false, 0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.saveGState()
        
        let path = UIBezierPath(roundedRect: thumbRect, cornerRadius: min(thumbRect.width/2, thumbRect.height/2))
        context.beginPath()
        context.addPath(path.cgPath)
        context.closePath()
        context.clip()
        
        draw(in: thumbRect)
        
        strokeColor.setStroke()
        path.lineWidth = 1 * UIScreen.main.scale
        path.stroke()
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result
    }
    
    /**
     This UIImage extension function returns a new copy of an image applying a color mask.
     */
    func renderImage(toMaskWithColor color: UIColor) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.clip(to: CGRect(x: 0, y: 0, width: size.width, height: size.height), mask: cgImage!)
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let coloredImg: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return coloredImg
    }
}
