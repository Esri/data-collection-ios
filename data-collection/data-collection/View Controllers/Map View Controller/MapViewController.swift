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
    
    struct EphemeralCacheKeys {
        static let newSpatialFeature = "MapViewController.newFeature.spatial"
        static let newNonSpatialFeature = "MapViewController.newFeature.nonspatial"
        static let newRelatedRecord = "MapViewController.newRelatedRecord"
    }

    var delegate: MapViewControllerDelegate?

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var smallPopupView: ShrinkingView!
    @IBOutlet weak var popupsContainerView: UIView!
    @IBOutlet weak var addPopupRelatedRecordButton: UIButton!
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
        willSet {
            currentPopup?.clearSelection()
        }
        didSet {
            updateUIForCurrentPopup()
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
        appContext.loadOfflineMobileMapPackageAndSetMapForCurrentWorkMode()
    }
    
    // MARK: SMALL POPUP
    
    func setupSmallPopupViewController() {
        
        smallPopupViewController = embedPopupsSmallViewController()

        smallPopupView.actionClosure = { [weak self] in
            
            guard self?.currentPopup != nil else {
                return
            }
            self?.performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
        }
    }
    
    func updateUIForCurrentPopup() {
        
        smallPopupViewController?.popup = currentPopup
        
        guard currentPopup != nil else {
            mapViewMode = .defaultView
            return
        }
        
        currentPopup!.select()
        
        smallPopupViewController?.populateWithRelatedRecordContent { [weak self] in
            
            self?.addPopupRelatedRecordButton.isHidden = false

            if let canAdd = self?.smallPopupViewController?.oneToManyRelatedRecordTable?.canAddFeature {
                self?.addPopupRelatedRecordButton.isHidden = !canAdd
            }
            
            guard let _ = self?.currentPopup else {
                self?.mapViewMode = .defaultView
                return
            }
            
            self?.mapViewMode = .selectedFeature
        }
    }
    
    @IBAction func userRequestsAddNewRelatedRecord(_ sender: Any) {
        
        guard appContext.isLoggedIn else {
            self.present(loginAlertMessage: "You must log in to add a related record.")
            return
        }
        
        guard
            let parentPopup = currentPopup,
            let featureTable = smallPopupViewController?.oneToManyRelatedRecordTable,
            let childPopup = featureTable.createPopup()
            else {
            present(simpleAlertMessage: "Uh Oh! You are unable to add a new related record.")
            return
        }
        
        SVProgressHUD.show(withStatus: "Creating new \(childPopup.title ?? "related record").")
        let parentPopupManager = PopupRelatedRecordsManager(popup: parentPopup)
        parentPopupManager.loadRelatedRecords { [weak self] in
            EphemeralCache.set(object: (parentPopupManager, childPopup), forKey: EphemeralCacheKeys.newRelatedRecord)
            SVProgressHUD.dismiss()
            self?.performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.navigationDestination as? RelatedRecordsPopupsViewController {
            if let newPopup = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newSpatialFeature) as? AGSPopup {
                currentPopup = newPopup
                destination.popup = newPopup
                destination.editPopup(true)
            }
            else if let (parentPopupManager, childPopup) = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newRelatedRecord) as? (PopupRelatedRecordsManager, AGSPopup) {
                destination.parentRecordsManager = parentPopupManager
                destination.popup = childPopup
                destination.editPopup(true)
            }
            else {
                destination.popup = currentPopup!
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        adjustForLocationAuthorizationStatus()
        
        if let popup = currentPopup, !popup.isFeatureAddedToTable {
            currentPopup = nil
        }
        
        updateUIForCurrentPopup()
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
