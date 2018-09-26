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

extension AGSPopup {
    
    enum RecordType: String {
        /// A more descriptive popup record type, can be either `.record` or `.feature`
        case record, feature
        /// The fallback general record type
        case popup
    }
    
    /// Determine whether the popup represents a symbolizable feature or table record.
    var recordType: RecordType {
        
        guard let feature = geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            return .popup
        }
        
        return featureTable.featureLayer != nil ? .feature : .record
    }
}

