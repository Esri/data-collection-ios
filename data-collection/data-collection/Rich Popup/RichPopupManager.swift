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
    
    private(set) var richPopupAttachmentManager: RichPopupAttachmentsManager?
    
    // Init requires a RichPopup
    init(richPopup: RichPopup) {
        super.init(popup: richPopup)
        self.richPopupAttachmentManager = RichPopupAttachmentsManager(richPopupManager: self)
    }
    
    // Closes access to the init() initializer.
    private override init() {
        super.init()
    }
    
    // MARK:- Popup Manager Editing Session
    
    /// Cancel editing the pop-up's attributes as well as its many-to-one records.
    ///
    /// - Note: Many-to-one records are included in edits to the pop-up because the pop-up is the child
    /// in the relationship.
    ///
    override func cancelEditing() {
        
        if let relationships = richPopup.relationships, relationships.loadStatus == .loaded {
            
            // First, all staged many to one record changes are canceled.
            // Only many to one related records can be edited during an editing session.
            let manyToOne = relationships.manyToOne
            
            manyToOne.forEach { (manager) in
                manager.cancelChange()
            }
        }
        
        // Call cooresponding super class method.
        super.cancelEditing()
        
        // Then, discard any staged attachments (resetting the attachments to the condition before the editing session started).
        richPopupAttachmentManager?.discardStagedAttachments()
    }
    
    /// Finish editing the pop-up's attributes as well as it's many-to-one records.
    ///
    /// - Note: Many-to-one records are included in edits to the pop-up because the pop-up is the child
    /// in the relationship.
    ///
    override func finishEditing(completion: @escaping (Error?) -> Void) {
        // First, all staged many to one record changes are commited and features are related.
        var manyOneError: ManyToOneRelationshipsEditingError?
        do {
            try finishEditingManyToOneRelationships()
        }
        catch {
            manyOneError = error as? ManyToOneRelationshipsEditingError
        }
        // Then, update any parent one-to-many records.
        var oneManyError: OneToManyRelationshipsEditingError?
        do {
            try finishEditingOneToManyRelationships()
        }
        catch {
            oneManyError = error as? OneToManyRelationshipsEditingError
        }
        // Finally, finish by calling this method.
        func finishEditingSession() {
            super.finishEditing { (error) in
                if manyOneError != nil || oneManyError != nil || error != nil {
                    completion(
                        EditingError(
                            attributes: error,
                            manyToOne: manyOneError,
                            oneToMany: oneManyError
                        )
                    )
                }
                else {
                    completion(nil)
                }
            }
        }
        // Then, commit all staged (add/delete) attachments.
        if let attachmentsManager = richPopupAttachmentManager {
            attachmentsManager.commitStagedAttachments {
                finishEditingSession()
            }
        }
        else {
            finishEditingSession()
        }
    }
    
    private func finishEditingManyToOneRelationships() throws {
        
        guard let relationships = richPopup.relationships,
              relationships.loadStatus == .loaded
        else {
            throw InvalidOperation()
        }
        
        let errors = relationships.manyToOne
            .compactMap { (manager) -> (ManyToOneRelationship, Error)? in
                // The relationship info is weakly referenced but should exist.
                // The feature is weakly referenced but should exist.
                guard let info = manager.relationshipInfo,
                      let feature = manager.popup?.geoElement as? AGSArcGISFeature
                else {
                    manager.cancelChange()
                    return (manager, Relationship.UnknownError())
                }
                // Depending on the relationship requirement, there might be a related record or there might not.
                if let relatedFeature = manager.relatedPopup?.geoElement as? AGSArcGISFeature {
                    manager.commitChange()
                    feature.relate(to: relatedFeature, relationshipInfo: info)
                }
                else {
                    manager.cancelChange()
                    if info.isComposite {
                        return (manager, ManyToOneRelationship.RequiredRelationship(name: manager.name ?? "(missing)"))
                    }
                }
                return nil
            }
        
        if !errors.isEmpty {
            throw ManyToOneRelationshipsEditingError(errors: errors)
        }
    }
    
    private func finishEditingOneToManyRelationships() throws {
        
        let relationships = parentOneToManyManagers.keyEnumerator().allObjects as! [OneToManyRelationship]
        
        let errors = relationships
            .compactMap { (relationship) -> (OneToManyRelationship, Error)? in
                if let parentManager = parentOneToManyManagers.object(forKey: relationship) {
                    // The feature is weakly referenced but should exist.
                    // The feature table is weakly referenced but should exist.
                    guard let feature = popup.geoElement as? AGSArcGISFeature,
                          let featureTable = feature.featureTable as? AGSArcGISFeatureTable
                    else {
                        return (relationship, Relationship.UnknownError())
                    }
                    
                    // Update or add, depending if the record is already a member of the table.
                    do {
                        if featureTable.canUpdate(feature) {
                            try parentManager.update(oneToMany: self.richPopup)
                        }
                        else if featureTable.canAddFeature {
                            try parentManager.add(oneToMany: self.richPopup)
                        }
                        else {
                            return (relationship, InvalidOperation())
                        }
                    }
                    catch {
                        return (relationship, error)
                    }
                }
                return nil
            }
        
        if !errors.isEmpty {
            throw OneToManyRelationshipsEditingError(errors: errors)
        }
    }
    
    // MARK:- Custom Validation
    
    /// Determine if the pop-up and related record editing session have validation errors.
    ///
    /// First, the validation checks if all composite many-to-one relationships have a record.
    /// Then, the manager checks if each editable display field validates.
    ///
    /// - Returns: An array of validation errors.
    ///
    func validatePopup() throws {
        
        guard isEditing else {
            throw InvalidOperation()
        }
        
        var invalids = [(String, Error)]()
        
        // Check M:1 relationships.
        // Only M:1 relationships can be edited during an editing session.
        if let relationships = richPopup.relationships {
            invalids += relationships.manyToOne
                .filter { record in
                    let isComposite = record.relationshipInfo?.isComposite ?? false
                    return isComposite && record.relatedPopup == nil
                }
                .map { relationship in
                    let name = relationship.name ?? "(unknown)"
                    return (name, ManyToOneRelationship.RequiredRelationship(name: name))
                }
        }
        
        // Check validity on all popup editable display fields.
        invalids += editableDisplayFields.compactMap {
            if let error = validationError(for: $0) {
                return ($0.fieldName, error)
            }
            else {
                return nil
            }
        }
        
        if !invalids.isEmpty {
            throw InvalidFields(fields: invalids)
        }
    }
    
    // MARK:- Public Editing Related Records
    
    // Section: Editing One To Many
    
    /// Add a one-to-many related record.
    ///
    /// - Note: Handles finding the relationship for the provided popup.
    ///
    func add(oneToMany popup: AGSPopup) throws {
        
        assert(!isEditing, "The pop-up manager must not be editing to add a one-to-many related record.")

        guard !isEditing else {
            throw InvalidOperation()
        }
        
        guard richPopup.relationships?.loadStatus == .loaded else {
            throw richPopup.relationships?.loadError ?? InvalidOperation()
        }
        
        guard let info = self.popup.relationship(to: popup) else {
            throw InvalidOperation()
        }
        
        guard info.isOneToMany else {
            throw InvalidOperation()
        }
        
        guard let feature = popup.geoElement as? AGSArcGISFeature,
              let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
              featureTable.canAddFeature
        else {
            throw InvalidOperation()
        }
        
        try update(oneToMany: popup, forRelationship: info)
    }
    
    /// Update a one-to-many related record.
    ///
    /// - Note: Handles finding the relationship for the provided popup.
    ///
    func update(oneToMany popup: AGSPopup) throws {
        
        assert(!isEditing, "The pop-up manager must not be editing to add a one-to-many related record.")
        
        guard !isEditing else {
            throw InvalidOperation()
        }
        
        guard richPopup.relationships?.loadStatus == .loaded else {
            throw richPopup.relationships?.loadError ?? InvalidOperation()
        }
        
        guard let info = self.popup.relationship(to: popup) else {
            throw InvalidOperation()
        }
        
        guard info.isOneToMany else {
            throw InvalidOperation()
        }
        
        guard let feature = popup.geoElement as? AGSArcGISFeature,
              let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
              featureTable.canUpdate(feature)
        else {
            throw InvalidOperation()
        }
        
        try update(oneToMany: popup, forRelationship: info)
    }
    
    /// Delete a one-to-many related record.
    ///
    /// - Note: Handles finding the relationship for the provided popup.
    ///
    func delete(oneToMany popup: AGSPopup) throws {
        
        assert(!isEditing, "Removing pop-up but manager is in editing session.")
        
        guard !isEditing else {
            throw InvalidOperation()
        }
        
        guard let info = self.popup.relationship(to: popup) else {
            throw InvalidOperation()
        }
        
        guard info.isOneToMany else {
            throw InvalidOperation()
        }
        
        guard let feature = popup.geoElement as? AGSArcGISFeature,
              let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
              featureTable.canDelete(feature)
        else {
            throw InvalidOperation()
        }
        
        try delete(oneToMany: popup, forRelationship: info)
    }
    
    // Section: Editing One To Many
    
    /// Updates the relationship of a many-to-one related record.
    ///
    /// - Note: Handles finding the relationship for the provided popup.
    ///
    func update(manyToOne popup: AGSPopup) throws {
        
        assert(isEditing, "The pop-up manager must be editing to update a many-to-one related record.")
        
        guard isEditing else {
            throw InvalidOperation()
        }
        
        guard richPopup.relationships?.loadStatus == .loaded else {
            throw richPopup.relationships?.loadError ?? InvalidOperation()
        }
        
        guard let info = self.popup.relationship(to: popup) else {
            throw InvalidOperation()
        }
        
        guard info.isManyToOne else {
            throw InvalidOperation()
        }
        
        try update(manyToOne: popup, forRelationship: info)
    }
    
    // MARK:- Delete Rich Popup
    
    /// Handles deleting parent manager associations.
    func deleteRichPopup() throws {
        var errors = [(OneToManyRelationship, Error)]()
        // Inform any parent one to many managers that this pop-up is to be deleted.
        for relationship in parentOneToManyManagers.keyEnumerator() {
            if let relationship = relationship as? OneToManyRelationship {
                if let parentManager = parentOneToManyManagers.object(forKey: relationship) {
                    do {
                        try parentManager.delete(oneToMany: richPopup)
                    }
                    catch {
                        errors.append((relationship, error))
                    }
                }
            }
        }
        
        if !errors.isEmpty {
            throw OneToManyRelationshipsEditingError(errors: errors)
        }
    }
    
    // MARK:- Private Editing Related Records
    
    // Section: Many To One

    /// Stage and relate a new many-to-one record for a particular relationship info.
    ///
    /// - Parameters:
    ///   - popup: The new record to relate.
    ///   - info: The relationship info defining which related record to update.
    ///
    /// - Throws: An error if there is a problem staging or relating the new record.
    ///
    private func update(manyToOne popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
        guard let relationships = richPopup.relationships,
              relationships.loadStatus == .loaded
        else {
            throw richPopup.relationships?.loadError ?? InvalidOperation()
        }
        
        guard isEditing else {
            throw InvalidOperation()
        }
        
        guard !info.isComposite else {
            // Data Collection does not support non-composite many to one relationships at this time.
            throw InvalidOperation()
        }
        
        let foundManager = relationships.manyToOne.first { $0.relationshipInfo == info }
        
        guard let manager = foundManager else {
            throw InvalidOperation()
        }
        
        // Stage the related popup. Relating the pop-up will come if the user saves the session.
        manager.editRelatedPopup(popup)
    }
    
    // MARK: One To Many
    
    private let parentOneToManyManagers = NSMapTable<OneToManyRelationship, RichPopupManager>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    
    /// Builds a new rich pop-up and pop-up manager for a specific one-to-many relationship.
    ///
    /// - NOTE: Use this function to create a new one-to-many related record pop-up manager so that changes made to the new record
    /// are also reflected by this, the parent pop-up manager.
    ///
    func buildRichPopupManagerForNewOneToManyRecord(for relationship: OneToManyRelationship) throws -> RichPopupManager {
        
        guard self.richPopup.relationships?.loadStatus == .loaded else {
            throw self.richPopup.relationships?.loadError ?? InvalidOperation()
        }
        
        guard !isEditing else {
            throw InvalidOperation()
        }
        
        guard let popup = relationship.createNewRecord() else {
            throw InvalidOperation()
        }
        
        let richPopup = RichPopup(popup: popup)
        let richPopupManager = RichPopupManager(richPopup: richPopup)
        
        richPopupManager.parentOneToManyManagers.setObject(self, forKey: relationship)
        
        return richPopupManager
    }
    
    /// Builds a new rich pop-up manager for existing pop-up for a specific index path.
    ///
    /// - NOTE: Use this function to create a new one-to-many related record pop-up manager so that changes made to the new record
    /// are also reflected by this, the parent pop-up manager.
    ///
    public func buildRichPopupManagerForExistingRecord(at indexPath: IndexPath) throws -> RichPopupManager {
        
        guard self.richPopup.relationships?.loadStatus == .loaded else {
            throw self.richPopup.relationships?.loadError ?? InvalidOperation()
        }
        
        guard !isEditing else {
            throw InvalidOperation()
        }
        
        let manager: RichPopupManager
        
        if let manyToOneRelationship = self.relationship(forIndexPath: indexPath) as? ManyToOneRelationship {
            guard let popup = manyToOneRelationship.relatedPopup else {
                throw InvalidOperation()
            }
            let richPopup = RichPopup(popup: popup)
            manager = RichPopupManager(richPopup: richPopup)
        }
        else if let oneToManyRelationship = self.relationship(forIndexPath: indexPath) as? OneToManyRelationship {
            guard let popup = oneToManyRelationship.popup(forIndexPath: indexPath) else {
                throw InvalidOperation()
            }
            let richPopup = RichPopup(popup: popup)
            manager = RichPopupManager(richPopup: richPopup)
            manager.parentOneToManyManagers.setObject(self, forKey: oneToManyRelationship)
        }
        else {
            assertionFailure("Unsupported relationship type.")
            throw InvalidOperation()
        }
        
        return manager
    }
    
    public func parentOneToManyManagersCurrentlyMaintained() -> [RichPopupManager] {
        parentOneToManyManagers.keyEnumerator().allObjects
            .compactMap{ (relationship) -> RichPopupManager? in
                if let relationship = relationship as? OneToManyRelationship {
                    return parentOneToManyManagers.object(forKey: relationship)
                }
                return nil
            }
    }
    
    /// Stage and relate a new one-to-many record for a particular relationship info.
    ///
    /// - Parameters:
    ///   - popup: The new record to relate.
    ///   - info: The relationship info defining which related record to update.
    ///
    /// - Throws: An error if there is a problem staging or relating the new record.
    ///
    private func update(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
        guard let feature = popup.geoElement as? AGSArcGISFeature else {
            preconditionFailure("Unsupported record type.")
        }
        
        let foundManager = richPopup.relationships?.oneToMany
            .first { (manager) -> Bool in
                guard let relationshipInfo = manager.relationshipInfo else { return false }
                return relationshipInfo == info
            }
        
        guard let relationship = foundManager,
              let relatedFeature = relationship.popup?.geoElement as? AGSArcGISFeature,
              let info = relationship.relationshipInfo
        else {
            throw InvalidOperation()
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
        
        guard let feature = popup.geoElement as? AGSArcGISFeature else {
            preconditionFailure("Unsupported record type.")
        }
        
        let foundRelationship = richPopup.relationships?.oneToMany
            .first { (manager) -> Bool in
                guard let relationshipInfo = manager.relationshipInfo else { return false }
                return relationshipInfo == info
            }

        guard let relationship = foundRelationship,
              let relatedFeature = relationship.popup?.geoElement as? AGSArcGISFeature
        else {
            throw InvalidOperation()
        }
        
        // Unrelate the two records.
        feature.unrelate(to: relatedFeature)

        // Delete the popup from the model.
        relationship.removeRelatedPopup(popup)
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
        else if indexPathIsAddOneToMany(indexPath) || indexPathWithinOneToMany(indexPath) {
           
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

        // Sections that represent one-to-many relationships are represented by indices 1..n.
        // We want to offset the section index by -1.
        let sectionIndex = indexPath.section - 1

        // The offset section index must not be larger than (n) managers.
        guard managers.count > sectionIndex else {
            return false
        }

        let manager = managers[sectionIndex]

        var rowOffset = 0
        
        // If the table can add a feature, the first cell in the section is reserved for adding a new feature.
        if manager.canAddRecord {
            
            if indexPath.row == 0 {
                return false
            }
            else {
                rowOffset = 1
            }
        }

        return manager.relatedPopups.count > indexPath.row - rowOffset
    }
    
    /// Does the index path lies within the one-to-many section's add new row (index `0`)?
    ///
    /// This function is designed to be used with a `UITableViewDataSource`.
    ///
    /// - Parameter indexPath: The index path in question.
    ///
    /// - Returns: If the index path lies within the one-to-many section's add new row (index `0`).
    ///
    func indexPathIsAddOneToMany(_ indexPath: IndexPath) -> Bool {
        
        guard indexPath.section > 0, richPopup.relationships?.loadStatus == .loaded, let managers = richPopup.relationships?.oneToMany else {
            return false
        }
        
        // Sections that represent one-to-many relationships are represented by indices 1..n.
        // We want to offset the section index by -1.
        let sectionIndex = indexPath.section - 1
        
        // The offset section index must not be larger than (n) managers.
        guard managers.count > sectionIndex else {
            return false
        }
        
        let manager = managers[sectionIndex]
        
        if manager.canAddRecord, indexPath.row == 0 {
            return true
        }
        else {
            return false
        }
    }
}

extension RichPopupManager {
    
    struct InvalidOperation: LocalizedError {
        var errorDescription: String? { "The operation you are trying to perform is not permitted." }
    }
    
    struct InvalidFields: LocalizedError {
        let fields: [(name: String, error: Error)]
        var errorDescription: String? {
            "Invalid fields: \(fields.map{$0.name}.joined(separator: ","))"
        }
    }
    
    struct ManyToOneRelationshipsEditingError: LocalizedError, LocalizedEditingError {
        let errors: [(ManyToOneRelationship, Error)]
        
        var errorDescription: String? {
            "Failed to edit M:1 relationships: \(errors.map{$0.0.name ?? "(no name)"}.joined(separator: ","))"
        }
        
        var editingErrorDescription: String {
            "\(errors.count) failed M:1 edits."
        }
    }
    
    struct OneToManyRelationshipsEditingError: LocalizedError, LocalizedEditingError {
        let errors: [(OneToManyRelationship, Error)]
        
        var errorDescription: String? {
            "Failed to edit 1:M relationships: \(errors.map{$0.0.name ?? "(no name)"}.joined(separator: ","))"
        }
        
        var editingErrorDescription: String {
            "\(errors.count) failed 1:M edits."
        }
    }
    
    struct EditingError: LocalizedError {
        
        var attributes: Error?
        var manyToOne: ManyToOneRelationshipsEditingError?
        var oneToMany: OneToManyRelationshipsEditingError?
        
        var errorDescription: String? {
            var description = "Failed to edit record."
            if let attributes = attributes {
                description += "\n\(attributes.localizedDescription)"
            }
            if let manyToOne = manyToOne {
                description += "\n\(manyToOne.editingErrorDescription)"
            }
            if let oneToMany = oneToMany {
                description += "\n\(oneToMany.editingErrorDescription)"
            }
            return description
        }
    }
}

fileprivate protocol LocalizedEditingError {
    var editingErrorDescription: String { get }
}
