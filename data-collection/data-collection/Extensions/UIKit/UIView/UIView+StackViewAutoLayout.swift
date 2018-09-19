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
    
    func addStackviewAndConstrainToEdges(_ stackView: UIStackView) {

        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        let trailing = stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        let top = stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        let bottom = stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        
        switch stackView.axis {
            
        case .horizontal:
            leading.priority = UILayoutPriority(999)
            trailing.priority = UILayoutPriority(999)

        case .vertical:
            top.priority = UILayoutPriority(999)
            bottom.priority = UILayoutPriority(999)
        }
        
        NSLayoutConstraint.activate([leading, trailing, top, bottom])
    }
}

