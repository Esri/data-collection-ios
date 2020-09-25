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

        // MARK: Offline Map
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForOfflineMap),
            name: .offlineMapDidChange,
            object: nil
        )
        
        adjustForOfflineMap()
    }
    
    // MARK:- Work Mode
    
    @objc
    func adjustForWorkMode() {
        switch appContext.workMode {
        case .none:
            deselect(indexPath: .workOnline)
            deselect(indexPath: .workOffline)
        case .online(_):
            select(indexPath: .workOnline)
            deselect(indexPath: .workOffline)
        case .offline(_):
            select(indexPath: .workOffline)
            deselect(indexPath: .workOnline)
        }
    }
    
    private func workOnline() {
        if case .online(_) = appContext.workMode { return }
        appContext.setWorkModeOnline()
    }
    
    private func workOffline() {
        if case .offline(_) = appContext.workMode { return }
        do {
            try appContext.setWorkModeOffline()
        }
        catch {
            if error is OfflineMapManager.MissingOfflineMapError {
                userRequestsTakeMapOffline()
            }
        }
    }
    
    @objc
    func adjustForOfflineMap() {
        let hasOfflineMap = appContext.offlineMapManager.hasMap
        workOfflineCell.subtitleLabel.isHidden = hasOfflineMap
        if hasOfflineMap {
            synchronizeMapCell.brighten()
            deleteMapCell.brighten()
        }
        else {
            synchronizeMapCell.dim()
            deleteMapCell.dim()
        }
        if let date = appContext.offlineMapManager.lastSync {
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
    
    @objc
    func userRequestsTakeMapOffline() {
        delegate.profileViewControllerRequestsDownloadMapOfflineOnDemand(profileViewController: self)
    }
    
    // MARK:- Portal
    
    @objc
    func adjustForPortal() {
        switch appContext.portalSession.status {
        case .fallback(let portal, _), .loaded(let portal):
            if let user = portal.user {
                set(user: user)
            }
            else {
                setNoUser()
            }
        case .loading:
            setLoading()
        case .failed(_), .none:
            setNoUser()
        }
    }
        
    private func load(user: AGSPortalUser) {
         user.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.showError(error)
                self.setNoUser()
            }
            else {
                self.set(user: user)
            }
        }
    }
    
    private func setLoading() {
        portalUserCell.authButton.isHidden = true
        portalUserCell.authActivityIndicator.isHidden = false
        portalUserCell.authActivityIndicator.startAnimating()
    }
    
    private func setNoUser() {
        portalUserCell.thumbnailImageView.image = UIImage(named: "UserLoginIcon-Large")
        portalUserCell.userFullNameLabel.text = "Access Portal"
        portalUserCell.userEmailLabel.text = URL.basePortal.host
        portalUserCell.authButton.setTitle("Sign In", for: .normal)
        portalUserCell.authButton.removeTarget(self, action: #selector(userRequestsSignOut), for: .touchUpInside)
        portalUserCell.authButton.addTarget(self, action: #selector(userRequestsSignIn), for: .touchUpInside)
        portalUserCell.authButton.isHidden = false
        portalUserCell.authActivityIndicator.isHidden = true
        portalUserCell.authActivityIndicator.stopAnimating()
    }
    
    private func set(user: AGSPortalUser) {
        portalUserCell.thumbnailImageView.image = UIImage(named: "UserLoginIcon-Large")
        portalUserCell.userEmailLabel.text = user.email
        portalUserCell.userFullNameLabel.text = user.fullName
        portalUserCell.authButton.setTitle("Sign Out", for: .normal)
        portalUserCell.authButton.removeTarget(self, action: #selector(userRequestsSignIn), for: .touchUpInside)
        portalUserCell.authButton.addTarget(self, action: #selector(userRequestsSignOut), for: .touchUpInside)
        portalUserCell.authButton.isHidden = false
        portalUserCell.authActivityIndicator.isHidden = true
        portalUserCell.authActivityIndicator.stopAnimating()
        
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
        precondition(appContext.offlineMapManager.hasMap, "There is no map to synchronize.")
        delegate?.profileViewControllerRequestsSynchronizeMap(profileViewController: self)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK:- Delete Offline Map
    
    private func promptDeleteOfflineMap() {
        
        precondition(appContext.offlineMapManager.hasMap, "There is no map to delete.")
        
        var message = "Are you sure you want to delete your offline map?"

        if appContext.offlineMapManager.mapHasLocalEdits {
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
        appContext.deleteOfflineMapAndAttemptToGoOnline()
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
            if case .offline = appContext.workMode {
                return indexPath
            }
            else {
                return nil
            }
        }
        else if indexPath == .workOffline {
            if case .online = appContext.workMode {
                return indexPath
            }
            else {
                return nil
            }
        }
        else if indexPath == .synchronize {
            if appContext.offlineMapManager.hasMap {
                return indexPath
            }
            else {
                return nil
            }
        }
        else if indexPath == .delete {
            if appContext.offlineMapManager.hasMap {
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
    @IBOutlet weak var authActivityIndicator: UIActivityIndicatorView!
}

protocol Dimmable {
    var dimmableLabel: UILabel { get }
}

extension Dimmable {
    
    func dim() {
        dimmableLabel.textColor = .secondaryLabel
    }
    
    func brighten() {
        dimmableLabel.textColor = .label
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
            backgroundColor = .secondarySystemGroupedBackground
            titleLabel.textColor = .label
            subtitleLabel.textColor = .secondaryLabel
            icon.tintColor = .primary
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
