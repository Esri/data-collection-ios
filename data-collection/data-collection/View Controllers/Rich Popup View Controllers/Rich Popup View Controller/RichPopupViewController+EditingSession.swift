//// Copyright 2019 Esri
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

import ArcGIS

extension RichPopupViewController {
        
    // MARK: Finish Session
    
    func finishEditingSession(_ completion: ((_ error: Error?) -> Void)? = nil) {
        
        // 1. Finish editing pop-up.
        finishEditingPopup { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                completion?(error)
                return
            }
            
            // 2. Persist edits to table
            self.persistEditsToTable { (error) in
                completion?(error)
            }
        }
    }
    
    private func finishEditingPopup(_ completion: @escaping (_ error: Error?) -> Void) {
        
        // Popup manager must not be in an editing session already.
        guard self.popupManager.isEditing else {
            completion(NSError.invalidOperation)
            return
        }
        
        // Ensure the popup validates.
        let invalids = self.popupManager.validatePopup()
        
        // Before saving, check that the pop-up and related records are valid.
        guard invalids.isEmpty else {
            completion(RichPopupManagerError.invalidPopup(invalids))
            return
        }
        
        // Finally, finish editing the pop-up.
        self.popupManager.finishEditing { (error) in
            completion(error)
        }
    }
    
    private func persistEditsToTable(_ completion: @escaping (_ error: Error?) -> Void) {
        
        guard let feature = self.popupManager.popup.geoElement as? AGSArcGISFeature else {
            completion(FeatureTableError.invalidFeature)
            return
        }
        
        guard let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
            completion(FeatureTableError.invalidFeatureTable)
            return
        }
        
        featureTable.performEdit(feature: feature, completion: { [weak self] (error) in
            
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            // An extra check is performed for the sake of the _Trees of Portland_ web map story.
            // This line can be removed without any consequence.
            self.popupManager.conditionallyPerformCustomBehavior { completion(nil) }
        })
    }
}
