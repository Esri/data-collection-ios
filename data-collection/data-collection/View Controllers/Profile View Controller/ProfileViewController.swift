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
    func profileViewControllerRequestsSynchronizeMap(profileViewController: ProfileViewController)
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
        
        // MARK: Work Mode
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForWorkMode),
            name: .workModeDidChange,
            object: nil
        )
        
        adjustForWorkMode()
        
        // MARK: Portal
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForPortal),
            name: .portalDidChange,
            object: nil
        )
        
        adjustForPortal()
        
        // MARK: Reachability
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForReachability),
            name: .reachabilityDidChange,
            object: nil
        )
        
        adjustForReachability()
        
        // MARK: Last Sync Date
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForLastSyncDate),
            name: .lastSyncDidChange,
            object: nil
        )
        
        adjustForLastSyncDate()
        
        // MARK: Offline Map
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForHasOfflineMap),
            name: .hasOfflineMapDidChange,
            object: nil
        )
        
        adjustForHasOfflineMap()
    }
    
    // MARK:- Reachability
    
    @objc
    func adjustForReachability() {
        let reachable = appReachability.isReachable
        if reachable {
            workOnlineCell.subtitleLabel.isHidden = true
            workOnlineCell.brighten()
        }
        else {
            workOnlineCell.subtitleLabel.text = "no network connectivity"
            workOnlineCell.subtitleLabel.isHidden = false
            workOnlineCell.dim()
        }
    }
    
    // MARK:- Work Mode
    
    @objc
    func adjustForWorkMode() {
        switch appContext.workMode {
        case .online:
            select(indexPath: .workOnline)
            deselect(indexPath: .workOffline)
        case .offline:
            select(indexPath: .workOffline)
            deselect(indexPath: .workOnline)
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
    
    @objc
    func adjustForHasOfflineMap() {
        let hasOfflineMap = appContext.hasOfflineMap
        workOfflineCell.subtitleLabel.isHidden = hasOfflineMap
        if hasOfflineMap {
            synchronizeMapCell.brighten()
            deleteMapCell.brighten()
        }
        else {
            synchronizeMapCell.dim()
            deleteMapCell.dim()
        }
    }
    
    // MARK:- Portal
    
    @objc
    func adjustForPortal() {
        if let user = appContext.portal.user {
            load(user: user)
        }
        else {
            setNoUser()
        }
    }
        
    private func load(user: AGSPortalUser) {
         user.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.present(simpleAlertMessage: error.localizedDescription)
                self.setNoUser()
            }
            else {
                self.set(user: user)
            }
        }
    }
    
    private func setNoUser() {
        portalUserCell.thumbnailImageView.image = UIImage(named: "UserLoginIcon-Large")
        portalUserCell.userFullNameLabel.text = "Access Portal"
        portalUserCell.userEmailLabel.text = .basePortalDomain
        portalUserCell.authButton.setTitle("Sign In", for: .normal)
        portalUserCell.authButton.addTarget(self, action: #selector(userRequestsSignIn), for: .touchUpInside)
    }
    
    private func set(user: AGSPortalUser) {
        portalUserCell.thumbnailImageView.image = UIImage(named: "UserLoginIcon-Large")
        portalUserCell.userEmailLabel.text = user.email
        portalUserCell.userFullNameLabel.text = user.fullName
        portalUserCell.authButton.setTitle("Sign Out", for: .normal)
        portalUserCell.authButton.addTarget(self, action: #selector(userRequestsSignOut), for: .touchUpInside)
        
        if let thumbnail = user.thumbnail {
            thumbnail.load { [weak self] (error) in
                if let error = error {
                    print(error)
                }
                else {
                    self?.portalUserCell.thumbnailImageView.image = thumbnail.image
                }
            }
        }
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
        
        precondition(appContext.hasOfflineMap, "There is no map to synchronize.")
        
        delegate?.profileViewControllerRequestsSynchronizeMap(profileViewController: self)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    @objc
    func adjustForLastSyncDate() {
        if let date = appContext.mobileMapPackage?.lastSyncDate {
            synchronizeMapCell.subtitleLabel.isHidden = false
            synchronizeMapCell.subtitleLabel.text = String(
                format: "last sync %@",
                Self.dateFormatter.string(from: date)
            )
        }
        else {
            synchronizeMapCell.subtitleLabel.isHidden = true
        }
    }
    
    // MARK:- Delete Offline Map
    
    private func promptDeleteOfflineMap() {
        
        precondition(appContext.hasOfflineMap, "There is no map to delete.")
        
        var message = "Are you sure you want to delete your offline map?"

        if let mobileMapPackage = appContext.mobileMapPackage, mobileMapPackage.hasLocalEdits {
            message += "\n\nThe offline map contains un-synchronized changes."
        }
        
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        
        let delete = UIAlertAction(
            title: "Delete",
            style: .destructive
        ) { [weak self] (_) in
            self?.deleteOfflineMap()
        }
        
        alert.addAction(delete)
        alert.addAction(.cancel())
        
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteOfflineMap() {
        do {
            try appContext.deleteOfflineMapAndAttemptToGoOnline()
        }
        catch {
            let alert = UIAlertController(
                title: nil,
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(.okay())
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK:- Programmatic cell selection / deselection to reflect state
    
    private func select(indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
    }
    
    private func deselect(indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK:- UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == .portal {
            return nil
        }
        else if indexPath == .workOnline {
            guard appContext.workMode == .offline else {
                return nil
            }
            if appReachability.isReachable {
                return indexPath
            }
            else {
                return nil
            }
        }
        else if indexPath == .workOffline {
            guard appContext.workMode == .online else {
                return nil
            }
            return indexPath
        }
        else if indexPath == .synchronize {
            if appContext.hasOfflineMap {
                return indexPath
            }
            else {
                return nil
            }
        }
        else if indexPath == .delete {
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
            return nil
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
            promptDeleteOfflineMap()
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

protocol Dimmable {
    var dimmableLabel: UILabel { get }
}

extension Dimmable {
    
    func dim() {
        if #available(iOS 13.0, *) {
            dimmableLabel.textColor = .secondaryLabel
        }
        else {
            dimmableLabel.textColor = .gray
        }
    }
    
    func brighten() {
        if #available(iOS 13.0, *) {
            dimmableLabel.textColor = .label
        }
        else {
            dimmableLabel.textColor = .black
        }
    }
}

class WorkModeCell: UITableViewCell, Dimmable {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var dimmableLabel: UILabel { titleLabel }
    
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
                icon.tintColor = .primary
            } else {
                backgroundColor = .white
                titleLabel.textColor = .black
                subtitleLabel.textColor = .darkGray
                icon.tintColor = .primary
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

class SynchronizeMapCell: UITableViewCell, Dimmable {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    var dimmableLabel: UILabel { titleLabel }
}

class DeleteMapCell: UITableViewCell, Dimmable {
    @IBOutlet weak var titleLabel: UILabel!
    var dimmableLabel: UILabel { titleLabel }
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
