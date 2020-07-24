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
    // Floating Panel preview.
    case floatingPanel

    public var title: String {
        switch self {
        case .layers:
            return "Layers"
        case .bookmarks:
            return "Bookmarks"
        case .floatingPanel:
            return "Floating Panel"
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
            case .floatingPanel:
                extraAction = UIAlertAction(title: extra.title, style: .default, handler: { [weak self] (action) in
                    self?.showFloatingPanel(barButtonItem)
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
            layerContentsVC.title = MapViewControllerExtras.layers.title

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
//        let bookmarksVC: BookmarksViewController
        let extrasVC: UINavigationController

        // Create the BookmarksViewController if it's not already created.
//        if let existingViewController = bookmarksViewController {
//            bookmarksVC = existingViewController
//        } else {
//            // Create and configure the view controller.
//            bookmarksVC = BookmarksViewController(geoView: mapView)
//            bookmarksVC.title = MapViewControllerExtras.bookmarks.title
//
//            // Add a done button.
//            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
//            bookmarksVC.navigationItem.leftBarButtonItem = doneButton
//            bookmarksVC.delegate = self
//            bookmarksViewController = bookmarksVC
//        }
     
        // Create the navigation controller if it's not already created.
        if let existingNavigationVC = extrasNavigationController {
            extrasVC = existingNavigationVC
            extrasVC.setViewControllers([bookmarksViewController], animated: false)
        } else {
            extrasVC = UINavigationController(rootViewController: bookmarksViewController)
            extrasNavigationController = extrasVC
        }

        // Display the extrasVC as a popover controller.
        extrasVC.modalPresentationStyle = .popover
        extrasVC.popoverPresentationController?.barButtonItem = barButtonItem
        present(extrasVC, animated: true)
    }
    
    func showFloatingPanel(_ barButtonItem: UIBarButtonItem?) {
        let floatingPanelVC: FloatingPanelViewController?
//        let extrasVC: UINavigationController

        // Create the FloatingPanelViewController.
        // Create and configure the view controller.
        
        // Get the bundle and then the storyboard for the LayerContentsTableViewController.
        let bundle = Bundle(for: FloatingPanelViewController.self)
        let storyboard = UIStoryboard(name: "FloatingPanelViewController", bundle: bundle)
        // Create the layerContentsTableViewController from the storyboard.
        floatingPanelVC = storyboard.instantiateInitialViewController() as? FloatingPanelViewController

        guard let floatingPanelViewController = floatingPanelVC else { return }
        floatingPanelViewController.floatingPanelTitle = MapViewControllerExtras.floatingPanel.title
        floatingPanelViewController.floatingPanelSubtitle = "Select a bookmark"
        floatingPanelViewController.image = UIImage(named: "bookmark")
        
        floatingPanelViewController.initialViewController = bookmarksViewController
        floatingPanelViewController.delegate = self
        
//
//        // Add a done button.
//        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
//        floatingPanelViewController.navigationItem.rightBarButtonItem = doneButton
//
//        let extrasVC = UINavigationController(rootViewController: floatingPanelViewController)
//
//        // Display the extrasVC as a popover controller.
//        extrasVC.modalPresentationStyle = .popover
//        extrasVC.popoverPresentationController?.barButtonItem = barButtonItem
//        present(extrasVC, animated: true)
        
//        Add vc.view as subview, moveToParent, set constraints, etc.
        addChild(floatingPanelViewController)
        self.view.addSubview(floatingPanelViewController.view)
        
        floatingPanelViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
//        let topConstraint = floatingPanelViewController.view.topAnchor.constraint(equalTo: (view.safeAreaLayoutGuide.topAnchor), constant: floatingPanelViewController.edgeInsets.top)
//        floatingPanelViewController.resizeableLayoutConstraint = topConstraint
//        
//        var trailingConstraint: NSLayoutConstraint
//        if traitCollection.horizontalSizeClass == .compact {
//            trailingConstraint = floatingPanelViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -floatingPanelViewController.edgeInsets.right)
//        }
//        else {
//            trailingConstraint = floatingPanelViewController.view.trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: 320)
//        }
//        
//        NSLayoutConstraint.activate([
//            floatingPanelViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: floatingPanelViewController.edgeInsets.left),
//            trailingConstraint,
//            topConstraint,
//            floatingPanelViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -floatingPanelViewController.edgeInsets.bottom)
//        ])

        floatingPanelViewController.didMove(toParent: self)
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
extension MapViewController: FloatingPanelViewControllerDelegate {
    func userDidRequestDismissFloatingPanel(_ floatingPanelViewController: FloatingPanelViewController) {
        // Animate the alpha of the panel to 0.0 then remove from parent
        UIView.animate(withDuration: 0.5, animations: {
            floatingPanelViewController.view.alpha = 0.0
        }) { (_) in
            floatingPanelViewController.removeFromParent()
            floatingPanelViewController.view.removeFromSuperview()
        }
    }
    
//    func hideFloatingPanelViewController(_ floatingPanelViewController: FloatingPanelViewController) {
//        //remove current constraint
////        floatingPanelViewController.view.removeConstraint(floatingPanelViewController.resizeableLayoutConstraint)
//
////        let hideConstraint = NSLayoutConstraint(item: floatingPanelViewController.view as Any,
////            attribute: .top,
////            relatedBy: .equal,
////            toItem: floatingPanelViewController.view,
////            attribute: .bottom,
////            multiplier: 1,
////            constant: -200)
////        self.view.addConstraint(hideConstraint)
//        //animate changes
////        floatingPanelViewController.view.alpha = 0.0
//        UIView.animate(withDuration: 0.5, animations: {
//            floatingPanelViewController.view.alpha = 0.0
//        }) { (_) in
//            floatingPanelViewController.removeFromParent()
//            floatingPanelViewController.view.removeFromSuperview()
//        }
//    }
}
