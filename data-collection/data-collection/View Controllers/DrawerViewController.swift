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
    
    var observeCurrentUser: NSKeyValueObservation?
    var observeOfflineMap: NSKeyValueObservation?
    
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
        
        beginObservingCurrentUser()
        beginObservingOfflineMap()
        
        setButtonImageTints()
//        setButtonAttributedTitles()
    }
    
    func setButtonImageTints() {
        
        workOnlineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        workOfflineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        synchronizeOfflineMapButton.setTintColors(forControlStateColors: offlineActivityControlStateColors)
        deleteOfflineMapButton.setTintColors(forControlStateColors: offlineActivityControlStateColors)
    }
    
    func setButtonAttributedTitles() {

        workOnlineButton.setAttributedTitle(header: "Work Online", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader)
        workOfflineButton.setAttributedTitle(header: "Work Offline", forControlStateColors: workModeControlStateColors, headerFont: appFonts.drawerButtonHeader)
        synchronizeOfflineMapButton.setAttributedTitle(header: "Synchronize Offline Map", subheader: "Last synchronized ..", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
        deleteOfflineMapButton.setAttributedTitle(header: "Delete Offline Map", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader)
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
        
        let workModeIndicatorAnimation:()->Void = { [weak self] in
            guard let online = self?.workOnlineButton.frame, let offline = self?.workOfflineButton.frame else {
                return
            }
            self?.workModeHighlightView.frame = appContext.workMode == .online ? online : offline
        }
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseOut, animations: workModeIndicatorAnimation, completion: nil)
        
        workOnlineButton.isEnabled = appReachability.isReachable
        workOnlineButton.isSelected = appContext.workMode == .online
        
        workOfflineButton.isEnabled = appContext.hasOfflineMap || appReachability.isReachable
        workOfflineButton.isSelected = appContext.workMode == .offline
        
        synchronizeOfflineMapButton.isEnabled = appContext.hasOfflineMap && appContext.isLoggedIn && appReachability.isReachable
        synchronizeOfflineMapButton.isSelected = false
        
        if let lastSynchronized = appContext.lastSync.date {
            synchronizeOfflineMapButton.setAttributedTitle(header: "Synchronize Offline Map", subheader: "last synchronized \(lastSynchronized.formattedString)", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
        }
        else {
            synchronizeOfflineMapButton.setAttributedTitle(header: "Synchronize Offline Map", forControlStateColors: offlineActivityControlStateColors, headerFont: appFonts.drawerButtonHeader)
        }
        
        deleteOfflineMapButton.isEnabled = appContext.hasOfflineMap && appContext.isLoggedIn
        deleteOfflineMapButton.isSelected = false
    }
    
    private func beginObservingCurrentUser() {
        observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { [weak self] (context, _) in
            print("[Authentication] user is", appContext.isLoggedIn ? "logged in." : "logged out.")
            
            // TODO update.
            guard let colors = self?.workModeControlStateColors else {
                return
            }
            
            if let currentUser = appContext.user {
                self?.loginButton.setAttributedTitle(header: "Log out", subheader: currentUser.username, forControlStateColors: colors, headerFont: appFonts.drawerButtonHeader, subheaderFont: appFonts.drawerButtonSubheader)
                let fallbackProfileImage = UIImage(named: "MissingProfile")!.withRenderingMode(.alwaysOriginal)
                guard let image = currentUser.thumbnail else {
                    self?.loginButton.setImage(fallbackProfileImage, for: .normal)
                    return
                }
                image.load(completion: { (error: Error?) in
                    self?.loginButton.setImage(fallbackProfileImage, for: .normal)
                    guard error == nil else {
                        print("[Error: User Thumbnail Image Load]", error!.localizedDescription)
                        return
                    }
                    guard let img = image.image, let profImage = img.circularThumbnail(ofSize: 36) else {
                        print("[Error: User Thumbnail Image Load] image processing error.")
                        return
                    }
                    self?.loginButton.setImage(profImage.withRenderingMode(.alwaysOriginal), for: .normal)
                })
            }
            else {
                self?.loginButton.setAttributedTitle(header: "Log in", forControlStateColors: colors, headerFont: appFonts.drawerButtonHeader)
                self?.loginButton.setImage(UIImage(named: "UserLoginIcon"), for: .normal)
            }
        }
    }
    
    private func beginObservingOfflineMap() {
        observeOfflineMap = appContext.observe(\.hasOfflineMap, options: [.new, .old]) { [weak self] (context, _) in
            self?.adjustContextDrawerUI()
        }
    }
    
    override func appWorkModeDidChange() {
        super.appWorkModeDidChange()
        adjustContextDrawerUI()
    }
    
    override func appReachabilityDidChange() {
        super.appReachabilityDidChange()
        adjustContextDrawerUI()
    }
    
    override func appLastSyncDidChange() {
        super.appLastSyncDidChange()
        adjustContextDrawerUI()
    }
    
    deinit {
        observeCurrentUser?.invalidate()
        observeCurrentUser = nil
        
        observeOfflineMap?.invalidate()
        observeOfflineMap = nil
    }
}

