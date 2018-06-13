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
import UIKit
import ArcGIS

class SmallPopupViewController: AppContextAwareController {
    
    @IBOutlet weak var relatedRecordHeaderLabel: UILabel!
    @IBOutlet weak var relatedRecordSubheaderLabel: UILabel!
    @IBOutlet weak var relatedRecordsNLabel: UILabel!
    
    var popup: AGSPopup? {
        didSet {
            popupManager = popup != nil ? AGSPopupManager(popup: popup!) : nil
        }
    }
    
    private var popupManager: AGSPopupManager?
    
    /**
     The small popup view controller (spvc) is concerned primarly with displaying content to do with related records.
     Specifically, the spvc is concerned with two related record types.
     1) The (left) side of the spvc concerns itself with displaying content from the highest order related table where the relationship is one to many and the feature of interest is the destination
     2) The (right) side of the spvc concerns itself with displaying content from the highest order related table where the relationship is one to many and the feature of interest is the origin
     Should the feature of interest not contain tables with this specific related table relationships, the spvc populates itself with content derived from itself's feature of interest
     */
    
    
    // TODO
    /*
     The queryCompletion declaration is long and distracts from the rest of the logic of populateViewWithBestContent.
     
     I bet that pulling that into a separate function that returns a tuple of (manyToOneRelationship, oneToManyRelantionship,queryCompletion) would work nicely.
    */
    func popuplateViewWithBestContent(_ complete: @escaping ()->Void ) {
        
        guard
            let popupManager = popupManager,
            let feature = popupManager.popup.geoElement as? AGSArcGISFeature,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable
            else {
                clearLabels()
                complete()
                return
        }
        
        var manyToOneRelationship: AGSRelationshipInfo?
        var oneToManyRelationship: AGSRelationshipInfo?
        
        let queryCompletion: ([AGSRelatedFeatureQueryResult]?, Error?) -> Void = { [weak self] (results, error) in
            
            guard error == nil else {
                self?.clearLabels()
                print("[Error] querying for related records", error!.localizedDescription)
                complete()
                return
            }
            
            guard let results = results else {
                self?.clearLabels()
                print("[Error] querying for related records, results are nil")
                complete()
                return
            }
            
            var manyToOneManager: AGSPopupManager?
            var oneToManyManagers: [AGSPopupManager]?
            
            for result in results {
                
                if let manyToOne = manyToOneRelationship, let info = result.relationshipInfo, manyToOne.name == info.name {
                    manyToOneManager = result.firstFeatureAsPopupManager
                    continue
                }
                
                if let oneToMany = oneToManyRelationship, let info = result.relationshipInfo, oneToMany.name == info.name {
                    oneToManyManagers = result.featuresAsPopupManagers
                    continue
                }
            }
            
            var popupIndex = 0
            
            if let manyToOne = manyToOneManager {
                
                var destinationIndex = 0
                self?.relatedRecordHeaderLabel.text = manyToOne.nextFieldStringValue(idx: &destinationIndex) ?? popupManager.nextFieldStringValue(idx: &popupIndex)
                self?.relatedRecordSubheaderLabel.text = manyToOne.nextFieldStringValue(idx: &destinationIndex) ?? popupManager.nextFieldStringValue(idx: &popupIndex)
            }
            else {
                self?.relatedRecordHeaderLabel.text = popupManager.nextFieldStringValue(idx: &popupIndex)
                self?.relatedRecordSubheaderLabel.text = popupManager.nextFieldStringValue(idx: &popupIndex)
            }
            
            if let oneToMany = oneToManyManagers {
                
                let n = oneToMany.count
                let name = oneToMany.first?.tableName ?? "Records"
                self?.relatedRecordsNLabel.text = "\(n) \(name)"
            }
            else {
                self?.relatedRecordsNLabel.text = popupManager.nextFieldStringValue(idx: &popupIndex)
            }
            
            complete()
        }
        
        guard let relationshipInfos = featureTable.layerInfo?.relationshipInfos else {
            queryCompletion([AGSRelatedFeatureQueryResult](), nil)
            return
        }
        
        // TODO Solve the ordering of tables
        let sortedRelationshipInfos = relationshipInfos.sorted { (a, b) -> Bool in
            return a.relatedTableID < b.relatedTableID
        }

        for info in sortedRelationshipInfos {
            
            // Find top most table relationship where item of interest is one of many
            if manyToOneRelationship == nil, info.isManyToOne, featureTable.isPopupEnabledFor(relationshipInfo: info) {
                manyToOneRelationship = info
                continue
            }
                
            // Find top most table relationship where item of interest contains a collection
            else if oneToManyRelationship == nil, info.isOneToMany, featureTable.isPopupEnabledFor(relationshipInfo: info) {
                oneToManyRelationship = info
                continue
            }
            
            // escape early if we've found both top most tables
            if manyToOneRelationship != nil && oneToManyRelationship != nil {
                break
            }
        }
        
        var relationships = [AGSRelationshipInfo]()
        
        if let manyToOne = manyToOneRelationship {
            relationships.append(manyToOne)
        }
        
        if let oneToMany = oneToManyRelationship {
            relationships.append(oneToMany)
        }
        
        featureTable.queryRelatedFeatures(forFeature: feature, relationships: relationships, completion: queryCompletion)
    }
    
    private func clearLabels() {
        relatedRecordHeaderLabel.text = nil
        relatedRecordSubheaderLabel.text = nil
        relatedRecordsNLabel.text = nil
    }
}
