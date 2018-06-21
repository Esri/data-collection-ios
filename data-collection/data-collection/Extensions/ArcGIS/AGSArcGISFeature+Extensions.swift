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

extension AGSArcGISFeature {
    
    var asPopup: AGSPopup? {
        guard let featureTable = featureTable, featureTable.isPopupActuallyEnabled, let popupDefinition = featureTable.popupDefinition else {
            return nil
        }
        return AGSPopup(geoElement: self, popupDefinition: popupDefinition)
    }
    
    var asPopupManager: AGSPopupManager? {
        guard let popup = asPopup else {
            return nil
        }
        return AGSPopupManager(popup: popup)
    }
    
    var popupDefinition: AGSPopupDefinition? {
        return featureTable?.popupDefinition
    }
    
    var relatedRecordsInfos: [AGSRelationshipInfo]? {
        guard let table = featureTable as? AGSArcGISFeatureTable, let layerInfo = table.layerInfo else {
            return nil
        }
        return layerInfo.relationshipInfos.filter({ (info) -> Bool in info.cardinality == .oneToMany })
    }
    
    var relatedRecordsCount: Int {
        guard let infos = relatedRecordsInfos else {
            return 0
        }
        return infos.count
    }
    
    var objectID: Int64? {
        get {
            guard
                let featureTable = featureTable as? AGSArcGISFeatureTable,
                let oid = attributes[featureTable.objectIDField] as? Int64
                else {
                    return nil
            }
            
            return oid
        }
        set {
            guard let featureTable = featureTable as? AGSArcGISFeatureTable else {
                return
            }
            attributes[featureTable.objectIDField] = newValue
        }
    }
}

extension Collection where Iterator.Element == AGSArcGISFeature {
    
    var asPopups: [AGSPopup]? {
        
        var popups = [AGSPopup]()

        guard let first = first else {
            return popups
        }
        
        guard let firstFeatureTable = first.featureTable, firstFeatureTable.isPopupActuallyEnabled else {
            return nil
        }
        
        for feature in self {
            
            guard let featureTable = feature.featureTable, featureTable == firstFeatureTable else {
                print("[Error] all features must be of the same table")
                return nil
            }
            
            if let popup = feature.asPopup {
                popups.append(popup)
            }
        }

        return popups
    }
}

