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

class RelatedRecordsTableManager: AGSLoadableBase {
    
    internal private(set) var featureTable: AGSArcGISFeatureTable
    
    private var query: AGSCancelable?
    
    var popups = [AGSPopup]()

    init(featureTable table: AGSArcGISFeatureTable) {
        self.featureTable = table
    }
    
    override func doCancelLoading() {
        query?.cancel()
        popups.removeAll()
        loadDidFinishWithError(AppLoadableError.canceledLoad)
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        popups.removeAll()
        
        var sorted: AGSOrderBy?
        
        if let definition = featureTable.popupDefinition, let field = definition.fields.first {
            sorted = AGSOrderBy(fieldName: field.fieldName, sortOrder: .ascending)
        }
        
        query = featureTable.queryAllFeaturesAsPopups(sorted: sorted) { [weak self] (popups, error) in
            
            guard error == nil else {
                self?.loadDidFinishWithError(error!)
                return
            }
            
            guard let popups = popups else {
                self?.loadDidFinishWithError(FeatureTableError.queryResultsMissingPopups)
                return
            }
            
            self?.popups = popups
            self?.loadDidFinishWithError(nil)
        }
    }
}
