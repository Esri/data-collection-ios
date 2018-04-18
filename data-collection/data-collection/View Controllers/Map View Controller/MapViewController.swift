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

enum MapViewMode {
    case `default`
    case disabled
    case selectedFeature
    case selectingFeature
    case offlineMask
    case offlineDownload
    case noMap
}

enum LocationSelectionViewType {
    
    case newFeature
    case offlineExtent
    
    var headerText: String {
        switch self {
        case .newFeature:
            return "Choose the location"
        case .offlineExtent:
            return "Select the region of the map to take offline"
        }
    }
    
    var subheaderText: String {
        switch self {
        case .newFeature:
            return "Pan and zoom map under pin"
        case .offlineExtent:
            return "Pan and zoom map within the rectangle"
        }
    }
}

protocol MapViewControllerDelegate {
    func mapViewController(_ mapViewController: MapViewController, didSelect extent: AGSEnvelope)
}

class MapViewController: AppContextAwareController {

    var delegate: MapViewControllerDelegate?
    
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var smallPopupView: UIView!
    @IBOutlet weak var selectView: UIView!
    @IBOutlet weak var pinDropView: PinDropView!
    @IBOutlet weak var activityBarView: ActivityBarView!
    @IBOutlet weak var notificationBar: NotificationBarLabel!
    @IBOutlet weak var compassView: CompassView!
    
    @IBOutlet weak var selectViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectViewHeaderLabel: UILabel!
    @IBOutlet weak var selectViewSubheaderLabel: UILabel!
    
    var featureDetailViewBottomConstraint: NSLayoutConstraint!
    
    var observeDrawStatus: NSKeyValueObservation?
    var observeLocationAuthorization: NSKeyValueObservation?
    var observeCurrentMap: NSKeyValueObservation?
    
    var locationSelectionType: LocationSelectionViewType = .newFeature {
        didSet {
            updateSelectView(forType: locationSelectionType)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SETUPS
        setupMapViewAttributionBarAutoLayoutConstraints()
        setupMapView()
        
        // OBSERVERS
        setupObservers()
        
        //
        adjustForMapViewMode()
        
        let map = AGSMap(basemap: AGSBasemap.streetsVector())
        mapView.map = map
        mapView.map?.load(completion: { (error) in })
        
        // COMPASS
        compassView.mapView = mapView
        
        // ACTIVITY BAR
        activityBarView.mapView = mapView
        
        // Load Map and Services
        appContext.loadOfflineMobileMapPackageAndSetBestMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        adjustForLocationAuthorizationStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Setup
    
    func setupMapView() {
        mapView.touchDelegate = self
        mapView.releaseHardwareResourcesWhenBackgrounded = true
        mapView.interactionOptions.isMagnifierEnabled = true
    }
    
    func setupMapViewAttributionBarAutoLayoutConstraints() {
        featureDetailViewBottomConstraint = mapView.attributionTopAnchor.constraint(equalTo: smallPopupView.bottomAnchor, constant: 8)
        featureDetailViewBottomConstraint.isActive = true
    }
    
    // MARK: Observers
    
    func setupObservers() {
        beginObservingLocationAuthStatus()
        beginMonitoringMapviewLayerViewStateChanges()
        beginObservingCurrentMap()
    }
    
    private func beginObservingLocationAuthStatus() {
        observeLocationAuthorization = AppLocation.shared.observe(\.locationAuthorized, options:[.new, .old]) { [weak self] (appLocation, _) in
            print("[Location Authorization] is authorized: \(appLocation.locationAuthorized)")
            self?.adjustForLocationAuthorizationStatus()
        }
    }
    
    private func beginMonitoringMapviewLayerViewStateChanges() {
        mapView.layerViewStateChangedHandler = { (layer:AGSLayer, state:AGSLayerViewState) in
            print("[Layer View State] \(state) - \(layer.name)")
        }
    }
    
    private func beginObservingCurrentMap() {
        observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { [weak self] (appContext, _) in
            self?.mapView.map = appContext.currentMap
            if let map = appContext.currentMap {
                print("[Current Map] \(map)")
            }
            else {
                print("[Current Map] nil")
            }
        }
    }
    
    // MARK: Adjustments
    
    func adjustForLocationAuthorizationStatus() {
        mapView.locationDisplay.showLocation = AppLocation.shared.locationAuthorized
        mapView.locationDisplay.showAccuracy = AppLocation.shared.locationAuthorized
        if AppLocation.shared.locationAuthorized {
            mapView.locationDisplay.start { (err) in
                if let error = err {
                    print("[Error] Cannot display user location: \(error.localizedDescription)")
                }
            }
        }
        else {
            mapView.locationDisplay.stop()
        }
    }
    
    func invalidateAndReleaseObservations() {
        
        // Invalidate and release KVO observations
        observeDrawStatus?.invalidate()
        observeDrawStatus = nil
        
        observeLocationAuthorization?.invalidate()
        observeLocationAuthorization = nil
        
        observeCurrentMap?.invalidate()
        observeCurrentMap = nil
    }
    
    // MARK: Select View
    
    func prepareMapMaskViewForOfflineDownloadArea() {
        presentMapMaskViewForOfflineDownloadArea()
        mapViewMode = .offlineMask
    }
    
    @IBAction func userDidSelectLocation(_ sender: Any) {

        switch locationSelectionType {
        case .newFeature:
            break
        case .offlineExtent:
            prepareForOfflineMapDownloadJob()
            break
        }
        
        mapViewMode = .`default`
    }
    
    @IBAction func userDidCancelSelectLocation(_ sender: Any) {
        
        switch locationSelectionType {
        case .newFeature:
            break
        case .offlineExtent:
            hideMapMaskViewForOfflineDownloadArea()
            break
        }
        
        mapViewMode = .`default`
    }
    
    func updateSelectView(forType type: LocationSelectionViewType) {
        
        selectViewHeaderLabel.text = type.headerText
        selectViewSubheaderLabel.text = type.subheaderText
    }
    
    func userRequestsAddNewFeature() {
        
        // 1 User must be logged in, prompt if not.
        guard appContext.isLoggedIn else {
            present(loginAlertMessage: "You must log in to add a Tree.")
            return
        }
        
        mapViewMode = .selectingFeature
    }
    
    // MARK: User Location
    
    func userRequestsZoomOnUserLocation() {
        if AppLocation.shared.locationAuthorized {
            guard mapView.locationDisplay.showLocation == true, let location = mapView.locationDisplay.location, let position = location.position else {
                return
            }
            let scale = min(1500, mapView.mapScale)
            let viewpoint = AGSViewpoint(center: position, scale: scale)
            mapView.setViewpoint(viewpoint, duration: 1.2, completion: nil)
        }
        else {
            present(settingsAlertMessage: "You must enable Data Collection to access your location in your device's settings to zoom to your location.")
        }
    }
    
    // MARK: Map View Mode
    var mapViewMode: MapViewMode = .`default` {
        didSet {
            adjustForMapViewMode()
        }
    }
    
    func adjustForMapViewMode() {
        
        let smallPopViewVisible: (Bool) -> UIViewAnimations = { [unowned mvc = self] (visible) in
            return {
                mvc.smallPopupView.alpha = visible.asAlpha
                mvc.featureDetailViewBottomConstraint.constant = visible ? 8 : 28
            }
        }
        
        let selectViewVisible: (Bool) -> UIViewAnimations = { [unowned mvc = self] (visible) in
            return {
                mvc.selectViewTopConstraint.constant = visible ? 0 : -mvc.selectView.frame.height
                mvc.selectView.alpha = visible.asAlpha
            }
        }
        
        var animations = [UIViewAnimations]()
        
        switch mapViewMode {
            
        case .selectingFeature:
            pinDropView.pinDropped = true
            animations.append( selectViewVisible(true) )
            animations.append( smallPopViewVisible(false) )
            locationSelectionType = .newFeature
            
        case .selectedFeature:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(true) )
            
        case .offlineMask:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(true) )
            animations.append( smallPopViewVisible(false) )
            locationSelectionType = .offlineExtent
            
        default:
            pinDropView.pinDropped = false
            animations.append( selectViewVisible(false) )
            animations.append( smallPopViewVisible(false) )
        }
        
        UIView.animate(withDuration: 0.2) { [unowned mvc = self] in
            for animation in animations { animation() }
            mvc.view.layoutIfNeeded()
        }
    }
    
    // MARK: App Context
    
    override func appWorkModeDidChange() {
        
        super.appWorkModeDidChange()
        
        DispatchQueue.main.async { [weak self] in
            self?.activityBarView.colorA = (appContext.workMode == .online) ? AppColors.primaryLight : AppColors.offlineLight
            self?.activityBarView.colorB = (appContext.workMode == .online) ? AppColors.primaryDark : AppColors.offlineDark
            self?.notificationBar.backgroundColor = (appContext.workMode == .online) ? AppColors.offlineLight : AppColors.offlineDark
        }
    }
    
    deinit {
        // Remove gestures
        // TODO: needed?
        mapView.removeGestures()
        
        // Invalidate and release KVO observations
        invalidateAndReleaseObservations()
    }
}

extension MapViewController: AGSGeoViewTouchDelegate {
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didEndLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        query(geoView, atScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    private func query(_ geoView: AGSGeoView, atScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
//
//        guard let map = mapView.map, map.loadStatus == .loaded, newTreeUIVisible == false, let treeManager = appTreesManager else {
//            return
//        }
//
//        selectedTreeDetailViewLoading = true
//
//        queryForTreeAtMapPoint?.cancel()
//        queryForTreeAtMapPoint = nil
//
//        // Extension bridge between AGSGeoView identifyTree(::::::) with ArcGIS runtime feature service layers.
//        // See: AGSGeoView+Extensions.swift
//        queryForTreeAtMapPoint = geoView.identifyTree(atScreenPoint: screenPoint, tolerance: 8, returnPopupsOnly: false, maximumResults: 8)  { [weak self] (result) in
//
//            treeManager.clearSelections()
//
//            guard let queryResult = result else {
//                self?.selectedTree = nil
//                self?.queryForTreeAtMapPoint = nil
//                return
//            }
//
//            guard
//                let features = queryResult.geoElements as? [AGSArcGISFeature],
//                let feature = features.featureNearestTo(mapPoint: mapPoint)
//                else {
//
//                    self?.mapViewNotificationBarLabel.showLabel(withNotificationMessage: "Did not find a tree at that location.", forDuration: 2.0)
//                    self?.selectedTree = nil
//                    self?.queryForTreeAtMapPoint = nil
//                    return
//            }
//
//            treeManager.tree(forSelectedFeature: feature) { (tree) in
//
//                self?.selectedTree = tree
//                self?.queryForTreeAtMapPoint = nil
//
//                if let point = feature.geometry as? AGSPoint, let scale = self?.mapView.mapScale {
//
//                    let viewpoint = AGSViewpoint(center: point, scale: scale)
//                    self?.mapView.setViewpoint(viewpoint, duration: 1.2, completion: nil)
//                }
//            }
//        }
    }
}
