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

protocol MapViewControllerDelegate: class {
    func mapViewController(_ mapViewController: MapViewController, didSelect extent: AGSEnvelope)
    func mapViewController(_ mapViewController: MapViewController, shouldAllowNewFeature: Bool)
    func mapViewController(_ mapViewController: MapViewController, didUpdateTitle title: String)
}


class MapViewController: AppContextAwareController {
    
    struct EphemeralCacheKeys {
        static let newSpatialFeature = "MapViewController.newFeature.spatial"
        static let newNonSpatialFeature = "MapViewController.newFeature.nonspatial"
        static let newRelatedRecord = "MapViewController.newRelatedRecord"
    }

    var mapDelegate: MapViewControllerDelegate?

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var smallPopupView: ShrinkingView!
    @IBOutlet weak var popupsContainerView: UIView!
    @IBOutlet weak var addPopupRelatedRecordButton: UIButton!
    @IBOutlet weak var selectView: UIView!
    @IBOutlet weak var pinDropView: PinDropView!
    @IBOutlet weak var activityBarView: ActivityBarView!
    @IBOutlet weak var notificationBar: NotificationBarLabel!
    @IBOutlet weak var compassView: CompassView!
    @IBOutlet weak var reloadMapButton: UIButton!
    
    @IBOutlet weak var relatedRecordHeaderLabel: UILabel!
    @IBOutlet weak var relatedRecordSubheaderLabel: UILabel!
    @IBOutlet weak var relatedRecordsNLabel: UILabel!
    
    @IBOutlet weak var selectViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectViewHeaderLabel: UILabel!
    @IBOutlet weak var selectViewSubheaderLabel: UILabel!
        
    var featureDetailViewBottomConstraint: NSLayoutConstraint!

    var identifyOperation: AGSCancelable?
    
    var currentPopup: AGSPopup? {
        set {
            recordsManager = newValue != nil ? PopupRelatedRecordsManager(popup: newValue!) : nil
        }
        get {
            return recordsManager?.popup
        }
    }
    
    internal private(set) var recordsManager: PopupRelatedRecordsManager? {
        willSet {
            recordsManager?.popup.clearSelection()
        }
        didSet {
            updateSmallPopupViewForCurrentPopup()
        }
    }
    
    var oneToManyRelatedRecordTable: AGSArcGISFeatureTable? {
        return recordsManager?.oneToMany.first?.relatedTable
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
        setupSmallPopupView()

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        adjustForLocationAuthorizationStatus()
        
        displayInitialReachabilityMessage()
        
        if let popup = currentPopup, !popup.isFeatureAddedToTable {
            currentPopup = nil
        }
        
        updateSmallPopupViewForCurrentPopup()
    }
    
    @IBAction func userRequestsReloadMap(_ sender: Any) {
        loadMapViewMap()
    }
    
    @IBAction func userRequestsAddNewRelatedRecord(_ sender: Any) {
        
        guard appContext.isLoggedIn else {
            self.present(loginAlertMessage: "You must log in to add a related record.")
            return
        }
        
        guard
            let parentPopup = currentPopup,
            let featureTable = oneToManyRelatedRecordTable,
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
    
    private func displayInitialReachabilityMessage() {
        if !appReachability.isReachable { displayReachabilityMessage(isReachable: false) }
    }
    
    private func displayReachabilityMessage(isReachable reachable: Bool) {
        notificationBar.showLabel(withNotificationMessage: "Device \(reachable ? "gained" : "lost") connection to the network.", forDuration: 6.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var appContextNotificationRegistrations: [AppContextChangeNotification] {
        
        let workModeNotification = AppContextChangeNotification.workMode { [weak self] workMode in
            
            DispatchQueue.main.async { [weak self] in
                self?.activityBarView.colorA = (workMode == .online) ? appColors.primary.lighter : appColors.offlineLight
                self?.activityBarView.colorB = (workMode == .online) ? appColors.primary.darker : appColors.offlineDark
                self?.notificationBar.backgroundColor = (workMode == .online) ? appColors.primary.lighter : appColors.offlineDark
            }
        }
        
        let currentMapNotification: AppContextChangeNotification = .currentMap { [weak self] currentMap in
            
            self?.mapView.map = currentMap
            self?.loadMapViewMap()
        }
        
        let locationAuthorizationNotification: AppContextChangeNotification = .locationAuthorization { [weak self] authorized in
            
            self?.mapView.locationDisplay.showLocation = authorized
            self?.mapView.locationDisplay.showAccuracy = authorized
            
            if authorized {
                self?.mapView.locationDisplay.start { (err) in
                    if let error = err {
                        print("[Error] Cannot display user location: \(error.localizedDescription)")
                    }
                }
            }
            else {
                self?.mapView.locationDisplay.stop()
            }
        }
        
        let reachabilityNotification = AppContextChangeNotification.reachability { [weak self] reachable in
            self?.displayReachabilityMessage(isReachable: reachable)
        }
        
        return [workModeNotification, currentMapNotification, locationAuthorizationNotification, reachabilityNotification]
    }
}
