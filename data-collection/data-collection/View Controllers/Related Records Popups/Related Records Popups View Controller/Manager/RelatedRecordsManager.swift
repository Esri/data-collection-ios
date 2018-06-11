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

class RelatedRecordsManager {
    
    weak internal private(set) var popup: AGSPopup?
    weak var relationshipInfo: AGSRelationshipInfo?
    weak var relatedTable: AGSArcGISFeatureTable?
    
    init?(relationshipInfo info: AGSRelationshipInfo, table: AGSArcGISFeatureTable?, popup: AGSPopup) {
        
        guard info.cardinality == .oneToMany else {
            return nil
        }
        
        self.relationshipInfo = info
        self.relatedTable = table
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
    
    var name: String? {
        return relatedTable?.tableName
    }
}

class OneToManyManager: RelatedRecordsManager {
    
    internal private(set) var relatedPopups = [AGSPopup]()
    
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
    
    func addPopup(_ newRelatedPopup: AGSPopup) throws {
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = newRelatedPopup.geoElement as? AGSArcGISFeature,
            let info = relationshipInfo
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        feature.relate(to: relatedFeature, relationshipInfo: info)
        
        if !relatedPopups.contains(newRelatedPopup) {
            relatedPopups.append(newRelatedPopup)
        }
    }
    
    func deletePopup(_ removedRelatedPopup: AGSPopup) throws {
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = removedRelatedPopup.geoElement as? AGSArcGISFeature,
            let relatedFeatureID = relatedFeature.objectID
            else {
                throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        feature.unrelate(to: relatedFeature)

        var foundPopupIndex: Int?
        
        for (idx, popup) in relatedPopups.enumerated() {
            
            guard
                let feature = popup.geoElement as? AGSArcGISFeature,
                let oid = feature.objectID
                else {
                    continue
            }
            
            if oid == relatedFeatureID {
                foundPopupIndex = idx
                break
            }
        }
        
        guard let idx = foundPopupIndex else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        relatedPopups.remove(at: idx)
    }
}

class ManyToOneManager: RelatedRecordsManager {
    
    var relatedPopup: AGSPopup? {
        get {
            return stagedRelatedPopup ?? currentRelatedPopup
        }
        set {
            stagedRelatedPopup = newValue
        }
    }
    
    private var currentRelatedPopup: AGSPopup?
    
    private var stagedRelatedPopup: AGSPopup?
    
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
            
            self?.currentRelatedPopup = popups.first
            
            completion(nil)
        }
    }
    
    func cancelChange() {
        
        stagedRelatedPopup = nil
    }
    
    func commitChange() throws {
        
        guard let info = relationshipInfo else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        guard let newRelatedPopup = stagedRelatedPopup else {
            if info.isComposite {
                throw RelatedRecordsManagerError.invalidPopup
            }
            return
        }
        
        guard
            let feature = popup?.geoElement as? AGSArcGISFeature,
            let relatedFeature = newRelatedPopup.geoElement as? AGSArcGISFeature
            else {
            throw RelatedRecordsManagerError.cannotRelateFeatures
        }
        
        feature.relate(to: relatedFeature, relationshipInfo: info)
        
        stagedRelatedPopup = nil
        currentRelatedPopup = newRelatedPopup
    }
}
