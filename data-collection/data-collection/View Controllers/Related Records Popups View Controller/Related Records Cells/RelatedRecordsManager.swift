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
    
    private var oneToMany = [OneToManyManager]()
    private var manyToOne = [ManyToOneManager]()
    
    override func startEditing() -> Bool {
        
        // TODO build out
        return super.startEditing()
    }
    
    override func cancelEditing() {
        
        // TODO build out
        super.cancelEditing()
    }
    
    override func finishEditing(completion: @escaping (Error?) -> Void) {
        
        super.finishEditing { [weak self] (error) in
            
            guard self?.validatePopup() == nil else {
                completion(RelatedRecordsManagerError.invalidPopup)
                return
            }
            
            completion(error)
        }
    }
    
    func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool {
        
        guard indexPath.section == 0 else {
            return false
        }
        
        let nFields = isEditing ? editableDisplayFields.count : displayFields.count
        
        return indexPath.row < nFields
    }
    
    func validatePopup() -> [Error]? {
        
        guard isEditing else {
            return nil
        }
        
        var invalids = [Error]()
        
        for field in editableDisplayFields {
            if let error = validationError(for: field) {
                invalids.append(error)
            }
        }
        
        // TODO enforce M:1 relationships exist.
        for manager in manyToOne {
            if manager.relatedPopup == nil {
                let error = RelatedRecordsManagerError.missingManyToOneRelationship(manager.name ?? "Unknown")
                invalids.append(error)
            }
        }
        
        return invalids
    }
    
    // TODO
    func save() throws {
        // 1. Are Fields Valid?
        // 2. Many To One Records all existing
        // 3. Are All Related Records Valid?
        // 4. Save
        // 4a. Locally
        // 4b. Remotely
        // 5. Update local data from Remote.
    }
    //
    
    func loadRelatedRecords(_ completion: @escaping ()->Void) {
        
        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let relatedRecordsInfos = feature.relatedRecordsInfos,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable
            else {
                completion()
                return
        }
        
        oneToMany.removeAll()
        manyToOne.removeAll()
        
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
    
    func numberOfSections() -> Int {
        return 1 + manyToOne.count
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        
        if section == 0 {
            let nFields = isEditing ? editableDisplayFields.count : displayFields.count
            return nFields + manyToOne.count
        }
        else {
            let idx = section - 1
            guard oneToMany.count > idx else {
                return 0
            }
            return oneToMany[idx].relatedPopups.count
        }
    }
    
    func maxAttributes(forSection section: Int) -> Int {
        return section == 0 ? 2 : 3
    }
    
    func header(forSection section: Int) -> String? {
        
        guard section > 0 else {
            return nil
        }
        
        let offset = section - 1
        
        return oneToMany[offset].name
    }
    
    func field(forIndexPath indexPath: IndexPath) -> AGSPopupField? {
        
        guard indexPath.section == 0 else {
            return nil
        }
        
        let fields = isEditing ? editableDisplayFields : displayFields
        
        guard indexPath.row < fields.count else {
            return nil
        }
        
        return fields[indexPath.row]
    }
    
    func popup(forIndexPath indexPath: IndexPath) -> AGSPopup? {
        
        // Many To One
        if indexPath.section == 0 {
            let offset = isEditing ? editableDisplayFields.count : displayFields.count
            let idx = indexPath.row - offset
            let manager = manyToOne[idx]
            return manager.relatedPopup
        }
        
        // One To Many
        else {
            let offset = 1
            let idx = indexPath.section - offset
            let manager = oneToMany[idx]
            guard manager.relatedPopups.count > indexPath.row else {
                return nil
            }
            return manager.relatedPopups[indexPath.row]
        }
    }
    
    // MARK: Many To One
    
    func update(manyToOne popup: AGSPopup?, forRelationship info: AGSRelationshipInfo) {

        if let manager = manyToOne.first(where: { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
            
        }) {
            manager.popup = popup
        }
    }
    
    // MARK: One To Many
    
    func add(oneToMany popup: AGSPopup, forRelationship info: AGSRelationshipInfo) {
        
        if let manager = oneToMany.first(where: { (manager) -> Bool in
            
            guard let relationshipInfo = manager.relationshipInfo else {
                return false
            }
            
            return relationshipInfo == info
            
        }) {
            do {
                try manager.relate(relatedPopup: popup)
            }
            catch {
                print("[Error]", error.localizedDescription)
            }
        }
    }
}

class RelatedRecordsManager {
    
    weak var popup: AGSPopup?
    weak var relationshipInfo: AGSRelationshipInfo?
    
    init?(relationshipInfo info: AGSRelationshipInfo, popup: AGSPopup) {
        
        guard info.cardinality == .oneToMany else {
            return nil
        }
        
        self.relationshipInfo = info
        self.popup = popup
    }
    
    func load(records completion: @escaping ([AGSPopup]?, Error?) -> Void) {
        
        guard let feature = self.popup?.geoElement as? AGSArcGISFeature else {
            completion(nil, FeatureTableError.missingFeature)
            return
        }
        
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            completion(nil, FeatureTableError.missingFeatureTable)
            return
        }
        
        guard let info = self.relationshipInfo else {
            completion(nil, FeatureTableError.missingRelationshipInfos)
            return
        }
        
        featureTable.queryRelatedFeaturesAsPopups(forFeature: feature, relationship: info) { (popupsResults, error) in
            
            guard error == nil else {
                completion(nil, error!)
                return
            }
            
            guard let popups = popupsResults else {
                completion(nil, FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            completion(popups, nil)
        }
    }
}

class OneToManyManager: RelatedRecordsManager {
    
    var relatedPopups = [AGSPopup]()
    
    var name: String? {
        return (relatedPopups.first?.geoElement as? AGSArcGISFeature)?.featureTable?.tableName
    }

    func relate(relatedPopup: AGSPopup) throws {

        // TODO safeguard if added to table?
        guard let popup = popup, let info = relationshipInfo else {
            // TODO safeguard can relate?
            // TODO throw
            return
        }
        
        popup.relate(toPopup: relatedPopup, relationshipInfo: info)
    }
    
    func unrelate(relatedPopup: AGSPopup) throws {
        
        guard let popup = popup else {
            // TODO safeguard?
            // TODO throw
            return
        }
        
        popup.unrelate(toPopup: relatedPopup)
    }
    
    func load(records completion: @escaping (Error?) -> Void) {
        
        super.load { [weak self] (popupsResults, error) in
            
            if let err = error {
                completion(err)
                return
            }
            
            guard let popups = popupsResults else {
                completion(FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            self?.relatedPopups = popups
            
            completion(nil)
        }
    }
}

class ManyToOneManager: RelatedRecordsManager {
    
    var relatedPopup: AGSPopup?
    
    var name: String? {
        return (relatedPopup?.geoElement as? AGSArcGISFeature)?.featureTable?.tableName
    }
    
    func load(records completion: @escaping (Error?) -> Void) {
        
        super.load { [weak self] (popupsResults, error) in
            
            if let err = error {
                completion(err)
                return
            }
            
            guard let popups = popupsResults else {
                completion(FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            self?.relatedPopup = popups.first
            
            completion(nil)
        }
    }
}

