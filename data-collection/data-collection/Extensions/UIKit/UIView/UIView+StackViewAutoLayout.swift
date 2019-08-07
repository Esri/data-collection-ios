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

// MARK: Autolayout

extension UIView {
    
    /// Add a `UIStackView` child view and constrain the stack view to leading, trailing, top, and bottom anchors.
    ///
    /// - Parameters:
    ///   - stackView: The stack view to add as a subview.
    ///   - reduce: If the caller would like to modify the stack view's constraint priority to less than required (1000), axis dependent.
    ///   This is desireable for a scenario where a `UIStackView` is added to the `contentView` of a `UITableViewCell`, for example.
    
    func addStackviewAndConstrainToEdges(_ stackView: UIStackView, reduceAxisPriority reduce: Bool = true) {

        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        let trailing = stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        let top = stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        let bottom = stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        
        if reduce {
            
            switch stackView.axis {
                
            case .horizontal:
                leading.priority = UILayoutPriority(999)
                trailing.priority = UILayoutPriority(999)
                
            case .vertical:
                top.priority = UILayoutPriority(999)
                bottom.priority = UILayoutPriority(999)
                
            @unknown default:
                fatalError("Unsupported case \(self).")
            }
        }

        NSLayoutConstraint.activate([leading, trailing, top, bottom])
    }
}

