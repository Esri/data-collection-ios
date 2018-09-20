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

class PopupRelatedRecordsManager: AGSPopupManager {
    
    private(set) var manyToOne = [ManyToOneManager]()
    private(set) var oneToMany = [OneToManyManager]()
    
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
        
        for manager in manyToOne {
            do {
                try manager.commitChange()
            }
            catch {
                relatedRecordsError = error
            }
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
    
    func validatePopup() -> [Error] {
        
        guard isEditing else {
            return [Error]()
        }
        
        var invalids = [Error]()
        
        // 1. enforce M:1 relationships if composite
        invalids += manyToOne
            .filter { record in
                guard let info = record.relationshipInfo else { return false }
                
                if info.isComposite { return record.relatedPopup == nil }
                else { return false }
            }
            .map { return RelatedRecordsManagerError.missingManyToOneRelationship($0.name ?? "Unknown") as Error }
        
        // 2. enforce validity on all popup fields
        invalids += editableDisplayFields.compactMap { return validationError(for: $0) }
        
        return invalids
    }
    
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

        for info in relatedRecordsInfos {
            
            guard featureTable.isPopupEnabledFor(relationshipInfo: info) else {
                continue
            }
            
            let foundRelatedTable = featureTable.relatedTables()?.first { $0.serviceLayerID == info.relatedTableID }
            
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
        let offsetIndex = indexPath.row - rowOffset

        return manyToOne.count > offsetIndex
    }

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
