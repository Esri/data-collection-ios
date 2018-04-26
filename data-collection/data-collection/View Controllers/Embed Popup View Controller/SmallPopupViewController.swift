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

class SmallPopupViewController: UIViewController {
    
    @IBOutlet weak var relatedRecordHeaderLabel: UILabel!
    @IBOutlet weak var relatedRecordSubheaderLabel: UILabel!
    @IBOutlet weak var relatedRecordsNLabel: UILabel!
    
    var popup: AGSPopup? {
        didSet {
            popupManager = popup != nil ? AGSPopupManager(popup: popup!) : nil
        }
    }
    
    private var popupManager: AGSPopupManager? {
        didSet {
            popuplateViewWithBestContent()
        }
    }
    
    /**
     The small popup view controller (spvc) is concerned primarly with displaying content to do with related records.
     Specifically, the spvc is concerned with two related record types.
     1) The (left) side of the spvc concerns itself with displaying content from the highest order related table where the relationship is one to many and the feature of interest is the destination
     2) The (right) side of the spvc concerns itself with displaying content from the highest order related table where the relationship is one to many and the feature of interest is the origin
     Should the feature of interest not contain tables with this specific related table relationships, the spvc populates itself with content derived from itself's feature of interest
     */
    
    func popuplateViewWithBestContent() {
        
        guard
            let popupManager = popupManager,
            let feature = popupManager.popup.geoElement as? AGSArcGISFeature,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable
            else {
                clearLabels()
                return
        }
        
        var oneToManyDestination: AGSRelationshipInfo?
        var oneToManyOrigin: AGSRelationshipInfo?
        
        let queryCompletion: ([AGSRelatedFeatureQueryResult]?, Error?) -> Void = { [weak self] (results, error) in
            
            guard error == nil else {
                self?.clearLabels()
                print("[Error] querying for related records", error!.localizedDescription)
                return
            }
            
            guard let results = results else {
                self?.clearLabels()
                print("[Error] querying for related records, results are nil")
                return
            }
            
            var destinationPopupManager: AGSPopupManager?
            var originPopupManagers: [AGSPopupManager]?
            
            for result in results {
                
                if let destination = oneToManyDestination, let info = result.relationshipInfo, destination.name == info.name {
                    destinationPopupManager = result.firstFeatureAsPopupManager
                    continue
                }
                
                if let origin = oneToManyOrigin, let info = result.relationshipInfo, origin.name == info.name {
                    originPopupManagers = result.featuresAsPopupManagers
                    continue
                }
            }
            
            var popupIndex = 0
            
            if let destination = destinationPopupManager {
                
                var destinationIndex = 0
                self?.relatedRecordHeaderLabel.text = destination.nextFieldStringValue(idx: &destinationIndex) ?? popupManager.nextFieldStringValue(idx: &popupIndex)
                self?.relatedRecordSubheaderLabel.text = destination.nextFieldStringValue(idx: &destinationIndex) ?? popupManager.nextFieldStringValue(idx: &popupIndex)
            }
            else {
                self?.relatedRecordHeaderLabel.text = popupManager.nextFieldStringValue(idx: &popupIndex)
                self?.relatedRecordSubheaderLabel.text = popupManager.nextFieldStringValue(idx: &popupIndex)
            }
            
            if let origin = originPopupManagers {
                
                let n = origin.count
                let name = origin.first?.tableName ?? "Records"
                self?.relatedRecordsNLabel.text = "\(n) \(name)"
            }
            else {
                self?.relatedRecordsNLabel.text = popupManager.nextFieldStringValue(idx: &popupIndex)
            }
        }
        
        guard let relationshipInfos = featureTable.layerInfo?.relationshipInfos else {
            queryCompletion([AGSRelatedFeatureQueryResult](), nil)
            return
        }
        
        // TODO Solve the ordering of tables
//        let sortedRelationshipInfos = relationshipInfos.sorted { (a, b) -> Bool in
//            return a.relatedTableID < b.relatedTableID
//        }
        
        // TODO check on popup information.
        for info in relationshipInfos {
            
            // Find top most table relationship where item of interest is one of many
            if info.cardinality == .oneToMany, info.role == .destination, oneToManyDestination == nil {
                oneToManyDestination = info
                continue
            }
                
                // Find top most table relationship where item of interest contains a collection
            else if info.cardinality == .oneToMany, info.role == .origin, oneToManyOrigin == nil {
                oneToManyOrigin = info
                continue
            }
            
            // escape early if we've found both top most tables
            if oneToManyDestination != nil && oneToManyOrigin != nil {
                break
            }
        }
        
        var relationships = [AGSRelationshipInfo]()
        
        if let destinationRelationship = oneToManyDestination {
            relationships.append(destinationRelationship)
        }
        
        if let originRelationship = oneToManyOrigin {
            relationships.append(originRelationship)
        }
        
        // Online Table
        if let serviceFeatureTable = featureTable as? AGSServiceFeatureTable {
            serviceFeatureTable.queryRelatedFeatures(for: feature, withRelationships: relationships, queryFeatureFields: .loadAll, completion: queryCompletion)
        }
            // Offline Table :: TODO Check
        else if let geodatabaseFeatureTable = featureTable as? AGSGeodatabaseFeatureTable {
            geodatabaseFeatureTable.queryRelatedFeatures(for: feature, completion: queryCompletion)
        }
            // Unknown
        else {
            clearLabels()
        }
    }
    
    private func clearLabels() {
        relatedRecordHeaderLabel.text = nil
        relatedRecordSubheaderLabel.text = nil
        relatedRecordsNLabel.text = nil
    }
}
