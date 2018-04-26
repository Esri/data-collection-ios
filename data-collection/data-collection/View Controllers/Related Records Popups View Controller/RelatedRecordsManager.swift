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

extension Collection where Iterator.Element == RelatedRecordsManager {
    
    var manyToOneLoaded: [RelatedRecordsManager] {
        return filter({ (relatedRecord) -> Bool in
            
            guard let relationshipInfo = relatedRecord.relationshipInfo else {
                return false
            }
            
            return relatedRecord.loadStatus == .loaded && relationshipInfo.isManyToOne
        })
    }
    
    var oneToManyLoaded: [RelatedRecordsManager] {
        return filter({ (relatedRecord) -> Bool in
            
            guard let relationshipInfo = relatedRecord.relationshipInfo else {
                return false
            }
            
            return relatedRecord.loadStatus == .loaded && relationshipInfo.isOneToMany
        })
    }
}

class RelatedRecordsManager: AGSLoadableBase {
    
    weak var feature: AGSArcGISFeature?
    weak var relationshipInfo: AGSRelationshipInfo?
    
    var popups = [AGSPopup]()
    
    var name: String? {
        return (popups.first?.geoElement as? AGSArcGISFeature)?.featureTable?.tableName
    }
    
    init?(relationshipInfo info: AGSRelationshipInfo, feature: AGSArcGISFeature) {
        
        guard info.cardinality == .oneToMany else {
            return nil
        }
        
        self.relationshipInfo = info
        self.feature = feature
    }
    
    override func doCancelLoading() {
        loadDidFinishWithError(NSUserCancelledError as? Error)
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        popups.removeAll()
        
        guard let feature = self.feature, let featureTable = feature.featureTable as? AGSServiceFeatureTable, let relationshipInfo = self.relationshipInfo else {
            // TODO redo all Errors
            loadDidFinishWithError(NSError(domain: "com.esri.redo.me", code: 0, userInfo: [NSLocalizedDescriptionKey : "Feature does not belong to a feature table"]))
            return
        }
        
        featureTable.queryOneToManyRelatedFeatures(for: feature, withRelationship: relationshipInfo, queryFeatureFields: .loadAll, completion: { [weak self] (features, error) in
            
            guard error == nil else {
                self?.loadDidFinishWithError(error!)
                return
            }
            
            guard let features = features else {
                self?.loadDidFinishWithError(NSError(domain: "com.esri.redo.me", code: 1, userInfo: [NSLocalizedDescriptionKey : "Missing Features in results"]))
                return
            }
            
            for feature in features {
                if let popup = feature.asPopup {
                    self?.popups.append(popup)
                }
            }
            
            self?.loadDidFinishWithError(nil)
        })
    }
}

