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

private let layersExtra = "Layers"
private let bookmarksExtra = "Bookmarks"

extension MapViewController {
    func userRequestsExtras(_ barButtonItem: UIBarButtonItem?) {
        guard mapViewMode != .disabled else {
            return
        }

        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
        // Present the list of extras.
        for extra in [layersExtra, bookmarksExtra] {
            let extraAction = UIAlertAction(title: extra, style: .default, handler: { [weak self] (action) in
                switch extra {
                case layersExtra:
                    self?.showLayerContents(barButtonItem)
                case bookmarksExtra:
                    self?.showBookmarks(barButtonItem)
                default:
                    break
                }
            })
            
            action.addAction(extraAction)
        }
        
        action.addAction(.cancel())
        action.popoverPresentationController?.barButtonItem = barButtonItem
        present(action, animated: true)
    }
    
    func showLayerContents(_ barButtonItem: UIBarButtonItem?) {
        // Create the LayerContentsViewController if it doesn't exist.
        if layerContentsViewController == nil {
            let dataSource = DataSource(geoView: mapView)
            layerContentsViewController = TableOfContents(dataSource)
            
            // Add a done button.
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
            layerContentsViewController?.navigationItem.leftBarButtonItem = doneButton
        }
        
        if let layerContentsVC = layerContentsViewController {
            // Display the layerContentsVC as a popover controller.
            layerContentsVC.modalPresentationStyle = .popover
            layerContentsVC.popoverPresentationController?.barButtonItem = barButtonItem
            present(layerContentsVC, animated: true)
        }
    }
    
    func showBookmarks(_ barButtonItem: UIBarButtonItem?) {
        // Create the BookmarksViewController if it doesn't exist.
        if bookmarksViewController == nil {
            bookmarksViewController = BookmarksViewController(geoView: mapView)
            
            // Add a done button.
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
            bookmarksViewController?.navigationItem.leftBarButtonItem = doneButton
            bookmarksViewController?.delegate = self
        }
        
        if let bookmarksVC = bookmarksViewController {
            // Display the bookmarksVC as a popover controller.
            bookmarksVC.modalPresentationStyle = .popover
            bookmarksVC.popoverPresentationController?.barButtonItem = barButtonItem
            present(bookmarksVC, animated: true)
        }
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
