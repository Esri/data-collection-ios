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

class Relationships: AGSLoadableBase {
    
    weak private(set) var popup: AGSPopup?
    
    init?(popup: AGSPopup) {
        
        guard let feature = popup.geoElement as? AGSArcGISFeature,
              let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
              featureTable.layerInfo != nil
        else {
            return nil
        }
        
        self.popup = popup
    }
    
    private(set) var manyToOne = [ManyToOneRelationship]()
    
    private(set) var oneToMany = [OneToManyRelationship]()
    
    private var loadingRelationships: [Relationship]?
    
    override func doCancelLoading() {
        
        if let loadables = loadingRelationships {
            
            loadingRelationships = nil
            
            for manager in loadables {
                manager.cancelLoad()
            }
        }
        
        clear()
        
        loadDidFinishWithError(CancelledError())
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        if retrying {
            clear()
        }
        
        guard let popup = popup else {
            loadDidFinishWithError(MissingRecordError())
            return
        }
        
        guard let feature = popup.geoElement as? AGSArcGISFeature,
              let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
              let layerInfo = featureTable.layerInfo
        else {
            preconditionFailure("Cannot load Relationships, invalid data model.")
        }
        
        var loadables = [Relationship]()
        
        for info in layerInfo.relationshipInfos {
            
            // Ensure popup's are enabled for this relationship info.
            guard featureTable.isPopupEnabled(for: info) else {
                continue
            }
            
            // We only load relationships whose cardinality is one to many for either role (one-to-many & many-to-one).
            guard info.cardinality == .oneToMany else {
                continue
            }
            
            // Find the table on the other end of the relationship.
            if let foundRelatedTable = featureTable.relatedTables()?.first(where: { $0.serviceLayerID == info.relatedTableID }) {
                
                if info.isManyToOne, let relationship = ManyToOneRelationship(relationshipInfo: info, table: foundRelatedTable, popup: popup) {
                    loadables.append(relationship)
                }
                else if info.isOneToMany, let relationship = OneToManyRelationship(relationshipInfo: info, table: foundRelatedTable, popup: popup) {
                    loadables.append(relationship)
                }
            }
        }
        
        self.loadingRelationships = loadables
        
        AGSLoadObjects(loadables) { [weak self] (success) in
            
            guard let self = self else { return }
            
            guard let loadedRelationships = self.loadingRelationships else {
                return
            }
            
            self.loadingRelationships = nil
            
            let errors = loadedRelationships.reduce(into: [Relationship: Error]()) { (errors, relationship) in
                if let error = relationship.loadError {
                    errors[relationship] = error
                }
            }
            
            guard errors.isEmpty else {
                self.loadDidFinishWithError(
                    RelationshipsLoadError(errors: errors)
                )
                return
            }
                        
            for relationship in loadedRelationships {
                if relationship is OneToManyRelationship {
                    self.oneToMany.append(relationship as! OneToManyRelationship)
                }
                
                if relationship is ManyToOneRelationship {
                    self.manyToOne.append(relationship as! ManyToOneRelationship)
                }
            }
            
            self.loadDidFinishWithError(nil)
        }
    }
    
    // MARK: Errors
    
    struct CancelledError: LocalizedError {
        var localizedDescription: String { "Cancelled loading relationships." }
    }
    
    struct RelationshipsLoadError: LocalizedError {
        let errors: [Relationship: Error]
        var localizedDescription: String {
            "Failed to load relationships: \(errors.keys.map{ $0.name ?? "(missing tablename)" }.joined(separator: ","))"
        }
    }
    
    struct MissingRecordError: LocalizedError {
        var localizedDescription: String { "Missing record." }
    }
    
    // MARK: Clear Related Records
    
    private func clear() {

        manyToOne.removeAll()
        oneToMany.removeAll()
    }
}
