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

class MapViewController: AppContextAwareController, PopupsViewControllerEmbeddable {    

    var delegate: MapViewControllerDelegate?

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var popupsContainerView: UIView!
    @IBOutlet weak var selectView: UIView!
    @IBOutlet weak var pinDropView: PinDropView!
    @IBOutlet weak var activityBarView: ActivityBarView!
    @IBOutlet weak var notificationBar: NotificationBarLabel!
    @IBOutlet weak var compassView: CompassView!
    
    @IBOutlet weak var selectViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectViewHeaderLabel: UILabel!
    @IBOutlet weak var selectViewSubheaderLabel: UILabel!
    
    var smallPopupViewController: SmallPopupViewController?
    
    var featureDetailViewBottomConstraint: NSLayoutConstraint!
    
    var observeLocationAuthorization: NSKeyValueObservation?
    var observeCurrentMap: NSKeyValueObservation?
    
    var identifyOperation: AGSCancelable?
    
    var currentPopup: AGSPopup? {
        didSet {
            updateUIForCurrentTree()
        }
    }
    
    func updateUIForCurrentTree() {
        smallPopupViewController?.popup = currentPopup
        guard currentPopup != nil else {
            mapViewMode = .defaultView
            return
        }
        smallPopupViewController?.popuplateViewWithBestContent { [weak self] in
            guard let _ = self?.currentPopup else {
                self?.mapViewMode = .defaultView
                return
            }
            self?.mapViewMode = .selectedFeature
        }
    }
    
    var mapViewMode: MapViewMode = .defaultView {
        didSet {
            adjustForMapViewMode(from: oldValue, to: mapViewMode)
        }
    }
    
    var locationSelectionType: LocationSelectionViewType = .newFeature {
        didSet {
            adjustForLocationSelectionType()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MAPVIEW
        setupMapView()
        
        // SETUPS
        setupMapViewAttributionBarAutoLayoutConstraints()
        
        // SMALL POPUP
        setupSmallPopupViewController()
        
        // OBSERVERS
        setupObservers()

        // MAPVIEWMODE
        adjustForMapViewMode(from: nil, to: mapViewMode)
        
        // LOCATION SELECTION TYPE
        adjustForLocationSelectionType()
        
        // COMPASS
        compassView.mapView = mapView
        
        // ACTIVITY BAR
        activityBarView.mapView = mapView
        
        // Load Map and Services
        appContext.loadOfflineMobileMapPackageAndSetBestMap()
    }
    
    // MARK: SMALL POPUP
    
    func setupSmallPopupViewController() {
        
        smallPopupViewController = embedPopupsSmallViewController()

        (popupsContainerView as! ShrinkingView).actionClosure = { [weak self] in
            
            // todo change strongSElf
            guard let strongSelf = self, strongSelf.currentPopup != nil else {
                return
            }
            strongSelf.performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.navigationDestination as? RelatedRecordsPopupsViewController {
            if let newPopup = EphemeralCache.get(objectForKey: "MapViewController.newFeature.spatial") as? AGSPopup {
                destination.popup = newPopup
                destination.editingPopup = true
                // TODO : Toggle Bool for edit mode
            }
            else {
                destination.popup = currentPopup!
            }
        }
    }

    //
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        adjustForLocationAuthorizationStatus()
        updateUIForCurrentTree()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func appWorkModeDidChange() {
        
        super.appWorkModeDidChange()
        
        DispatchQueue.main.async { [weak self] in
            self?.activityBarView.colorA = (appContext.workMode == .online) ? AppConfiguration.appColors.primary.lighter : AppConfiguration.appColors.offlineLight
            self?.activityBarView.colorB = (appContext.workMode == .online) ? AppConfiguration.appColors.primary.darker : AppConfiguration.appColors.offlineDark
            self?.notificationBar.backgroundColor = (appContext.workMode == .online) ? AppConfiguration.appColors.primary.lighter : AppConfiguration.appColors.offlineDark
        }
    }
    
    deinit {        
        // Invalidate and release KVO observations
        invalidateAndReleaseObservations()
    }
}
