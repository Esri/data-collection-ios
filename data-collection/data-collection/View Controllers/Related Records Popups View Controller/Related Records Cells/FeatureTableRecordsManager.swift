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

class FeatureTableRecordsManager: AGSLoadableBase {
    
    weak var featureTable: AGSArcGISFeatureTable?
    
    var popups = [AGSPopup]()

    init(featureTable table: AGSArcGISFeatureTable) {
        self.featureTable = table
    }
    
    override func doCancelLoading() {
        loadDidFinishWithError(NSUserCancelledError as? Error)
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        popups.removeAll()
        
        guard let featureTable = self.featureTable else {
            loadDidFinishWithError(FeatureTableError.missingFeatureTable)
            return
        }
        
        featureTable.queryAllFeaturesAsPopups { [weak self] (popups, error) in
            
            guard error == nil else {
                self?.loadDidFinishWithError(error!)
                return
            }
            
            guard let popups = popups else {
                self?.loadDidFinishWithError(FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            self?.popups = popups/*.sorted(by: { (a, b) -> Bool in
                guard
                let featureA = a.geoElement as? AGSArcGISFeature,
                let featureB = b.geoElement as? AGSArcGISFeature,
                featureA.attributes.count > 0,
                featureB.attributes.count > 0,
                let comparableA = featureA.attributes[0] as? Equatable,
                let comparableB = featureB.attributes[0] as? Equatable
                    else {
                        return true
                }
                return comparableA < comparableB
            })*/
            
            self?.loadDidFinishWithError(nil)
        }
    }
}
