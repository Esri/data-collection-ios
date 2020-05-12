//// Copyright 2020 Esri
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

import Foundation
import ArcGIS
import ArcGISToolkit

/// Defines the Extras.
public enum MapViewControllerExtras : CaseIterable {
    // Displays layer content.
    case layers
    // Displays bookmarks.
    case bookmarks
}

extension MapViewControllerExtras : CustomStringConvertible {
    public var description: String {
        switch self {
        case .layers:
            return "Layers"
        case .bookmarks:
            return "Bookmarks"
        }
    }
}

extension MapViewController {
    func userRequestsExtras(_ barButtonItem: UIBarButtonItem?) {
        guard mapViewMode != .disabled else {
            return
        }

        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
        // Present the list of extras.
        for extra in MapViewControllerExtras.allCases {
            let extraAction: UIAlertAction
            switch extra {
            case .layers:
                extraAction = UIAlertAction(title: extra.description, style: .default, handler: { [weak self] (action) in
                    self?.showLayerContents(barButtonItem)
                })
            case .bookmarks:
                extraAction = UIAlertAction(title: extra.description, style: .default, handler: { [weak self] (action) in
                    self?.showBookmarks(barButtonItem)
                })
            }
            
            action.addAction(extraAction)
        }
        
        action.addAction(.cancel())
        action.popoverPresentationController?.barButtonItem = barButtonItem
        present(action, animated: true)
    }
    
    func showLayerContents(_ barButtonItem: UIBarButtonItem?) {
        let layerContentsVC: LayerContentsViewController
        let extrasVC: UINavigationController
        
        // Create the LayerContentsViewController if it's not already created.
        if let existingViewController = layerContentsViewController {
            layerContentsVC = existingViewController
        } else {
            // Create and configure the view controller.
            let dataSource = LayerContentsDataSource(geoView: mapView)
            layerContentsVC = TableOfContentsViewController(dataSource: dataSource)
            layerContentsVC.title = MapViewControllerExtras.layers.description

            // Add a done button.
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
            layerContentsVC.navigationItem.leftBarButtonItem = doneButton
            layerContentsViewController = layerContentsVC
        }

        // Create the navigation controller if it's not already created.
        if let existingNavigationVC = extrasNavigationController {
            extrasVC = existingNavigationVC
            extrasVC.setViewControllers([layerContentsVC], animated: false)
        } else {
            extrasVC = UINavigationController(rootViewController: layerContentsVC)
            extrasNavigationController = extrasVC
        }
        
        // Display the extrasVC as a popover controller.
        extrasVC.modalPresentationStyle = .popover
        extrasVC.popoverPresentationController?.barButtonItem = barButtonItem
        present(extrasVC, animated: true)
    }
    
    func showBookmarks(_ barButtonItem: UIBarButtonItem?) {
        let bookmarksVC: BookmarksViewController
        let extrasVC: UINavigationController

        // Create the BookmarksViewController if it's not already created.
        if let existingViewController = bookmarksViewController {
            bookmarksVC = existingViewController
        } else {
            // Create and configure the view controller.
            bookmarksVC = BookmarksViewController(geoView: mapView)
            bookmarksVC.title = MapViewControllerExtras.bookmarks.description

            // Add a done button.
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
            bookmarksVC.navigationItem.leftBarButtonItem = doneButton
            bookmarksVC.delegate = self
            bookmarksViewController = bookmarksVC
        }
     
        // Create the navigation controller if it's not already created.
        if let existingNavigationVC = extrasNavigationController {
            extrasVC = existingNavigationVC
            extrasVC.setViewControllers([bookmarksVC], animated: false)
        } else {
            extrasVC = UINavigationController(rootViewController: bookmarksVC)
            extrasNavigationController = extrasVC
        }

        // Display the extrasVC as a popover controller.
        extrasVC.modalPresentationStyle = .popover
        extrasVC.popoverPresentationController?.barButtonItem = barButtonItem
        present(extrasVC, animated: true)
    }

    @objc
    func done() {
        dismiss(animated: true)
    }
}

extension MapViewController: BookmarksViewControllerDelegate {
    func bookmarksViewController(_ controller: BookmarksViewController, didSelect bookmark: AGSBookmark) {
        if let viewpoint = bookmark.viewpoint {
            mapView.setViewpoint(viewpoint, duration: 2.0)
            dismiss(animated: true)
        }
    }
}
