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

protocol DrawerViewControllerDelegate {
    
    func drawerViewController(didRequestWorkOnline drawerViewController: DrawerViewController)
    func drawerViewController(didRequestLoginLogout drawerViewController: DrawerViewController)
    func drawerViewController(didRequestSyncJob drawerViewController: DrawerViewController)
    func drawerViewController(didRequestWorkOffline drawerViewController: DrawerViewController)
    func drawerViewController(didRequestDeleteMap drawerViewController: DrawerViewController)
}

class DrawerViewController: AppContextAwareController {
    
    @IBOutlet weak var workModeHighlightView: UIView!

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var workOnlineButton: UIButton!
    @IBOutlet weak var workOfflineButton: UIButton!
    @IBOutlet weak var synchronizeOfflineMapButton: UIButton!
    @IBOutlet weak var deleteOfflineMapButton: UIButton!
    
    var contextViewControllerJobDelegate: DrawerViewControllerDelegate?
    
    let loginLogoutButtonControlStateColors: [UIControlState: UIColor] = {
        return [.normal: appColors.loginLogoutNormal,
                .highlighted: appColors.loginLogoutHighlighted]
    }()
    
    let workModeControlStateColors: [UIControlState: UIColor] = {
        return [.normal: appColors.workModeNormal,
                .highlighted: appColors.workModeHighlighted,
                .selected: appColors.workModeSelected,
                .disabled: appColors.workModeDisabled]
    }()
    
    let offlineActivityControlStateColors: [UIControlState: UIColor] = {
        return [.normal: appColors.offlineActivityNormal,
                .highlighted: appColors.offlineActivityHighlighted,
                .selected: appColors.offlineActivitySelected,
                .disabled: appColors.offlineActivityDisabled]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setButtonImageTints()
        setButtonAttributedTitles()
    }
    
    func setButtonImageTints() {
        
        workOnlineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        workOfflineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        synchronizeOfflineMapButton.setTintColors(forControlStateColors: offlineActivityControlStateColors)
        deleteOfflineMapButton.setTintColors(forControlStateColors: offlineActivityControlStateColors)
    }
    
    func setButtonAttributedTitles() {
        
        updateLoginButtonForAuthenticatedUsername(user: appContext.user)
        workOnlineButton.setAttributed(header: "Work Online", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader)
        workOfflineButton.setAttributed(header: "Work Offline", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader)
        updateSynchronizeButtonForLastSync(date: appContext.lastSync.date)
        deleteOfflineMapButton.setAttributed(header: "Delete Offline Map", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    
    @IBAction func userRequestsLoginLogout(_ sender: Any) {
        contextViewControllerJobDelegate?.drawerViewController(didRequestLoginLogout: self)
    }
    
    @IBAction func userRequestsWorkOnline(_ sender: Any) {
        
        guard appContext.workMode == .offline else {
            return
        }
        
        guard appReachability.isReachable else {
            present(simpleAlertMessage: "Your device must be connected to a network to work online.", animated: true, completion: nil)
            return
        }
        
        contextViewControllerJobDelegate?.drawerViewController(didRequestWorkOnline: self)
    }
    
    @IBAction func userRequestsWorkOffline(_ sender: Any) {
        
        guard appContext.workMode == .online else {
            return
        }
        
        guard appContext.isLoggedIn else {
            present(loginAlertMessage: "You must log in to work offline.")
            return
        }
        
        if !appContext.hasOfflineMap && !appReachability.isReachable {
            present(simpleAlertMessage: "Your device must be connected to a network to work online.", animated: true, completion: nil)
            return
        }

        contextViewControllerJobDelegate?.drawerViewController(didRequestWorkOffline: self)
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
        
        guard appContext.isLoggedIn else {
            present(loginAlertMessage: "You must log in to download map offline.")
            return
        }
        
        contextViewControllerJobDelegate?.drawerViewController(didRequestSyncJob: self)
    }
    
    @IBAction func userRequestsDeleteOfflineMap(_ sender: Any) {
        
        guard appContext.hasOfflineMap else {
            present(simpleAlertMessage: "Unknown Error: your device doesn't have an offline map.", animated: true, completion: nil)
            return
        }
        
        guard appContext.isLoggedIn else {
            present(loginAlertMessage: "You must log in to download map offline.")
            return
        }
        
        contextViewControllerJobDelegate?.drawerViewController(didRequestDeleteMap: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        adjustContextDrawerUI()
    }
    
    func adjustContextDrawerUI() {
        
        workModeHighlightView.frame = appContext.workMode == .online ? workOnlineButton.frame : workOfflineButton.frame
        
        workOnlineButton.isEnabled = appContext.workMode == .offline ? appReachability.isReachable : true
        workOnlineButton.isSelected = appContext.workMode == .online
        
        if appReachability.isReachable {
            workOnlineButton.setAttributed(header: appContext.workMode == .online ? "Working Online" : "Work Online", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader)
        }
        else {
            workOnlineButton.setAttributed(header: appContext.workMode == .online ? "Working Online" : "Work Online", subheader: "no network connectivity", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
        }
        
        workOfflineButton.isEnabled = appContext.hasOfflineMap || appReachability.isReachable
        workOfflineButton.isSelected = appContext.workMode == .offline
        
        if appContext.isLoggedIn {
            workOfflineButton.setAttributed(header: appContext.workMode == .offline ? "Working Offline" : "Work Offline", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader)
        }
        else {
            workOfflineButton.setAttributed(header: appContext.workMode == .offline ? "Working Offline" : "Work Offline", subheader: "user isn't logged in", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
        }

        synchronizeOfflineMapButton.isEnabled = appContext.hasOfflineMap && appContext.isLoggedIn && appReachability.isReachable
        synchronizeOfflineMapButton.isSelected = false
        
        deleteOfflineMapButton.isEnabled = appContext.hasOfflineMap && appContext.isLoggedIn
        deleteOfflineMapButton.isSelected = false
    }
    
    private func updateLoginButtonForAuthenticatedUserProfileImage(user: AGSPortalUser?) {
        
        if let currentUser = user {
            
            let fallbackProfileImage = UIImage(named: "MissingProfile")!.withRenderingMode(.alwaysOriginal).circularThumbnail(ofSize: 36, strokeColor: appColors.loginLogoutNormal)
            
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
                
                guard let img = image.image, let profImage = img.circularThumbnail(ofSize: 36, strokeColor: appColors.loginLogoutNormal) else {
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
            loginButton.setAttributed(header: "Log out", subheader: currentUser.username, forControlStateColors: loginLogoutButtonControlStateColors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
        }
        else {
            loginButton.setAttributed(header: "Log in", forControlStateColors: loginLogoutButtonControlStateColors, headerFont: appFonts.drawerButtonHeader)
        }
    }
    
    override var appContextNotificationRegistrations: [AppContextChangeNotification] {
        
        let currentUserNotification = AppContextChangeNotification.currentUser { [weak self] user in
            self?.updateLoginButtonForAuthenticatedUserProfileImage(user: user)
            self?.updateLoginButtonForAuthenticatedUsername(user: user)
        }
        
        let workModeNotification = AppContextChangeNotification.workMode { [weak self] workMode in
            self?.adjustContextDrawerUI()
        }
        
        let reachabilityNotification = AppContextChangeNotification.reachability { [weak self] reachable in
            self?.adjustContextDrawerUI()
        }
        
        let lastSyncNotification = AppContextChangeNotification.lastSync { [weak self] date in
            self?.updateSynchronizeButtonForLastSync(date: date)
        }
        
        let hasOfflineMap = AppContextChangeNotification.hasOfflineMap { [weak self] hasOfflineMap in
            self?.adjustContextDrawerUI()
        }
        
        return [currentUserNotification, workModeNotification, reachabilityNotification, lastSyncNotification, hasOfflineMap]
    }
    
    func updateSynchronizeButtonForLastSync(date: Date?) {
        
        if let lastSynchronized = date {
            synchronizeOfflineMapButton.setAttributed(header: "Synchronize Offline Map", subheader: "last synchronized \(lastSynchronized.formattedString)", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
        }
        else {
            synchronizeOfflineMapButton.setAttributed(header: "Synchronize Offline Map", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader)
        }
    }
}

