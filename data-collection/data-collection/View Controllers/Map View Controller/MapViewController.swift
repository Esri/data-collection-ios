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

protocol MapViewControllerDelegate: AnyObject {
    func mapViewController(_ mapViewController: MapViewController, didSelect extent: AGSGeometry)
    func mapViewController(_ mapViewController: MapViewController, shouldAllowNewFeature: Bool)
    func mapViewController(_ mapViewController: MapViewController, didUpdateTitle title: String)
}

class MapViewController: UIViewController {
    
    struct EphemeralCacheKeys {
        static let newSpatialFeature = "MapViewController.newFeature.spatial"
        static let newNonSpatialFeature = "MapViewController.newFeature.nonspatial"
        static let newRelatedRecord = "MapViewController.newRelatedRecord"
    }
    
    enum LocationSelectionViewType {
        case newFeature
        case offlineExtent
    }
    
    enum MapViewMode: Equatable {
        case defaultView
        case disabled
        case selectedFeature(featureLoaded: Bool)
        case selectingFeature
        case offlineMask
    }

    weak var delegate: MapViewControllerDelegate?
    
    let changeHandler = AppContextChangeHandler()

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var smallPopupView: ShrinkingView!
    @IBOutlet weak var popupsContainerView: UIView!
    @IBOutlet weak var addPopupRelatedRecordButton: UIButton!
    @IBOutlet weak var selectView: UIView!
    @IBOutlet weak var pinDropView: PinDropView!
    weak var activityBarView: ActivityBarView!
    @IBOutlet weak var slideNotificationView: SlideNotificationView!
    @IBOutlet weak var compassView: CompassView!
    @IBOutlet weak var reloadMapButton: UIButton!
    
    @IBOutlet weak var relatedRecordHeaderLabel: UILabel!
    @IBOutlet weak var relatedRecordSubheaderLabel: UILabel!
    @IBOutlet weak var relatedRecordsNLabel: UILabel!
    
    @IBOutlet var selectViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectViewHeaderLabel: UILabel!
    @IBOutlet weak var selectViewSubheaderLabel: UILabel!
    
    var maskViewController: MaskViewController!
    @IBOutlet weak var maskViewContainer: UIView!
    
    var featureDetailViewBottomConstraint: NSLayoutConstraint!
    
    var visibleAreaObserver: NSKeyValueObservation?

    var identifyOperation: AGSCancelable?
    
    var currentPopup: RichPopup? {
        willSet {
            currentPopup?.clearSelection()
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
        
        // Assign the map view touch delegate and other configurations.
        setupMapView()
        
        // Builds and constrains the activity view to the map view.
        setupActivityBarView()
        
        // Ensure the map view attribution bar top auto layout constraint is attached to the small pop-up view.
        setupMapViewAttributionBarAutoLayoutConstraints()
        
        // Set up the small pop-up view.
        setupSmallPopupView()

        // Set initial map view mode.
        adjustForMapViewMode(from: nil, to: mapViewMode)
        
        // Associate the compass view to the map view.
        compassView.mapView = mapView
        
        // Begin listening to changes to the app context.
        subscribeToAppContextChanges()
        
        // Load map from the app context.
        appContext.loadOfflineMobileMapPackageAndSetMapForCurrentWorkMode()
        
        // Adjust location display for app location authorization status. If location authorized is undetermined, this will prompt the user for authorization.
        adjustForLocationAuthorizationStatus()
        
        // If device is not reachable upon launch, inform the end-user.
        displayInitialReachabilityMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshCurrentPopup()
    }
    
    @IBAction func userRequestsReloadMap(_ sender: Any) {
        loadMapViewMap()
    }
    
    @IBAction func userRequestsAddNewRelatedRecord(_ sender: Any) {
        
        guard
            let parentPopup = currentPopup,
            let parentRelationships = parentPopup.relationships,
            let childPopup = parentPopup.relationships?.oneToMany.first?.relatedTable?.createPopup()
            else {
            present(simpleAlertMessage: "Uh Oh! You are unable to add a new related record.")
            return
        }
        
        SVProgressHUD.show(withStatus: String(format: "Creating new %@.", (childPopup.title ?? "related record")))

        parentRelationships.load { [weak self] (error) in
            
            SVProgressHUD.dismiss()
            
            guard let self = self else { return }
            
            guard error == nil else {
                self.present(simpleAlertMessage: error!.localizedDescription)
                return
            }
            
            EphemeralCache.set(object: (parentPopup, RichPopup(popup: childPopup)), forKey: EphemeralCacheKeys.newRelatedRecord)
            
            self.performSegue(withIdentifier: "modallyPresentRelatedRecordsPopupViewController", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.navigationDestination as? RichPopupViewController {
            if let newPopup = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newSpatialFeature) as? RichPopup {
                currentPopup = newPopup
                mapViewMode = .selectedFeature(featureLoaded: false)
                destination.popup = newPopup
                destination.shouldBeginEditPopupUponLoad = true
            }
            else if let (parentPopup, childPopup) = EphemeralCache.get(objectForKey: EphemeralCacheKeys.newRelatedRecord) as? (RichPopup, RichPopup) {
                destination.parentPopup = parentPopup
                destination.popup = childPopup
                destination.shouldBeginEditPopupUponLoad = true
            }
            else {
                destination.popup = currentPopup!
            }
        }
        else if let destination = segue.destination as? MaskViewController {
            maskViewController = destination
        }
    }
    
    private func displayInitialReachabilityMessage() {
        if !appReachability.isReachable { displayReachabilityMessage(isReachable: false) }
    }
    
    private func displayReachabilityMessage(isReachable reachable: Bool) {
        slideNotificationView.showLabel(withNotificationMessage: String(format: "Device %@ connection to the network.", (reachable ? "gained" : "lost")), forDuration: 6.0)
    }
    
    func subscribeToAppContextChanges() {
        
        let currentMapChange: AppContextChange = .currentMap { [weak self] currentMap in
            self?.mapViewMode = .defaultView
            self?.currentPopup = nil
            self?.mapView.map = currentMap
            self?.loadMapViewMap()
        }
        
        let locationAuthorizationChange: AppContextChange = .locationAuthorization { [weak self] authorized in
            self?.adjustForLocationAuthorizationStatus()
        }

        let workModeChange: AppContextChange = .workMode { [weak self] workMode in
            let color: UIColor = (workMode == .online) ? .primary : .offline
            self?.activityBarView.colors = (color.lighter, color.darker)
            self?.slideNotificationView.messageBackgroundColor = (workMode == .online) ? UIColor.primary.lighter : UIColor.offline.darker
            self?.slideNotificationView.messageTextColor = .tint
        }
        
        let reachabilityChange: AppContextChange = .reachability { [weak self] reachable in
            self?.displayReachabilityMessage(isReachable: reachable)
        }

        changeHandler.subscribe(toChanges: [currentMapChange, locationAuthorizationChange, workModeChange, reachabilityChange])
    }
}
