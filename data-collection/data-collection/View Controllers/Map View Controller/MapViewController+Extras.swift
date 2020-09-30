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

    public var title: String {
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
                extraAction = UIAlertAction(title: extra.title, style: .default, handler: { [weak self] (action) in
                    self?.showLayerContents(barButtonItem)
                })
            case .bookmarks:
                extraAction = UIAlertAction(title: extra.title, style: .default, handler: { [weak self] (action) in
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
        
        // Create the LayerContentsViewController if it's not already created.
        if let existingViewController = layerContentsViewController {
            layerContentsVC = existingViewController
        } else {
            // Create and configure the view controller.
            let dataSource = LayerContentsDataSource(geoView: mapView)
            layerContentsVC = TableOfContentsViewController(dataSource: dataSource)
            layerContentsVC.title = MapViewControllerExtras.layers.title

            layerContentsViewController = layerContentsVC
        }
        
        // Show the layer contents in a floating panel.  Use the adjusted insets
        // for the regular width case, as for compact width the floating panel
        // will extend all the way to the bottom.
        let floatingPanel = FloatingPanelController.instantiate(layerContentsVC,
                                                                regularWidthInsets: adjustedFloatingPanelInsets())
        floatingPanelController = floatingPanel
        presentFloatingPanel(floatingPanel)
        floatingPanel.delegate = self
    }
    
    func showBookmarks(_ barButtonItem: UIBarButtonItem?) {
        // Configure the view controller.
        let bookmarksVC = BookmarksViewController(geoView: mapView)
        bookmarksVC.delegate = self
        
        // Show the bookmarks in a floating panel.  Use the adjusted insets
        // for the regular width case, as for compact width the floating panel
        // will extend all the way to the bottom.
        let floatingPanel = FloatingPanelController.instantiate(bookmarksVC,
                                                                regularWidthInsets: adjustedFloatingPanelInsets())
        floatingPanelController = floatingPanel
        presentFloatingPanel(floatingPanel)
        floatingPanel.delegate = self
    }

    @objc
    func done() {
        dismiss(animated: true)
    }
    
    /// Create the floating panel insets, taking into account the map view's
    /// adjusted content inset for the attribution bar.
    /// - Returns: The floating panel insets.
    private func adjustedFloatingPanelInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 8.0, left: 8.0, bottom: mapView.adjustedContentInset.bottom + 8.0, right: 8.0)
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

extension MapViewController: FloatingPanelControllerDelegate {
    func userDidRequestDismissFloatingPanel(_ floatingPanelController: FloatingPanelController) {
        // Animate the alpha of the panel to 0.0 then dismiss it.
        UIView.animate(withDuration: 0.5, animations: {
            floatingPanelController.view.alpha = 0.0
        }) { [weak self] (_) in
            self?.dismissFloatingPanel(floatingPanelController)
        }
    }
}

extension BookmarksViewController: FloatingPanelEmbeddable {
    // We know that the BookmarksViewController will not be making
    // changes to the floating panel item, so it's OK to just have
    // this as a computed property.  Otherwise, that class would need
    // to be updated to implement FloatingPanelEmbeddable.
    public var floatingPanelItem: FloatingPanelItem {
        let fpItem = FloatingPanelItem()
        fpItem.title = MapViewControllerExtras.bookmarks.title
        fpItem.subtitle = "Select a bookmark"
        fpItem.image = UIImage(named: "bookmark")
        return fpItem
    }
}

extension LayerContentsViewController: FloatingPanelEmbeddable {
    // We know that the LayerContentsViewController will not be making
    // changes to the floating panel item, so it's OK to just have
    // this as a computed property.  Otherwise, that class would need
    // to be updated to implement FloatingPanelEmbeddable.
    public var floatingPanelItem: FloatingPanelItem {
        get {
            let item = FloatingPanelItem()
            item.title = MapViewControllerExtras.layers.title
            item.image = UIImage(named: "layers")
            return item
        }
    }
}
