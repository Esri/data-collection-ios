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

enum RelatedRecordsManagerError: AppError {
    
    var baseCode: AppErrorBaseCode { return .RelatedRecordsManagerError }
    
    case featureMissingTable
    case missingManyToOneRelationship(String)
    case invalidPopup
    case cannotRelateFeatures
    
    var errorCode: Int {
        let base = baseCode.rawValue
        switch self {
        case .featureMissingTable:
            return base + 1
        case .missingManyToOneRelationship(_):
            return base + 2
        case .invalidPopup:
            return base + 3
        case .cannotRelateFeatures:
            return base + 4
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .featureMissingTable:
            return [NSLocalizedDescriptionKey: "Feature does not belong to a feature table"]
        case .missingManyToOneRelationship(let str):
            return [NSLocalizedDescriptionKey: "Missing value for many to one relationship \(str)"]
        case .invalidPopup:
            return [NSLocalizedDescriptionKey: "Popup with related records in invalid."]
        case .cannotRelateFeatures:
            return [NSLocalizedDescriptionKey: "Features or Relationship Info missing."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

/// A concrete subclass of `AGSPopupManager` that augments the pop-up manager with the ability to manage
/// the popup as well as it's related records.
///
class PopupRelatedRecordsManager: AGSPopupManager {
    
    private(set) var manyToOne = [ManyToOneManager]()
    private(set) var oneToMany = [OneToManyManager]()
    
    // MARK: Popup Manager Editing Session
    
    /// Cancel editing the pop-up's attributes as well as its many-to-one records.
    ///
    /// - Note: Many-to-one records are included in edits to the pop-up because the pop-up is the child
    /// in the relationship.
    ///
    override func cancelEditing() {
        
        // First, all staged many to one record changes are canceled.
        manyToOne.forEach { (manager) in
            manager.cancelChange()
        }
        
        // Then, the manager cancels editing it's attributes.
        super.cancelEditing()
    }
    
    /// Finish editing the pop-up's attributes as well as it's many-to-one records.
    ///
    /// - Note: Many-to-one records are included in edits to the pop-up because the pop-up is the child
    /// in the relationship.
    ///
    override func finishEditing(completion: @escaping (Error?) -> Void) {
        
        // First, all staged many to one record changes are commited.
        var relatedRecordsError: Error?
        
        for manager in manyToOne {
            do {
                try manager.commitChange()
            }
            catch {
                relatedRecordsError = error
            }
        }
        
        // Then, the manager finishes editing it's attributes.
        super.finishEditing { (error) in
            
            guard error == nil, relatedRecordsError == nil else {
                completion(RelatedRecordsManagerError.invalidPopup)
                return
            }
            
            completion(error)
        }
    }
    
    // MARK: Custom Validation
    
    /// Determine if the pop-up and related record editing session have validation errors.
    ///
    /// First, the validation checks if all composite many-to-one relationships have a record.
    /// Then, the manager checks if each editable display field validates.
    ///
    /// - Returns: An array of validation errors.
    ///
    func validatePopup() -> [Error] {
        
        guard isEditing else {
            return [Error]()
        }
        
        var invalids = [Error]()
        
        // Check M:1 relationships, if composite.
        invalids += manyToOne
            .filter { record in
                guard let info = record.relationshipInfo else { return false }
                
                if info.isComposite { return record.relatedPopup == nil }
                else { return false }
            }
            .map { return RelatedRecordsManagerError.missingManyToOneRelationship($0.name ?? "Unknown") as Error }
        
        // Check validity on all popup editable display fields.
        invalids += editableDisplayFields.compactMap { return validationError(for: $0) }
        
        return invalids
    }
    
    /// Load the pop-up's related records.
    ///
    /// - Parameter completion: The closure performed when all related records have loaded.
    ///
    func loadRelatedRecords(_ completion: @escaping ()->Void) {
        
        manyToOne.removeAll()
        oneToMany.removeAll()
        
        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let relatedRecordsInfos = feature.oneToManyRelationshipInfos,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable
            else {
                completion()
                return
        }

        let dispatchGroup = DispatchGroup()

        // Iterate through the feature's related record infos.
        for info in relatedRecordsInfos {
            
            // Ensure popup's are enabled for the relationship info.
            guard featureTable.isPopupEnabledFor(relationshipInfo: info) else {
                continue
            }
            
            // Find the table on the other end of the relationship.
            let foundRelatedTable = featureTable.relatedTables()?.first { $0.serviceLayerID == info.relatedTableID }
            
            // Build a many-to-one related record manager.
            if info.isManyToOne, let manager = ManyToOneManager(relationshipInfo: info, table: foundRelatedTable, popup: popup) {
                
                dispatchGroup.enter()
                
                manager.load { [weak self] (error) in
                    
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    guard error == nil else {
                        print("[Error: Many To One Manager]", error!.localizedDescription)
                        return
                    }
                    
                    self?.manyToOne.append(manager)
                }
            }
            // Or, build a one-to-many related record manager.
            else if info.isOneToMany, let manager = OneToManyManager(relationshipInfo: info, table: foundRelatedTable, popup: popup) {
                
                dispatchGroup.enter()
                
                manager.load { [weak self] (error) in
                    
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    guard error == nil else {
                        print("[Error: Many To One Manager]", error!.localizedDescription)
                        return
                    }
                    
                    self?.oneToMany.append(manager)
                }
            }
        }
        
        // Finally, call the completion closure.
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
    // MARK: Many To One

    /// Stage and relate a new many-to-one record for a particular relationship info.
    ///
    /// - Parameters:
    ///   - popup: The new record to relate.
    ///   - info: The relationship info defining which related record to update.
    ///
    /// - Throws: An error if there is a problem staging or relating the new record.
    ///
    func update(manyToOne popup: AGSPopup?, forRelationship info: AGSRelationshipInfo) throws {
        
        guard isEditing else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        let foundManager = manyToOne.first { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
        }
        
        guard let manager = foundManager else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        manager.relatedPopup = popup
    }
    
    // MARK: One To Many
    
    /// Stage and relate a new one-to-many record for a particular relationship info.
    ///
    /// - Parameters:
    ///   - popup: The new record to relate.
    ///   - info: The relationship info defining which related record to update.
    ///
    /// - Throws: An error if there is a problem staging or relating the new record.
    ///
    func edit(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
        guard !isEditing else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        let foundManager = oneToMany.first { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
        }

        guard let manager = foundManager else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }

        do {
            try manager.editRelatedPopup(popup)
        }
        catch {
            throw error
        }
    }

    /// Unrelate a one-to-many record for a particular relationship info.
    ///
    /// - Parameters:
    ///   - popup: The new record to unrelate.
    ///   - info: The relationship info defining which related record to remove.
    ///
    /// - Throws: An error if there is a problem unrelating the new record.
    ///
    func delete(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {

        guard !isEditing else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        let foundManager = oneToMany.first { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
        }

        guard let manager = foundManager else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }

        do {
            try manager.deleteRelatedPopup(popup)
        }
        catch {
            throw error
        }
    }
}

extension PopupRelatedRecordsManager {
    
    /// Provide a pop-up field for an `UITableView` index path.
    ///
    /// This function is designed to be used with a `UITableViewDataSource`.
    ///
    /// - Parameter indexPath: The index path of the pop-up field.
    ///
    func attributeField(forIndexPath indexPath: IndexPath) -> AGSPopupField? {
        
        guard indexPathWithinAttributes(indexPath) else {
            return nil
        }
        
        let attributeFields = isEditing ? editableDisplayFields : displayFields
        return attributeFields[indexPath.row]
    }
    
    /// Provide a pop-up related records manager for an index path.
    ///
    /// This function is designed to be used with a `UITableViewDataSource`.
    /// This function will check if the index path references a related records manager within the many-to-one section
    /// or within the one-to-many section.
    ///
    /// - Parameter indexPath: The index path of the pop-up field.
    ///
    func relatedRecordManager(forIndexPath indexPath: IndexPath) -> RelatedRecordsManager? {
        
        if indexPathWithinManyToOne(indexPath) {
            
            let rowOffset = isEditing ? editableDisplayFields.count : displayFields.count
            let rowIndex = indexPath.row - rowOffset
            return manyToOne[rowIndex]
        }
        else if indexPathWithinOneToMany(indexPath) {
            
            let sectionOffset = 1
            let sectionIndex = indexPath.section - sectionOffset
            return oneToMany[sectionIndex]
        }
        
        return nil
    }
}

extension PopupRelatedRecordsManager {
    
    
    /// Does the index path lie within the attributes section?
    ///
    /// This function is designed to be used with a `UITableViewDataSource`.
    ///
    /// - Parameter indexPath: The index path in question.
    ///
    /// - Returns: If the index path lies within the attributes section.
    ///
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        
        guard indexPath.section == 0 else {
            return false
        }
        
        let nFields = isEditing ? editableDisplayFields.count : displayFields.count
        
        return indexPath.row < nFields
    }
    
    /// Does the index path lie within the many-to-one section?
    ///
    /// This function is designed to be used with a `UITableViewDataSource`.
    ///
    /// - Parameter indexPath: The index path in question.
    ///
    /// - Returns: If the index path lies within the many-to-one section.
    ///
    func indexPathWithinManyToOne(_ indexPath: IndexPath) -> Bool {

        guard indexPath.section == 0 else {
            return false
        }

        let rowOffset = isEditing ? editableDisplayFields.count : displayFields.count
        let offsetIndex = indexPath.row - rowOffset

        return manyToOne.count > offsetIndex
    }

    /// Does the index path lies within the one-to-many section?
    ///
    /// This function is designed to be used with a `UITableViewDataSource`.
    ///
    /// - Parameter indexPath: The index path in question.
    ///
    /// - Returns: If the index path lies within the one-to-many section.
    ///
    func indexPathWithinOneToMany(_ indexPath: IndexPath) -> Bool {

        guard indexPath.section > 0 else {
            return false
        }

        let sectionOffset = 1
        let sectionIndex = indexPath.section - sectionOffset

        guard oneToMany.count > sectionIndex else {
            return false
        }

        let manager = oneToMany[sectionIndex]

        var rowOffset = 0
        if let table = manager.relatedTable, table.canAddFeature {
            rowOffset += 1
        }

        return manager.relatedPopups.count > indexPath.row - rowOffset
    }
    
    func indexPathWithinRelatedRecords(_ indexPath: IndexPath) -> Bool {
        
        return indexPathWithinManyToOne(indexPath) || indexPathWithinOneToMany(indexPath)
    }
}
