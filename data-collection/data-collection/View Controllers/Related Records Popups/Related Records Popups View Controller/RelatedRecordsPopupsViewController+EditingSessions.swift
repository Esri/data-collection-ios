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

extension RelatedRecordsPopupsViewController {
    
    func editPopup(_ wantsEdit: Bool, completion: ((_ success: Bool) -> Void)? = nil) {
        
        if wantsEdit {
            
            guard !recordsManager.isEditing else {
                completion?(true)
                return
            }
            
            guard appContext.isLoggedIn else {
                present(loginAlertMessage: "You must login to make edit this \(recordsManager.popup.title ?? "record").")
                completion?(false)
                return
            }
            
            guard recordsManager.shouldAllowEdit, recordsManager.startEditing() else {
                present(simpleAlertMessage: "Unexpected error, you couldn't edit this \(recordsManager.popup.title ?? "record").")
                completion?(false)
                return
            }
            
            adjustViewControllerForEditState()
            completion?(true)
        }
        else {
            
            guard recordsManager.isEditing, let invalids = recordsManager.validatePopup() else {
                completion?(true)
                return
            }
            
            // 1. Check Validity
            guard invalids.count == 0 else {
                self.present(simpleAlertMessage: "You cannot save this \(recordsManager.title ?? "feature"). There \(invalids.count == 1 ? "is" : "are") \(invalids.count) invalid field\(invalids.count == 1 ? "" : "s").")
                completion?(false)
                return
            }
            
            // 2. Finish Editing
            recordsManager.finishEditing { [weak self] (error) in
                
                guard error == nil else {
                    print("[Error: Validating Feature]", error!.localizedDescription)
                    completion?(true)
                    return
                }
                guard
                    let feature = self?.popup.geoElement as? AGSArcGISFeature,
                    let featureTable = feature.featureTable as? AGSArcGISFeatureTable
                    else {
                        // somethign went very wrong
                        // TODO alert
                        completion?(true)
                        return
                }
                
                SVProgressHUD.show(withStatus: "Saving \(self?.recordsManager.title ?? "Record")...")
                
                // TODO make this into an extension
                if
                    let parentPopupManager = self?.parentPopupManager,
                    let parentFeature = parentPopupManager.popup.geoElement as? AGSArcGISFeature,
                    let relatedRecordInfos = parentFeature.relatedRecordsInfos,
                    let thisFeature = self?.popup.geoElement as? AGSArcGISFeature,
                    let thisFeatureTable = thisFeature.featureTable as? AGSArcGISFeatureTable
                {
                    
                    var foundRelationshipInfo: AGSRelationshipInfo?
                
                    for info in relatedRecordInfos {
                        if info.relatedTableID == thisFeatureTable.serviceLayerID {
                            foundRelationshipInfo = info
                            break
                        }
                    }
                    
                    if let relationshipInfo = foundRelationshipInfo, relationshipInfo.isOneToMany {
                        do {
                            //TODO make safe
                            try self?.parentPopupManager?.add(oneToMany: self!.popup, forRelationship: relationshipInfo)
                        }
                        catch {
                            SVProgressHUD.dismiss()
                            // TODO alert user
                            print("[Error: Records Manager]", error.localizedDescription)
                            return
                        }
                    }
                }
                
                featureTable.performEdit(feature: feature, completion: { [weak self] (error) in
                    
                    SVProgressHUD.dismiss()
                    if error != nil {
                        print("[Error] feature table edit error", error!.localizedDescription)
                    }
                    self?.adjustViewControllerForEditState()
                    completion?(true)
                })
            }
        }
    }
    
    func attemptToSavePopup(_ completion: @escaping (_ shouldProceed: Bool) -> Void) {
        
        guard recordsManager.isEditing else {
            completion(true)
            return
        }
        
        present(confirmationAlertMessage: "You must save first.", confirmationTitle: "Save", confirmationAction: { [weak self] (_) in
            self?.editPopup(false) { (success: Bool) in
                completion(success)
                return
            }
        })
    }
    
    func closeEditingSessionAndDelete(childPopup: AGSPopup, forRelationshipInfo relationshipInfo: AGSRelationshipInfo) {
        
        let deletePopup: (AGSPopup, AGSRelationshipInfo) -> Void = { [weak self] childPopup, relationshipInfo in
            
            guard let manager = self?.recordsManager else {
                self?.present(simpleAlertMessage: "Could not delete \(childPopup.tableName ?? "related record.")")
                return
            }
            
            SVProgressHUD.show(withStatus: "Deleting \(childPopup.tableName ?? "related record.")")
            
            do {
                try manager.delete(oneToMany: childPopup, forRelationship: relationshipInfo)
            }
            catch {
                print("[Error] deleting one to many child popup", error.localizedDescription)
                SVProgressHUD.dismiss()
                self?.present(simpleAlertMessage: "Could not delete \(childPopup.tableName ?? "related record.")")
                return
            }
            
            guard let feature = childPopup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
                SVProgressHUD.dismiss()
                self?.present(simpleAlertMessage: "Could not delete \(childPopup.tableName ?? "related record.")")
                return
            }
            
            featureTable.performDelete(feature: feature) { error in
                
                defer {
                    self?.tableView.reloadData()
                    SVProgressHUD.dismiss()
                }
                
                guard error == nil else {
                    print("[Error] deleting one to many child popup", error!.localizedDescription)
                    SVProgressHUD.dismiss()
                    self?.present(simpleAlertMessage: "Could not delete \(childPopup.tableName ?? "related record.")")
                    return
                }
            }
        }
        
        if recordsManager.isEditing {
            
            // save first
            attemptToSavePopup { [weak self] (shouldProceed: Bool) in
                
                guard shouldProceed else {
                    self?.present(simpleAlertMessage: "Could not edit this record.")
                    return
                }
                
                deletePopup(childPopup, relationshipInfo)
            }
        }
        else {
            deletePopup(childPopup, relationshipInfo)
        }
    }
    
    func closeEditingSessionAndBeginEditing(childPopup: AGSPopup) {
        
        let beginEditing: (AGSPopup) -> Void = { [weak self] childPopup in
            
            guard let rrvc = self?.storyboard?.instantiateViewController(withIdentifier: "RelatedRecordsPopupsViewController") as? RelatedRecordsPopupsViewController, let parentRecordsManager = self?.recordsManager else {
                // TODO inform user
                return
            }
            
            rrvc.popup = childPopup
            rrvc.parentPopupManager = parentRecordsManager
            rrvc.editPopup(true)
            
            self?.navigationController?.pushViewController(rrvc, animated: true)
        }
        
        if recordsManager.isEditing {
            
            // save first
            attemptToSavePopup { [weak self] (shouldProceed: Bool) in
                
                guard shouldProceed else {
                    self?.present(simpleAlertMessage: "Could not edit this record.")
                    return
                }
                
                beginEditing(childPopup)
            }
        }
        else {
            beginEditing(childPopup)
        }
    }
}
