////// Copyright 2018 Esri
////
//// Licensed under the Apache License, Version 2.0 (the "License");
//// you may not use this file except in compliance with the License.
//// You may obtain a copy of the License at
////
////   http://www.apache.org/licenses/LICENSE-2.0
////
//// Unless required by applicable law or agreed to in writing, software
//// distributed under the License is distributed on an "AS IS" BASIS,
//// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//// See the License for the specific language governing permissions and
//// limitations under the License.
//
import Foundation
import ArcGIS

extension RichPopupManager {
    
    func conditionallyPerformCustomBehavior(_ completion: @escaping () -> Void) {
        
        if shouldEnactCustomBehavior {
            
            if tableName == "Trees" {
                updateSymbology(withTreePopup: richPopup, completion: completion)
            }
            else if let parent = parentOneToManyManagersCurrentlyMaintained().first(where: { (manager) in
                manager.tableName == "Trees"
            }) {
                updateSymbology(withTreePopup: parent.richPopup, completion: completion)
            }
            else {
                completion()
            }
        }
        else {
            completion()
        }
    }
}
