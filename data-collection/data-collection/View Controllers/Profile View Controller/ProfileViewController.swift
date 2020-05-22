//// Copyright 2020 Esri
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

protocol ProfileViewControllerOfflineDelegate: class {
    func profileViewControllerRequestsDownloadMapOfflineOnDemand(profileViewController: ProfileViewController)
}

class ProfileViewController: UITableViewController {
    
    weak var delegate: ProfileViewControllerOfflineDelegate!
    
    @IBOutlet weak var portalUserCell: PortalUserCell!
    @IBOutlet weak var workOnlineCell: WorkOnlineCell!
    @IBOutlet weak var workOfflineCell: WorkOfflineCell!
    @IBOutlet weak var synchronizeMapCell: SynchronizeMapCell!
    @IBOutlet weak var deleteMapCell: DeleteMapCell!
    @IBOutlet weak var metaDataCell: MetaDataCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The contents of a pop-up field is dynamic and thus the size of a table view cell's content view must be able to change.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        
        metaDataCell.appNameVersionLabel.text = Bundle.AppNameVersionString
        metaDataCell.sdkVersionLabel.text = Bundle.ArcGISSDKVersionString
        
        subscribeToAppContextChanges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustFor(workMode: appContext.workMode)
        adjustFor(portal: appContext.portal)
        adjustFor(reachable: appReachability.isReachable)
    }
    
    // MARK:- App Context Changes
    
    let changeHandler = AppContextChangeHandler()
    
    private func subscribeToAppContextChanges() {
        
        let currentPortalChange: AppContextChange = .currentPortal { [weak self] portal in
            self?.adjustFor(portal: portal)
        }
        
        let workModeChange: AppContextChange = .workMode { [weak self] workMode in
            self?.adjustFor(workMode: workMode)
        }
        
        let reachabilityChange: AppContextChange = .reachability { [weak self] reachable in
            self?.adjustFor(reachable: reachable)
        }
        
        let lastSyncChange: AppContextChange = .lastSync { [weak self] date in
//            self?.updateSynchronizeButtonForLastSync(date: date)
        }
        
        let hasOfflineMapChange: AppContextChange = .hasOfflineMap { [weak self] _ in
//            self?.adjustContextDrawerUI()
        }
        
        changeHandler.subscribe(toChanges:
            [
                currentPortalChange,
                workModeChange,
                reachabilityChange,
                lastSyncChange,
                hasOfflineMapChange
            ]
        )
    }
    
    // MARK:- Reachability
    
    private func adjustFor(reachable: Bool) {
        if reachable {
            workOnlineCell.subtitleLabel.isHidden = true
        }
        else {
            workOnlineCell.subtitleLabel.text = "no network connectivity"
            workOnlineCell.subtitleLabel.isHidden = false
        }
    }
    
    // MARK:- Work Mode
    
    private func adjustFor(workMode: WorkMode) {
        switch workMode {
        case .online:
            select(indexPath: .workOnline)
        case .offline:
            select(indexPath: .workOffline)
        }
    }
    
    private func workOnline() {
        
        guard appContext.workMode == .offline else { return }
        
        guard appReachability.isReachable else {
            present(
                simpleAlertMessage: "Your device must be connected to a network to work online.",
                animated: true,
                completion: nil
            )
            return
        }
        
        appContext.setWorkModeOnlineWithMapFromPortal()
    }
    
    private func workOffline() {
        
        guard appContext.workMode == .online else { return }
        
        if !appContext.setMapFromOfflineMobileMapPackage() {
            delegate?.profileViewControllerRequestsDownloadMapOfflineOnDemand(profileViewController: self)
        }
    }
    
    // MARK:- Portal
    
    private func adjustFor(portal: AGSPortal) {
        if let user = portal.user {
            set(user: user)
        }
        else {
            setNoUser()
        }
    }
        
    private func set(user: AGSPortalUser) {
         user.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                print(error)
                #warning("Present error alert to customer.")
                self.setNoUser()
            }
            else {
                self.portalUserCell.thumbnailImageView.isHidden = false
                self.portalUserCell.userEmailLabel.isHidden = false
                self.portalUserCell.userEmailLabel.text = user.email
                self.portalUserCell.userFullNameLabel.text = user.fullName
                self.portalUserCell.authButton.setTitle("Sign Out", for: .normal)
                self.portalUserCell.authButton.addTarget(self, action: #selector(Self.userRequestsSignOut), for: .touchUpInside)
                
                if let thumbnail = user.thumbnail {
                    thumbnail.load { (error) in
                        if let error = error {
                            print(error)
                            #warning("Set fallback image.")
                        }
                        else {
                            self.portalUserCell.thumbnailImageView.image = thumbnail.image
                        }
                    }
                }
            }
        }
    }
    
    private func setNoUser() {
        portalUserCell.thumbnailImageView.isHidden = true
        portalUserCell.userEmailLabel.isHidden = true
        portalUserCell.userFullNameLabel.text = "Portal"
        portalUserCell.authButton.setTitle("Sign In", for: .normal)
        portalUserCell.authButton.addTarget(self, action: #selector(userRequestsSignIn), for: .touchUpInside)
    }
    
    @objc private func userRequestsSignIn() {
        appContext.signIn()
    }
    
    @objc private func userRequestsSignOut() {
        appContext.signOut()
    }
    
    // MARK:- Sync
    
    private func synchronizeMap() {
        guard appReachability.isReachable else {
            present(
                simpleAlertMessage: "Your device must be connected to a network to synchronize the offline map.",
                animated: true,
                completion: nil
            )
            return
        }
        
        guard appContext.hasOfflineMap else {
            present(
                simpleAlertMessage: "Unknown Error: your device doesn't have an offline map.",
                animated: true,
                completion: nil
            )
            return
        }
    }
    
    // MARK:- Programmatic cell selection / deselection to reflect state
    
    private func select(indexPath: IndexPath) {
        if let indexPath = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath) {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        }
    }
    
    private func deselect(indexPath: IndexPath) {
        if let indexPath = tableView.delegate?.tableView?(tableView, willDeselectRowAt: indexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK:- UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == .portal {
            return nil
        }
        else if indexPath == .synchronize {
            if appContext.hasOfflineMap {
                return indexPath
            }
            else {
                return nil
            }
        }
        else if indexPath == .metadata {
            return nil
        }
        else {
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == .workOnline {
            workOnline()
        }
        else if indexPath == .workOffline {
            workOffline()
        }
        else if indexPath == .synchronize {
            deselect(indexPath: indexPath)
            synchronizeMap()
        }
        else if indexPath == .delete {
            deselect(indexPath: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == .portal || indexPath == .metadata {
            return nil
        }
        else {
            return indexPath
        }
    }
    
    // MARK:- UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK:- Dismiss
    
    @IBAction func userRequestsDismiss(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

class PortalUserCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var userFullNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var authButton: UIButton!
}

class WorkModeCell: UITableViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {        
        if selected {
            backgroundColor = .accent
            titleLabel.textColor = .contrasting
            subtitleLabel.textColor = .contrasting
            icon.tintColor = .contrasting
        }
        else {
            if #available(iOS 13.0, *) {
                backgroundColor = .secondarySystemGroupedBackground
                titleLabel.textColor = .label
                subtitleLabel.textColor = .secondaryLabel
                icon.tintColor = .label
            } else {
                backgroundColor = .white
                titleLabel.textColor = .black
                subtitleLabel.textColor = .darkGray
                icon.tintColor = .black
            }
        }
    }
}

class WorkOnlineCell: WorkModeCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            titleLabel.text = "Working Online"
        }
        else {
            titleLabel.text = "Work Online"
        }
    }
}

class WorkOfflineCell: WorkModeCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            titleLabel.text = "Working Offline"
        }
        else {
            titleLabel.text = "Work Offline"
        }
    }
}

class SynchronizeMapCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}

class DeleteMapCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
}

class MetaDataCell: UITableViewCell {
    @IBOutlet weak var appNameVersionLabel: UILabel!
    @IBOutlet weak var sdkVersionLabel: UILabel!
}

extension IndexPath {
    static let portal = IndexPath(row: 0, section: 0)
    static let workOnline = IndexPath(row: 0, section: 1)
    static let workOffline = IndexPath(row: 0, section: 2)
    static let synchronize = IndexPath(row: 1, section: 2)
    static let delete = IndexPath(row: 2, section: 2)
    static let metadata = IndexPath(row: 0, section: 3)
}
