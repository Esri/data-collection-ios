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
    /// Build a copy of an image that is resized, clipped by a circle and given a stroke weight.
    ///
    /// - Parameters:
    ///   - diameter: The diameter of the rendered circular thumbnail.
    ///   - stroke: Tuple (color, weight) (optional).
    /// - Returns: A new `UIImage`.
    func circularThumbnail(ofSize diameter: CGFloat, stroke: (color: UIColor, weight: CGFloat)?) -> UIImage? {
        // We want to crop a UIImage to a specific size and to scale (considering of the device's screen resolution).
        let scale = min(size.width, size.height) / diameter
        
        let newSize = CGSize(width: size.width / scale, height: size.height / scale)
        let newOrigin = CGPoint(x: (diameter - newSize.width) / 2, y: (diameter - newSize.height) / 2)
        
        let thumbRect = CGRect(origin: newOrigin, size: newSize).integral
        
        let graphicsRenderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter), format: .init(for: traitCollection))
        let image = graphicsRenderer.image { (context) in
            // Build a circular path.
            let path = UIBezierPath(roundedRect: thumbRect, cornerRadius: min(thumbRect.width/2, thumbRect.height/2))
            context.cgContext.beginPath()
            context.cgContext.addPath(path.cgPath)
            context.cgContext.closePath()
            context.cgContext.clip()
            
            context.cgContext.translateBy(x: 0, y: diameter)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            context.cgContext.draw(cgImage!, in: thumbRect)
            
            // Draw a stroke weight provided parameters
            if let (color, weight) = stroke {
                color.setStroke()
                path.lineWidth = weight * UIScreen.main.scale
                path.stroke()
            }
        }
        return image
    }
    
    /// Makes a copy of an image applying a color mask.
    ///
    /// - Parameter color: The color to apply to the color mask.
    /// - Returns: A new `UIImage`.
    func renderImage(toMaskWithColor color: UIColor) -> UIImage {
        let graphicsRenderer = UIGraphicsImageRenderer(size: size, format: .init(for: traitCollection))
        return graphicsRenderer.image { (context) in
            color.setFill()
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.clip(to: rect, mask: cgImage!)
            context.fill(rect)
        }
    }
}
