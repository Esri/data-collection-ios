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

// MARK: UIView Animation

// UIView Animation Callback

typealias UIViewAnimations = () -> Void

// MARK: Core Graphics

extension UIView {
    
    var boundsCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

// MARK: Style

extension UIView {
    
    func stylizeBorder() {
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.2).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        clipsToBounds = true
    }
}

// MARK: Autolayout

extension UIView {
    
    func addSubviewAndConstrainToView(_ subview: UIView) {

        addSubview(subview)
        
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0))
        constraints.append(subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0))
        constraints.append(subview.topAnchor.constraint(equalTo: topAnchor, constant: 0))
        constraints.append(subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0))
        
        NSLayoutConstraint.activate(constraints)
    }
}

