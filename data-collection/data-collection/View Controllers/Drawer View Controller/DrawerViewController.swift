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

import Foundation
import UIKit
import ArcGIS

protocol DrawerViewControllerDelegate: AnyObject {

    func drawerViewController(didRequestWorkOnline drawerViewController: DrawerViewController)
    func drawerViewController(didRequestLoginLogout drawerViewController: DrawerViewController)
    func drawerViewController(didRequestSyncJob drawerViewController: DrawerViewController)
    func drawerViewController(didRequestWorkOffline drawerViewController: DrawerViewController)
    func drawerViewController(didRequestDeleteMap drawerViewController: DrawerViewController)
}

class DrawerViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var workOnlineButton: UIButton!
    @IBOutlet weak var workOfflineButton: UIButton!
    @IBOutlet weak var synchronizeOfflineMapButton: UIButton!
    @IBOutlet weak var deleteOfflineMapButton: UIButton!
    @IBOutlet weak var appVersionLabel: UILabel!
    
    weak var delegate: DrawerViewControllerDelegate?
    
    let changeHandler = AppContextChangeHandler()
    
    let loginLogoutButtonControlStateColors: [UIControlState: UIColor] = {
        return [.normal: .loginLogoutNormal,
                .highlighted: .loginLogoutHighlighted]
    }()
    
    let workModeControlStateColors: [UIControlState: UIColor] = {
        return [.normal: .workModeNormal,
                .highlighted: .workModeHighlighted,
                .selected: .workModeSelected,
                .disabled: .workModeDisabled]
    }()
    
    let offlineActivityControlStateColors: [UIControlState: UIColor] = {
        return [.normal: .offlineActivityNormal,
                .highlighted: .offlineActivityHighlighted,
                .selected: .offlineActivitySelected,
                .disabled: .offlineActivityDisabled]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setAppVersionLabel()
        setButtonImageTints()
        setButtonAttributedTitles()
        subscribeToAppContextChanges()
    }
    
    func setAppVersionLabel() {
        
        appVersionLabel.text = "\(Bundle.AppNameVersionString)\n\(Bundle.ArcGISSDKVersionString)"
    }
    
    func setButtonImageTints() {
        
        workOnlineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        workOfflineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        synchronizeOfflineMapButton.setTintColors(forControlStateColors: offlineActivityControlStateColors)
        deleteOfflineMapButton.setTintColors(forControlStateColors: offlineActivityControlStateColors)
    }
    
    func setButtonAttributedTitles() {
        
        updateLoginButtonForAuthenticatedUsername(user: appContext.portal.user)
        workOnlineButton.setAttributed(header: "Work Online", forControlStateColors: workModeControlStateColors, headerFont: .drawerButtonHeader)
        workOfflineButton.setAttributed(header: "Work Offline", forControlStateColors: workModeControlStateColors, headerFont: .drawerButtonHeader)
        updateSynchronizeButtonForLastSync(date: appContext.mobileMapPackage?.lastSyncDate)
        deleteOfflineMapButton.setAttributed(header: "Delete Offline Map", forControlStateColors: offlineActivityControlStateColors, headerFont: .drawerButtonHeader)
    }
    
    @IBAction func userRequestsLoginLogout(_ sender: Any) {
        delegate?.drawerViewController(didRequestLoginLogout: self)
    }
    
    @IBAction func userRequestsWorkOnline(_ sender: Any) {
        
        guard appContext.workMode == .offline else {
            return
        }
        
        guard appReachability.isReachable else {
            present(simpleAlertMessage: "Your device must be connected to a network to work online.", animated: true, completion: nil)
            return
        }
        
        delegate?.drawerViewController(didRequestWorkOnline: self)
    }
    
    @IBAction func userRequestsWorkOffline(_ sender: Any) {
        
        guard appContext.workMode == .online else {
            return
        }
        
        if !appContext.hasOfflineMap && !appReachability.isReachable {
            present(simpleAlertMessage: "Your device must be connected to a network to work online.", animated: true, completion: nil)
            return
        }
        
        if !appContext.hasOfflineMap && !appContext.isCurrentMapLoaded {
            present(simpleAlertMessage: "Map must be loaded to work offline.", animated: true, completion: nil)
            return
        }

        delegate?.drawerViewController(didRequestWorkOffline: self)
    }
    
    @IBAction func userRequestsSynchronizeOfflineMap(_ sender: Any) {
        
        guard appReachability.isReachable else {
            present(simpleAlertMessage: "Your device must be connected to a network to synchronize the offline map.", animated: true, completion: nil)
            return
        }
        
        guard appContext.hasOfflineMap else {
            present(simpleAlertMessage: "Unknown Error: your device doesn't have an offline map.", animated: true, completion: nil)
            return
        }
        
        delegate?.drawerViewController(didRequestSyncJob: self)
    }
    
    @IBAction func userRequestsDeleteOfflineMap(_ sender: Any) {
        
        guard appContext.hasOfflineMap else {
            present(simpleAlertMessage: "Unknown Error: your device doesn't have an offline map.", animated: true, completion: nil)
            return
        }
        
        delegate?.drawerViewController(didRequestDeleteMap: self)
    }
    
    func adjustContextDrawerUI() {
        
        workOnlineButton.isEnabled = appContext.workMode == .offline ? appReachability.isReachable : true
        workOnlineButton.isSelected = appContext.workMode == .online
        workOnlineButton.backgroundColor = appContext.workMode == .online ? .accent : .clear

        if appReachability.isReachable {
            workOnlineButton.setAttributed(header: appContext.workMode == .online ? "Working Online" : "Work Online", forControlStateColors: workModeControlStateColors, headerFont: .drawerButtonHeader)
        }
        else {
            workOnlineButton.setAttributed(header: appContext.workMode == .online ? "Working Online" : "Work Online", subheader: "no network connectivity", forControlStateColors: workModeControlStateColors, headerFont: .drawerButtonHeader, subheaderFont: .drawerButtonSubheader)
        }
        
        workOfflineButton.isEnabled = appContext.hasOfflineMap || appReachability.isReachable
        workOfflineButton.isSelected = appContext.workMode == .offline
        workOfflineButton.backgroundColor = appContext.workMode == .offline ? .accent : .clear
        
        if !appContext.hasOfflineMap {
            workOfflineButton.setAttributed(header: appContext.workMode == .offline ? "Working Offline" : "Work Offline", subheader: "download map", forControlStateColors: workModeControlStateColors, headerFont: .drawerButtonHeader, subheaderFont: .drawerButtonSubheader)
        }
        else {
            workOfflineButton.setAttributed(header: appContext.workMode == .offline ? "Working Offline" : "Work Offline", forControlStateColors: workModeControlStateColors, headerFont: .drawerButtonHeader)
        }

        synchronizeOfflineMapButton.isEnabled = appContext.hasOfflineMap && appReachability.isReachable
        synchronizeOfflineMapButton.isSelected = false
        
        deleteOfflineMapButton.isEnabled = appContext.hasOfflineMap
        deleteOfflineMapButton.isSelected = false
    }    
    
    private func updateLoginButtonForAuthenticatedUserProfileImage(user: AGSPortalUser?) {
        
        if let currentUser = user {
            
            let fallbackProfileImage = UIImage(named: "MissingProfile")!.withRenderingMode(.alwaysOriginal).circularThumbnail(ofSize: 36, strokeColor: .loginLogoutNormal)
            
            guard let image = currentUser.thumbnail else {
                loginButton.setImage(fallbackProfileImage, for: .normal)
                return
            }
            
            image.load(completion: { [weak self] (error: Error?) in
                
                self?.loginButton.setImage(fallbackProfileImage, for: .normal)
                
                guard error == nil else {
                    print("[Error: User Thumbnail Image Load]", error!.localizedDescription)
                    return
                }
                
                guard let img = image.image, let profImage = img.circularThumbnail(ofSize: 36, strokeColor: .loginLogoutNormal) else {
                    print("[Error: User Thumbnail Image Load] image processing error.")
                    return
                }
                
                self?.loginButton.setImage(profImage.withRenderingMode(.alwaysOriginal), for: .normal)
            })
        }
        else {
            loginButton.setImage(UIImage(named: "UserLoginIcon"), for: .normal)
        }
    }
    
    private func updateLoginButtonForAuthenticatedUsername(user: AGSPortalUser?) {
        
        if let currentUser = user {
            loginButton.setAttributed(header: "Log out", subheader: currentUser.username, forControlStateColors: loginLogoutButtonControlStateColors, headerFont: .drawerButtonHeader, subheaderFont: .drawerButtonSubheader)
        }
        else {
            loginButton.setAttributed(header: "Log in", forControlStateColors: loginLogoutButtonControlStateColors, headerFont: .drawerButtonHeader)
        }
    }
    
    func subscribeToAppContextChanges() {
        
        let currentPortalChange: AppContextChange = .currentPortal { [weak self] portal in
            self?.updateLoginButtonForAuthenticatedUserProfileImage(user: portal.user)
            self?.updateLoginButtonForAuthenticatedUsername(user: portal.user)
        }
        
        let workModeChange: AppContextChange = .workMode { [weak self] _ in
            self?.adjustContextDrawerUI()
        }
        
        let reachabilityChange: AppContextChange = .reachability { [weak self] _ in
            self?.adjustContextDrawerUI()
        }
        
        let lastSyncChange: AppContextChange = .lastSync { [weak self] date in
            self?.updateSynchronizeButtonForLastSync(date: date)
        }
        
        let hasOfflineMapChange: AppContextChange = .hasOfflineMap { [weak self] _ in
            self?.adjustContextDrawerUI()
        }
        
        changeHandler.subscribe(toChanges: [currentPortalChange, workModeChange, reachabilityChange, lastSyncChange, hasOfflineMapChange])
    }
    
    func updateSynchronizeButtonForLastSync(date: Date?) {
        
        if let lastSynchronized = date {
            synchronizeOfflineMapButton.setAttributed(header: "Synchronize Offline Map", subheader: "last sync \(lastSynchronized.shortDateTimeFormatted)", forControlStateColors: offlineActivityControlStateColors, headerFont: .drawerButtonHeader, subheaderFont: .drawerButtonSubheader)
        }
        else {
            synchronizeOfflineMapButton.setAttributed(header: "Synchronize Offline Map", forControlStateColors: offlineActivityControlStateColors, headerFont: .drawerButtonHeader)
        }
    }
}

