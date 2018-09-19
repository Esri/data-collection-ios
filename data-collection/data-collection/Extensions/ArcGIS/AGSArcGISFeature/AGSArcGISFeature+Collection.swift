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

extension Collection where Iterator.Element == AGSArcGISFeature {
    
    func asPopups() -> [AGSPopup]? {
        
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
            
            if let popup = feature.asPopup() {
                popups.append(popup)
            }
        }
        
        return popups
    }
}