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

/// Represents and manages the related records of a popup and one of its relationship infos.
///
/// This class is to not to be used directly but instead intended to be subclassed.
///
class Relationship: AGSLoadableBase {
    
    weak private(set) var popup: AGSPopup?
    weak private(set) var relationshipInfo: AGSRelationshipInfo?
    weak private(set) var relatedTable: AGSArcGISFeatureTable?
    
    init?(relationshipInfo info: AGSRelationshipInfo, table: AGSArcGISFeatureTable, popup: AGSPopup) {
        
        guard info.cardinality == .oneToMany else {
            return nil
        }
        
        self.relationshipInfo = info
        self.relatedTable = table
        self.popup = popup
    }
    
    var isStillValidRelationship: Bool {
        return popup != nil && relationshipInfo != nil && relatedTable != nil
    }
    
    var name: String? {
        return relatedTable?.tableName
    }
    
    var canAddRecord: Bool {
        return relatedTable?.canAddFeature ?? false
    }
    
    func createNewRecord() -> AGSPopup? {
        return relatedTable?.createPopup()
    }
    
    // MARK: AGSLoadableBase
    
    private var cancelableQuery: AGSCancelable?
    
    override func doStartLoading(_ retrying: Bool) {
        
        guard let feature = self.popup?.geoElement as? AGSArcGISFeature else {
            loadDidFinishWithError(FeatureTableError.invalidFeature)
            return
        }
        
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            loadDidFinishWithError(FeatureTableError.invalidFeatureTable)
            return
        }
        
        guard let info = self.relationshipInfo else {
            loadDidFinishWithError(FeatureTableError.missingRelationshipInfos)
            return
        }
        
        cancelableQuery = featureTable.queryRelatedFeaturesAsPopups(forFeature: feature, relationship: info) { [weak self] (popupsResults, error) in
            
            guard let self = self else { return }
            
            guard error == nil else {
                self.loadDidFinishWithError(error!)
                return
            }
            
            assert(popupsResults != nil, "Something went very wrong.")
            
            guard let popups = popupsResults else {
                self.loadDidFinishWithError(NSError.unknown)
                return
            }
            
            self.processRecords(popups)
            self.loadDidFinishWithError(nil)
        }
    }
    
    override func doCancelLoading() {
        
        // Cancel query.
        cancelableQuery?.cancel()
        
        // Pass user did cancel error.
        loadDidFinishWithError(NSError.userCancelled)
    }
    
    // MARK: For Subclassing Eyes
    
    /// Processes the records returned from the load process.
    ///
    /// Subclasses can override this method.
    ///
    /// - Note: Do not call this function directly.
    ///
    /// - Parameter popups: the collection of popups returned by the load process.
    func processRecords(_ popups: [AGSPopup]) { }
    
    /// Relate a new record record to the one managed.
    ///
    /// - Parameter editedRelatedPopup: the record to relate to the one managed.
    ///
    func editRelatedPopup(_ editedRelatedPopup: AGSPopup) { }
    
    /// Unrelate a record from the one managed.
    ///
    /// - Parameter removedRelatedPopup: the recored to remove from the managed popup.
    ///
    func removeRelatedPopup(_ removedRelatedPopup: AGSPopup) { }
    
}

extension Relationship {
    
    // MARK: Fetch and sort all related records for the many to one relationship.
    // This is intended to be used by `ManyToOneRelationship`.
    func queryAndSortAllRelatedPopups(_ completion: @escaping (Error?, [AGSPopup]?) -> Void) {
        
        guard let featureTable = relatedTable else {
            completion(NSError.unknown, nil)
            return
        }
        
        let sorted: AGSOrderBy?
        
        if let definition = featureTable.popupDefinition, let field = definition.fields.first {
            sorted = AGSOrderBy(fieldName: field.fieldName, sortOrder: .ascending)
        }
        else {
            sorted = nil
        }
        
        featureTable.queryAllFeaturesAsPopups(sorted: sorted) { (popups, error) in
            
            if let error = error {
                completion(error, nil)
                return
            }
            
            guard let popups = popups else {
                completion(NSError.unknown, nil)
                return
            }
            
            completion(nil, popups)
        }
    }
}
