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

/// Represents and manages a many-to-one related records of a popup.
class ManyToOneRelationship: Relationship {
    
    /// The staged related pop-up or the current related pop-up if a change has not been staged.
    var relatedPopup: AGSPopup? {
        get {
            return stagedRelatedPopup ?? currentRelatedPopup
        }
        set {
            stagedRelatedPopup = newValue
        }
    }
    
    /// The popup that is currently persisted.
    private var currentRelatedPopup: AGSPopup?
    
    /// The popup that could be persisted, if `commitChange()` is called.
    private var stagedRelatedPopup: AGSPopup?
    
    // Overrides the superclass method, stores a references to the record.
    override func processRecords(_ popups: [AGSPopup]) {
        
        currentRelatedPopup = popups.first
    }
    
    /// Call this method to cancel the editing session.
    func cancelChange() {
        
        stagedRelatedPopup = nil
    }
    
    /// Call this method to commit the editing session.
    func commitChange() {
        
        // Replace the current related pop-up with the staged related pop-up.
        if let newRelatedPopup = stagedRelatedPopup {
            
            // No need for the staged popup, remove it.
            stagedRelatedPopup = nil
            
            // Set the current related popup to the newly selected related popup.
            currentRelatedPopup = newRelatedPopup
        }
    }
}
