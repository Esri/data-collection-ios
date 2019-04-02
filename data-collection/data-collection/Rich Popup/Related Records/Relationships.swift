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
        
        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
            featureTable.layerInfo != nil else {
            return nil
        }
        
        self.popup = popup
    }
    
    private(set) var manyToOne = [ManyToOneRelationship]()
    
    private(set) var oneToMany = [OneToManyRelationship]()
    
    private var loadingRelationships: [AGSLoadable]?
    
    override func doCancelLoading() {
        
        if let loadables = loadingRelationships {
            
            loadingRelationships = nil
            
            for manager in loadables {
                manager.cancelLoad()
            }
        }
        
        clear()
        
        loadDidFinishWithError(NSError.userCancelled)
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        if retrying {
            clear()
        }
        
        guard let popup = popup else {
            loadDidFinishWithError(NSError.unknown)
            return
        }
        
        guard let feature = popup.geoElement as? AGSArcGISFeature else {
            loadDidFinishWithError(FeatureTableError.invalidFeature)
            return
        }
        
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            loadDidFinishWithError(FeatureTableError.invalidFeatureTable)
            return
        }
        
        guard let layerInfo = featureTable.layerInfo else {
            loadDidFinishWithError(FeatureTableError.missingRelationshipInfos)
            return
        }
        
        var loadables = [AGSLoadable]()
        
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
            
            var errors = [Error]()
            
            for relationship in loadedRelationships {
                
                guard relationship.loadStatus == .loaded else {
                    
                    if let error = relationship.loadError {
                        errors.append(error)
                    }
                    
                    continue
                }
                
                if relationship is OneToManyRelationship {
                    self.oneToMany.append(relationship as! OneToManyRelationship)
                }
                
                if relationship is ManyToOneRelationship {
                    self.manyToOne.append(relationship as! ManyToOneRelationship)
                }
            }
            
            if !errors.isEmpty {
                self.loadDidFinishWithError(LoadableError.multiLoadableFailure("related records", errors))
            }
            else {
                self.loadDidFinishWithError(nil)
            }
        }
    }
    
    private func clear() {

        manyToOne.removeAll()
        oneToMany.removeAll()
    }
}
