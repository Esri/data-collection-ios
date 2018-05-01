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
import ArcGIS


class RelatedRecordsPopupsViewController: UIViewController {
    
    struct ReuseIdentifiers {
        static let popupTextField = "PopupTextFieldReuseID"
        static let relatedRecordCell = "RelatedRecordCellReuseID"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var popup: AGSPopup! {
        didSet {
            popupManager = AGSPopupManager(popup: popup)
        }
    }
    
    var popupManager: AGSPopupManager!
    
    weak var previousPopup: AGSPopup?
    
    var manyToOneRecords = [RelatedRecordsManager]()
    var oneToManyRecords = [RelatedRecordsManager]()
    
    var loadingRelatedRecords = false
    
    func loadRelatedRecordsIntoTableView() {
        
        // TODO make swifty ?
        
        var rows = [IndexPath]()
        for i in 0..<manyToOneRecords.count {
            rows.append( IndexPath(row: i+popupManager.displayFields.count, section: 0) )
        }
        
        for i in 0..<oneToManyRecords.count {
            let manager = oneToManyRecords[i]
            for j in 0..<manager.popups.count {
                rows.append( IndexPath(row: j, section: i+1) )
            }
        }
        
        let sections = IndexSet(integersIn: 1...oneToManyRecords.count)
        
        tableView.beginUpdates()
        tableView.insertSections(sections, with: UITableViewRowAnimation.top)
        tableView.insertRows(at: rows, with: UITableViewRowAnimation.top)
        tableView.endUpdates()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(PopupTextFieldCell.self, forCellReuseIdentifier: ReuseIdentifiers.popupTextField)
        tableView.register(RelatedRecordCell.self, forCellReuseIdentifier: ReuseIdentifiers.relatedRecordCell)
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Is root popup view controller?
        if previousPopup == nil {
            guard let image = UIImage(named: "Cancel") else {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .done, target: self, action: #selector(RelatedRecordsPopupsViewController.exitRR(_:)))
                return
            }
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(RelatedRecordsPopupsViewController.exitRR(_:)))
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        tableView.isEditing = true
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set Title
        title = popupManager.title
        
        // Kick off load of related records
        var preloadedRelatedRecords = [RelatedRecordsManager]()
        if let feature = popup.geoElement as? AGSArcGISFeature, let relatedRecordsInfos = feature.relatedRecordsInfos, let map = appContext.currentMap {
            for info in relatedRecordsInfos {
                // TODO work this rule into AppRules
                if map.isPopupEnabledFor(relationshipInfo: info), let relatedRecord = RelatedRecordsManager(relationshipInfo: info, feature: feature) {
                    preloadedRelatedRecords.append(relatedRecord)
                }
            }
        }
        
        // Is root popup?
        if previousPopup == nil {
            
            loadingRelatedRecords = true
            
            AGSLoadObjects(preloadedRelatedRecords) { [weak self] (loaded) in
                self?.oneToManyRecords = preloadedRelatedRecords.oneToManyLoaded
                self?.manyToOneRecords = preloadedRelatedRecords.manyToOneLoaded
                self?.loadingRelatedRecords = false
                self?.loadRelatedRecordsIntoTableView()
            }
        }
        
        // Finally, load table
        tableView.reloadData()
    }
    
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            guard indexPath.row >= popupManager.displayFields.count else {
                return true
            }
        }
        return false
    }
    
    @objc func exitRR(_ sender: AnyObject?) {
        dismiss(animated: true, completion: nil)
    }
}

extension RelatedRecordsPopupsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let fieldCell = cell as? PopupFieldCell {
            fieldCell.updateForPopupField()
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {

        return !indexPathWithinAttributes(indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard !indexPathWithinAttributes(indexPath) else {
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? RelatedRecordCell {
            if let rrvc = storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController {
                rrvc.popup = cell.popup
                rrvc.previousPopup = self.popup
                self.navigationController?.pushViewController(rrvc, animated: true )
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        guard section == 0, loadingRelatedRecords else {
            return 0.0
        }
        
        return 35.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard section == 0, loadingRelatedRecords else {
            return nil
        }

        let containerHeight: CGFloat = 35.0
        let container = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width, height: containerHeight))
        container.backgroundColor = .clear
        
        let activity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activity.startAnimating()
        
        container.addSubview(activity)
        activity.center = container.convert(container.center, from:container.superview)
        return container
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//
//        guard indexPath.section > 0 else {
//            return nil
//        }
//
//        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit") { [weak self] (action, indexPath) in
//            print("Will Edit Inspection")
//        }
//        editAction.backgroundColor = .orange
//
//        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { [weak self] (action, indexPath) in
//            print("Will Delete Inspection")
//        }
//        deleteAction.backgroundColor = .red
//
//        return [deleteAction, editAction]
//    }
}

extension RelatedRecordsPopupsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {       
        return oneToManyRecords.count + 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 {
            return nil
        }
        else {
            return oneToManyRecords[section-1].name
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Section 0
        if indexPathWithinAttributes(indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.popupTextField, for: indexPath) as! PopupTextFieldCell
            cell.popupManager = popupManager
            cell.field = popupManager.displayFields[indexPath.row]
            return cell
        }
        else if indexPath.section == 0 {
            // M:1 Related Records
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let recordIndex = indexPath.row - popupManager.displayFields.count
            let record = manyToOneRecords[recordIndex]
            let popup = record.popups.first
            cell.popup = popup
            cell.maxAttributes = 2
            return cell
        }
        // Section 1..n
        else {
            // 1:M Related Records
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.relatedRecordCell, for: indexPath) as! RelatedRecordCell
            let record = oneToManyRecords[indexPath.section-1]
            let popup = record.popups[indexPath.row]
            cell.popup = popup
            cell.maxAttributes = 3
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.section > 0 {
            guard let relatedRecordCell = cell as? RelatedRecordCell else {
                return
            }
            // TODO CLEAN CELL?
            relatedRecordCell.popup = nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return popupManager.displayFields.count + manyToOneRecords.count
        }
        else {
            let relationship = oneToManyRecords[section-1]
            return relationship.popups.count
        }
    }
}

class RelatedRecordCell: UITableViewCell {
    
    weak var relationshipInfo: AGSRelationshipInfo?
    
    public var popup: AGSPopup? {
        didSet {
            guard let feature = popup?.geoElement as? AGSArcGISFeature else {
                update()
                return
            }
            feature.load { [weak self] (error) in
                self?.update()
            }
        }
    }
    
    public var maxAttributes: Int = 3 {
        didSet {
            update()
        }
    }
    
    private var attributes = [(UILabel, UILabel)]()
    
    private var stackView = UIStackView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .disclosureIndicator

        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 6.0
        contentView.addSubview(stackView)
        contentView.constrainToBounds(stackView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        update()
    }
    
    private func update() {
        
        guard let manager = popup?.asManager else {
            for attribute in attributes {
                stackView.removeArrangedSubview(attribute.0)
                attribute.0.removeFromSuperview()
                stackView.removeArrangedSubview(attribute.1)
                attribute.1.removeFromSuperview()
            }
            attributes.removeAll()
            return
        }
        
        let nAttributes = min(maxAttributes, manager.displayFields.count)
        
        if attributes.count < nAttributes {
            
            while attributes.count != nAttributes {
                
                let titleLabel = UILabel()
                titleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
                titleLabel.textColor = .gray
                titleLabel.sizeToFit()
                NSLayoutConstraint.activate([ titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.lineHeight) ])
                stackView.addArrangedSubview(titleLabel)
                
                let valueLabel = UILabel()
                valueLabel.numberOfLines = 0
                valueLabel.font = UIFont.preferredFont(forTextStyle: .body)
                valueLabel.sizeToFit()
                NSLayoutConstraint.activate([ valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: valueLabel.font.lineHeight) ])

                stackView.addArrangedSubview(valueLabel)
                
                attributes.append((titleLabel, valueLabel))
            }
        }
        else if attributes.count > nAttributes {
            
            while attributes.count != nAttributes {
                
                guard attributes.last != nil else {
                    break
                }
                
                let last = attributes.removeLast()
                
                // TODO consider how removing Auto Layout constraints
                
                stackView.removeArrangedSubview(last.0)
                last.0.removeFromSuperview()
                stackView.removeArrangedSubview(last.1)
                last.1.removeFromSuperview()
            }
        }
        
        var popupIndex = 0
        
        for attribute in attributes {
            
            let titleLabel = attribute.0
            titleLabel.text = manager.labelTitle(idx: popupIndex)
            let valueLabel = attribute.1
            valueLabel.text = manager.nextFieldStringValue(idx: &popupIndex)
            
            // TODO workout constraints issue
            titleLabel.considerEmptyStringForStackView()
            valueLabel.considerEmptyStringForStackView()
        }
    }
}

