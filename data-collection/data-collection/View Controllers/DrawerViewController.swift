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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginObservingCurrentUser()
        beginObservingOfflineMap()
        
        setButtonImageTints()
    }
    
    func setButtonImageTints() {
        
        let workModeControlStateColors: [UIControlState: UIColor] = [.normal: .darkGray,
                                                                     .highlighted: .lightGray,
                                                                     .selected: .white,
                                                                     .disabled: UIColor(white: 0.5, alpha: 0.5)]
        
        let secondaryButtonsControlStateColors: [UIControlState: UIColor] = [.normal: .darkGray,
                                                                             .highlighted: .lightGray,
                                                                             .selected: .lightGray,
                                                                             .disabled: UIColor(white: 0.5, alpha: 0.5)]
        
        workOnlineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        workOfflineButton.setTintColors(forControlStateColors: workModeControlStateColors)
        synchronizeOfflineMapButton.setTintColors(forControlStateColors: secondaryButtonsControlStateColors)
        deleteOfflineMapButton.setTintColors(forControlStateColors: secondaryButtonsControlStateColors)
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
        
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseOut, animations: {
            self.workModeHighlightView.frame = appContext.workMode == .online ? self.workOnlineButton.frame : self.workOfflineButton.frame
        }, completion: nil)
        
        workOnlineButton.isEnabled = appReachability.isReachable
        workOnlineButton.isSelected = appContext.workMode == .online
        workOnlineButton.tintColor = workOnlineButton.titleColor(for: workOnlineButton.state)
        
        workOfflineButton.isEnabled = appContext.hasOfflineMap || (appReachability.isReachable && appContext.isLoggedIn)
        workOfflineButton.isSelected = appContext.workMode == .offline
        workOfflineButton.tintColor = workOfflineButton.titleColor(for: workOfflineButton.state)
        
        synchronizeOfflineMapButton.isEnabled = appReachability.isReachable && appContext.hasOfflineMap && appContext.isLoggedIn
        synchronizeOfflineMapButton.isSelected = false
        synchronizeOfflineMapButton.tintColor = synchronizeOfflineMapButton.titleColor(for: synchronizeOfflineMapButton.state)
        
        deleteOfflineMapButton.isEnabled = appContext.hasOfflineMap && appContext.isLoggedIn
        deleteOfflineMapButton.isSelected = false
        deleteOfflineMapButton.tintColor = deleteOfflineMapButton.titleColor(for: deleteOfflineMapButton.state)
    }
    
    private func beginObservingCurrentUser() {
        observeCurrentUser = appContext.observe(\.user, options: [.new, .old]) { [weak self] (context, _) in
            print("[Authentication] user is", appContext.isLoggedIn ? "logged in." : "logged out.")
            
            if let currentUser = appContext.user {
                self?.loginButton.setTitle("Logout", for: .normal)
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
                self?.loginButton.setTitle("Login", for: .normal)
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
    
    deinit {
        observeCurrentUser?.invalidate()
        observeCurrentUser = nil
        
        observeOfflineMap?.invalidate()
        observeOfflineMap = nil
    }
}

