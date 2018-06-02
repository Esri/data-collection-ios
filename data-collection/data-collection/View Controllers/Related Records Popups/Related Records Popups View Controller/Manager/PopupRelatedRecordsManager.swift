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

// TODO hook in services
// TODO thread safe?
class PopupRelatedRecordsManager: AGSPopupManager {
    
    internal var oneToMany = [OneToManyManager]()
    internal var manyToOne = [ManyToOneManager]()
    
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

        // 1. enforce M:1 relationships exist
        // TODO make swifty
        for manager in manyToOne {
            if manager.relatedPopup == nil {
                let error = RelatedRecordsManagerError.missingManyToOneRelationship(manager.name ?? "Unknown")
                invalids.append(error)
            }
        }
        
        // 2. enforce validity on all popup fields
        // TODO make swifty
        for field in editableDisplayFields {
            if let error = validationError(for: field) {
                invalids.append(error)
            }
        }
        
        return invalids
    }
    
    func loadRelatedRecords(_ completion: @escaping ()->Void) {
        
        oneToMany.removeAll()
        manyToOne.removeAll()
        
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
            
            // TODO work this rule into AppRules
            guard featureTable.isPopupEnabledFor(relationshipInfo: info) else {
                continue
            }
            
            if info.isManyToOne, let manager = ManyToOneManager(relationshipInfo: info, popup: popup) {
                
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
            else if info.isOneToMany, let manager = OneToManyManager(relationshipInfo: info, popup: popup) {
                
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
    
    func add(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) throws {
        
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
            try manager.addPopup(popup)
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
            try manager.deletePopup(popup)
        }
        catch {
            throw error
        }
    }
}

