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

/// A concrete subclass of `AGSPopupManager` that augments the pop-up manager with the ability to manage
/// the popup as well as it's related records.
///
class RichPopupManager: AGSPopupManager {
    
    // MARK: Initialization
    
    var richPopup: RichPopup {
        return popup as! RichPopup
    }
    
    // Init requires a RichPopup
    init(richPopup: RichPopup) {
        super.init(popup: richPopup)
    }
    
    // Closes access to the init() initializer.
    private override init() {
        super.init()
    }
    
    // MARK: Popup Manager Editing Session
    
    /// Cancel editing the pop-up's attributes as well as its many-to-one records.
    ///
    /// - Note: Many-to-one records are included in edits to the pop-up because the pop-up is the child
    /// in the relationship.
    ///
    override func cancelEditing() {
        
        if let relationships = richPopup.relationships, relationships.loadStatus == .loaded {
            
            // First, all staged many to one record changes are canceled.
            relationships.manyToOne.forEach { (manager) in
                manager.cancelChange()
            }
        }
        
        super.cancelEditing()
    }
    
    /// Finish editing the pop-up's attributes as well as it's many-to-one records.
    ///
    /// - Note: Many-to-one records are included in edits to the pop-up because the pop-up is the child
    /// in the relationship.
    ///
    override func finishEditing(completion: @escaping (Error?) -> Void) {
        
        var relatedRecordsErrors = [Error]()
        
        // First, all staged many to one record changes are commited and features are related.
        if richPopup.relationships?.loadStatus == .loaded, let managers = richPopup.relationships?.manyToOne {
            
            for manager in managers {
                
                guard let info = manager.relationshipInfo else {
                    
                    manager.cancelChange()
                    continue
                }
                
                if let feature = manager.popup?.geoElement as? AGSArcGISFeature, let relatedFeature = manager.relatedPopup?.geoElement as? AGSArcGISFeature {
                    
                    manager.commitChange()
                    feature.relate(to: relatedFeature, relationshipInfo: info)
                }
                else {
                    
                    if info.isComposite {
                        relatedRecordsErrors.append(RichPopupManagerError.missingManyToOneRelationship(manager.name ?? "Unknown"))
                    }
                    
                    manager.cancelChange()
                }
            }
        }
        
        // Then, the manager finishes editing it's attributes.
        super.finishEditing { (error) in
            
            if let error = error {
                relatedRecordsErrors.append(error)
            }
            
            if !relatedRecordsErrors.isEmpty {
                completion(RichPopupManagerError.invalidPopup(relatedRecordsErrors))
            }
            else {
                completion(nil)
            }
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
        
        // Check M:1 relationships.
        if let managers = richPopup.relationships?.manyToOne {
            
            invalids += managers
                .filter { record in
                    let isComposite = record.relationshipInfo?.isComposite ?? false
                    return isComposite && record.relatedPopup == nil
                }
                .map { RichPopupManagerError.missingManyToOneRelationship($0.name ?? "Unknown") as Error }
        }
        
        // Check validity on all popup editable display fields.
        invalids += editableDisplayFields.compactMap { return validationError(for: $0) }
        
        return invalids
    }
    
    func update(_ popup: AGSPopup) throws {
        
        guard let info = self.popup.relationship(to: popup) else {
            throw NSError.unknown
        }
        
        if info.isManyToOne {
            try update(manyToOne: popup, forRelationship: info)
        }
        else if info.isOneToMany {
            try update(oneToMany: popup, forRelationship: info)
        }
        else {
            throw NSError.invalidOperation
        }
    }
    
    func remove(_ popup: AGSPopup) throws {
        
        guard let info = self.popup.relationship(to: popup) else {
            throw NSError.unknown
        }
        
        if info.isOneToMany {
            try delete(oneToMany: popup, forRelationship: info)
        }
        else {
            throw NSError.invalidOperation
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
    private func update(manyToOne popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
        guard let relationships = richPopup.relationships, relationships.loadStatus == .loaded else {
            throw richPopup.relationships?.loadError ?? NSError.unknown
        }
        
        guard isEditing else {
            throw NSError.invalidOperation
        }
        
        guard !info.isComposite else {
            throw RichPopupManagerError.cannotRelateFeatures
        }
        
        let foundManager = relationships.manyToOne.first { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
        }
        
        guard let manager = foundManager else {
            throw RichPopupManagerError.cannotRelateFeatures
        }
        
        // Stage the related popup. Relating the pop-up will come if the user saves the session.
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
    private func update(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
        guard richPopup.relationships?.loadStatus == .loaded else {
            throw richPopup.relationships?.loadError ?? NSError.unknown
        }
        
        guard !isEditing else {
            throw NSError.invalidOperation
        }
        
        let foundManager = richPopup.relationships?.oneToMany.first { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
        }
        
        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let relationship = foundManager,
            let relatedFeature = relationship.popup?.geoElement as? AGSArcGISFeature,
            let info = relationship.relationshipInfo
            else {
                throw RichPopupManagerError.cannotRelateFeatures
        }
        
        // Relate the two records.
        feature.relate(to: relatedFeature, relationshipInfo: info)

        // Add the popup to the model, if it not already there, and sort.
        relationship.editRelatedPopup(popup)
    }

    /// Unrelate a one-to-many record for a particular relationship info.
    ///
    /// - Parameters:
    ///   - popup: The new record to unrelate.
    ///   - info: The relationship info defining which related record to remove.
    ///
    /// - Throws: An error if there is a problem unrelating the new record.
    ///
    private func delete(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {

        guard richPopup.relationships?.loadStatus == .loaded else {
            throw richPopup.relationships?.loadError ?? NSError.unknown
        }
        
        guard !isEditing else {
            throw NSError.invalidOperation
        }
        
        let foundRelationship = richPopup.relationships?.oneToMany.first { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
        }

        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let relationship = foundRelationship,
            let relatedFeature = relationship.popup?.geoElement as? AGSArcGISFeature else {
            throw RichPopupManagerError.cannotRelateFeatures
        }
        
        // Unrelate the two records.
        feature.unrelate(to: relatedFeature)

        // Delete the popup from the model.
        relationship.deleteRelatedPopup(popup)
    }
}

extension RichPopupManager {
    
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
    func relationship(forIndexPath indexPath: IndexPath) -> Relationship? {
        
        guard richPopup.relationships?.loadStatus == .loaded else {
            return nil
        }
        
        if indexPathWithinManyToOne(indexPath) {
            
            let rowOffset = isEditing ? editableDisplayFields.count : displayFields.count
            let rowIndex = indexPath.row - rowOffset
            return richPopup.relationships?.manyToOne[rowIndex]
        }
        else if indexPathWithinOneToMany(indexPath) {
            
            let sectionOffset = 1
            let sectionIndex = indexPath.section - sectionOffset
            return richPopup.relationships?.oneToMany[sectionIndex]
        }
        
        return nil
    }
}

extension RichPopupManager {
    
    
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
        
        guard indexPath.section == 0, richPopup.relationships?.loadStatus == .loaded, let managers = richPopup.relationships?.manyToOne else {
            return false
        }

        let rowOffset = isEditing ? editableDisplayFields.count : displayFields.count
        let offsetIndex = indexPath.row - rowOffset

        return managers.count > offsetIndex
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
        
        guard indexPath.section > 0, richPopup.relationships?.loadStatus == .loaded, let managers = richPopup.relationships?.oneToMany else {
            return false
        }

        let sectionOffset = 1
        let sectionIndex = indexPath.section - sectionOffset

        guard managers.count > sectionIndex else {
            return false
        }

        let manager = managers[sectionIndex]

        var rowOffset = 0
        if let table = manager.relatedTable, table.canAddFeature {
            rowOffset += 1
        }

        return manager.relatedPopups.count > indexPath.row - rowOffset
    }
    
    func indexPathWithinRelatedRecords(_ indexPath: IndexPath) -> Bool {
        
        guard richPopup.relationships?.loadStatus == .loaded else {
            return false
        }
        
        return indexPathWithinManyToOne(indexPath) || indexPathWithinOneToMany(indexPath)
    }
}
