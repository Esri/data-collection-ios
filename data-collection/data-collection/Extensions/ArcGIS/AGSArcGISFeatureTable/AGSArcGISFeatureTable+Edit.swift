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

extension AGSArcGISFeatureTable {
    
    func performEdit(feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        // Update
        if canUpdate(feature) {
            performEdit(type: .update, forFeature: feature, completion: completion)
        }
            // Add
        else if canAddFeature {
            performEdit(type: .add, forFeature: feature, completion: completion)
        }
        else {
            completion(FeatureTableError.cannotEditFeature)
        }
    }
    
    func performDelete(feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        if canDelete(feature) {
            performEdit(type: .delete, forFeature: feature, completion: completion)
        }
        else {
            completion(FeatureTableError.cannotEditFeature)
        }
    }
    
    private func performEdit(type: EditType, forFeature feature: AGSArcGISFeature, completion: @escaping (Error?)->Void) {
        
        let editClosure:(Error?) -> Void = { error in
            
            guard error == nil else {
                print("[Error: Feature Service Table] could not edit", error!.localizedDescription)
                completion(error!)
                return
            }
            
            let updateObjectID: () -> Void = {
                if type != .delete {
                    feature.refreshObjectID()
                }
                else {
                    feature.objectID = nil
                }
            }
            
            // If online, apply edits.
            guard let serviceFeatureTable = self as? AGSServiceFeatureTable else {
                updateObjectID()
                completion(nil)
                return
            }
            
            serviceFeatureTable.applyEdits(completion: { (results, error) in
                
                guard error == nil else {
                    print("[Error: Feature Service Table] could not apply edits", error!.localizedDescription)
                    updateObjectID()
                    completion(error!)
                    return
                }
                
                updateObjectID()
                completion(nil)
            })
        }
        
        switch type {
        case .update: update(feature, completion: editClosure)
        case .delete: delete(feature, completion: editClosure)
        case .add: add(feature, completion: editClosure)
        }
    }
}
