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
}
