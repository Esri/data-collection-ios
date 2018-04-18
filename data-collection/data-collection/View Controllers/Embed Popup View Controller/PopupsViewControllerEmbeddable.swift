//// Copyright 2018 Esri
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
import ArcGIS

protocol PopupsViewControllerEmbeddable where Self: UIViewController {
    weak var popupsContainerView: UIView! { get }
}

extension PopupsViewControllerEmbeddable {
    
    func embedPopupsViewController(withPopup popup: AGSPopup? = nil) -> AGSPopupsViewController {
        
        var popups = [AGSPopup]()
        
        if let addPopup = popup {
            popups.append(addPopup)
        }
        
        let controller = AGSPopupsViewController(popups: popups, containerStyle: .custom)
        
        return embedChildViewController(controller) as! AGSPopupsViewController
    }
    
    func embedPopupsSmallViewController(withPopup popup: AGSPopup? = nil) -> SmallPopupViewController {
        
        let storyboard = UIStoryboard(name: "SmallPopup", bundle: nil)
        
        let controller = storyboard.instantiateInitialViewController() as! SmallPopupViewController
        
        let small = embedChildViewController(controller) as! SmallPopupViewController
        small.popup = popup
        
        return small
    }
    
    private func embedChildViewController(_ controller: UIViewController) -> UIViewController {
        
        self.addChildViewController(controller)
        self.view.addSubview(controller.view)
        
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: popupsContainerView.leadingAnchor, constant: 0),
            controller.view.trailingAnchor.constraint(equalTo: popupsContainerView.trailingAnchor, constant: 0),
            controller.view.topAnchor.constraint(equalTo: popupsContainerView.topAnchor, constant: 0),
            controller.view.bottomAnchor.constraint(equalTo: popupsContainerView.bottomAnchor, constant: 0)
            ])
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.willMove(toParentViewController: self)
        
        return controller
    }
}
