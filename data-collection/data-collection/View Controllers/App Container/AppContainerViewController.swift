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

protocol DrawerViewReferencable {
    var drawerView: AppContainerViewController? { get set }
}

class AppContainerViewController: AppContextAwareController {
    
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var secondRightBarButton: UIBarButtonItem!
    
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var mainMapView: UIView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView! 
    
    @IBOutlet weak var outsideDrawerTapGestureRecognizer: UITapGestureRecognizer!
    
    weak var drawerViewController: DrawerViewController?
    weak var mapViewController: MapViewController?
    weak var jobStatusViewController: JobStatusViewController?
    
    var dismissTimer: Timer?
    
    @IBOutlet weak var drawerLeadingLayoutConstraint: NSLayoutConstraint!
    
    var drawerShowing: Bool = false {
        didSet {
            adjustForDrawerShowing()
            adjustNavigationBarButtons()
        }
    }
    
    var showProfileBarButton: Bool = true {
        didSet {
            adjustNavigationBarButtons()
        }
    }
    
    var showAddFeatureBarButton: Bool = true {
        didSet {
            adjustNavigationBarButtons()
        }
    }
    
    var showZoomToLocationBarButton: Bool = true {
        didSet {
            adjustNavigationBarButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustForDrawerShowing(animationDuration: 0.0)
        adjustNavigationBarButtons()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppContainerViewController.deviceOrientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    @IBAction func userTapsOutsideOfDrawer(_ sender: Any) {
        drawerShowing = false
    }
    
    @IBAction func userRequestsToggleDrawer(_ sender: Any) {
        drawerShowing = !drawerShowing
    }
    
    @IBAction func userTapsSecondRightButton(_ sender: Any) {
        mapViewController?.userRequestsZoomOnUserLocation()
    }
    
    @IBAction func userTapsRightButton(_ sender: Any) {
        mapViewController?.userRequestsAddNewFeature()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var destination = segue.destination as? DrawerViewReferencable {
            destination.drawerView = self
        }
        if let destination = segue.destination as? MapViewController {
            destination.delegate = self
            mapViewController = destination
        }
        else if let destination = segue.destination as? DrawerViewController {
            destination.contextViewControllerJobDelegate = self
            drawerViewController = destination
        }
        else if let destination = segue.destination as? JobStatusViewController {
            destination.jobConstruct = EphemeralCache.get(objectForKey: AppOfflineMapJobConstructionInfo.EphemeralCacheKeys.offlineMapJob) as? AppOfflineMapJobConstructionInfo
            destination.delegate = self
            jobStatusViewController = destination
        }
    }
    
    @objc func deviceOrientationDidChange() {
        adjustForDrawerShowing(animationDuration: 0.0)
    }
    
    func adjustForDrawerShowing(animationDuration: TimeInterval = 0.2) {
        
        drawerLeadingLayoutConstraint.constant = drawerShowing ? 0.0 : -contextView.frame.size.width

        UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            self?.adjustVisualEffectViewForDrawerShowing()
        }) { [weak self] (_) in
            self?.adjustVisualEffectViewIsUserInteractionEnabled()
        }
    }
    
    private func adjustVisualEffectViewForDrawerShowing() {
        self.visualEffectView.effect = self.drawerShowing ? UIBlurEffect(style: .light) : nil
    }
    
    private func adjustVisualEffectViewIsUserInteractionEnabled() {
        self.visualEffectView.isUserInteractionEnabled = self.drawerShowing
    }
    
    func adjustNavigationBarButtons() {
        
        rightBarButton?.isEnabled = !drawerShowing && showAddFeatureBarButton
        secondRightBarButton?.isEnabled = !drawerShowing && showZoomToLocationBarButton
        leftBarButton?.isEnabled = showProfileBarButton
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
}
