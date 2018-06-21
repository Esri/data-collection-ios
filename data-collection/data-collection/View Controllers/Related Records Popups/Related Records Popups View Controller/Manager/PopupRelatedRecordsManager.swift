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

class PopupRelatedRecordsManager: AGSPopupManager {
    
    internal var manyToOne = [ManyToOneManager]()
    internal var oneToMany = [OneToManyManager]()
    
    // MARK: Popup Manager Editing Session
    
    override func cancelEditing() {
        
        // 1. Many To One
        
        manyToOne.forEach { (manager) in
            manager.cancelChange()
        }
        
        // 2. Cancel Session
        
        super.cancelEditing()
    }
    
    override func finishEditing(completion: @escaping (Error?) -> Void) {
        
        // 1. Many To One
        
        var relatedRecordsError: Error?
        
        do {
            for manager in manyToOne {
                try manager.commitChange()
            }
        }
        catch {
            relatedRecordsError = error
        }
        
        // 2. Validate Fields
        
        super.finishEditing { (error) in
            
            guard error == nil, relatedRecordsError == nil else {
                completion(RelatedRecordsManagerError.invalidPopup)
                return
            }
            
            completion(error)
        }
    }
    
    // MARK: Custom Validation
    
    func validatePopup() -> [Error]? {
        
        guard isEditing else {
            return nil
        }
        
        var invalids = [Error]()
        
        // 1. enforce M:1 relationships if composite
        invalids += manyToOne
            .filter { return ($0.relationshipInfo != nil) ? false : $0.relationshipInfo!.isComposite ? $0.relatedPopup == nil : false }
            .map    { return RelatedRecordsManagerError.missingManyToOneRelationship($0.name ?? "Unknown") as Error }
        
        // 2. enforce validity on all popup fields
        invalids += editableDisplayFields.compactMap { return validationError(for: $0) }
        
        for field in displayFields {
            if let error = validationError(for: field) {
                print(error, "for field", field.fieldName, field.label)
            }
        }
        
        return invalids
    }
    
    func loadRelatedRecords(_ completion: @escaping ()->Void) {
        
        manyToOne.removeAll()
        oneToMany.removeAll()
        
        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let relatedRecordsInfos = feature.relatedRecordsInfos,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable
            else {
                completion()
                return
        }

        let dispatchGroup = DispatchGroup()

        for info in relatedRecordsInfos {
            
            guard featureTable.isPopupEnabledFor(relationshipInfo: info) else {
                continue
            }
            
            var foundRelatedTable: AGSArcGISFeatureTable?
            
            if let relatedTables = featureTable.relatedTables() {
                for relatedTable in relatedTables {
                    if relatedTable.serviceLayerID == info.relatedTableID {
                        foundRelatedTable = relatedTable
                        break
                    }
                }
            }

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
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
    // MARK: Many To One

    func update(manyToOne popup: AGSPopup?, forRelationship info: AGSRelationshipInfo) throws {
        
        guard isEditing else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }

        var foundManager: ManyToOneManager?
        
        for manager in manyToOne {
            
            guard let relationshipInfo = manager.relationshipInfo else {
                continue
            }
            
            if relationshipInfo == info {
                foundManager = manager
                break
            }
        }
        
        guard let manager = foundManager else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        manager.relatedPopup = popup
    }
    
    // MARK: One To Many
    
    func edit(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
        guard !isEditing else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }

        var foundManager: OneToManyManager?

        for manager in oneToMany {

            guard let relationshipInfo = manager.relationshipInfo else {
                continue
            }

            if relationshipInfo == info {
                foundManager = manager
                break
            }
        }

        guard let manager = foundManager else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }

        do {
            try manager.editPopup(popup)
        }
        catch {
            throw error
        }
    }
    
    func delete(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {

        guard !isEditing else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        var foundManager: OneToManyManager?

        for manager in oneToMany {

            guard let relationshipInfo = manager.relationshipInfo else {
                continue
            }

            if relationshipInfo == info {
                foundManager = manager
                break
            }
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
    
    func attributeField(forIndexPath indexPath: IndexPath) -> AGSPopupField? {
        
        guard indexPathWithinAttributes(indexPath) else {
            return nil
        }
        
        let attributeFields = isEditing ? editableDisplayFields : displayFields
        return attributeFields[indexPath.row]
    }
    
    func relatedRecordManager(forIndexPath indexPath: IndexPath) -> RelatedRecordsManager? {
        
        if indexPathWithinManyToOne(indexPath) {
            
            let rowOffset = isEditing ? editableDisplayFields.count : displayFields.count
            let rowIDX = indexPath.row - rowOffset
            return manyToOne[rowIDX]
        }
        else if indexPathWithinOneToMany(indexPath) {
            
            let sectionOffset = 1
            let sectionIDX = indexPath.section - sectionOffset
            return oneToMany[sectionIDX]
        }
        
        return nil
    }
}

extension PopupRelatedRecordsManager {
    
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        
        guard indexPath.section == 0 else {
            return false
        }
        
        let nFields = isEditing ? editableDisplayFields.count : displayFields.count
        
        return indexPath.row < nFields
    }
    
    func indexPathWithinManyToOne(_ indexPath: IndexPath) -> Bool {

        guard indexPath.section == 0 else {
            return false
        }

        let rowOffset = isEditing ? editableDisplayFields.count : displayFields.count
        let offsetIDX = indexPath.row - rowOffset

        return manyToOne.count > offsetIDX
    }

    func indexPathWithinOneToMany(_ indexPath: IndexPath) -> Bool {

        guard indexPath.section > 0 else {
            return false
        }

        let sectionOffset = 1
        let sectionIDX = indexPath.section - sectionOffset

        guard oneToMany.count > sectionIDX else {
            return false
        }

        let manager = oneToMany[sectionIDX]

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
