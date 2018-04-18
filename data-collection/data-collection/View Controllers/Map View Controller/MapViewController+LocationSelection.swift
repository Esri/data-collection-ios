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

enum LocationSelectionViewType {
    
    case newFeature
    case offlineExtent
    
    var headerText: String {
        switch self {
        case .newFeature:
            return "Choose the location"
        case .offlineExtent:
            return "Select the region of the map to take offline"
        }
    }
    
    var subheaderText: String {
        switch self {
        case .newFeature:
            return "Pan and zoom map under pin"
        case .offlineExtent:
            return "Pan and zoom map within the rectangle"
        }
    }
}

extension MapViewController {
    
    func userRequestsAddNewFeature() {
        
        // 1 User must be logged in, prompt if not.
        guard appContext.isLoggedIn else {
            present(loginAlertMessage: "You must log in to add a Tree.")
            return
        }
        
        mapViewMode = .selectingFeature
    }
    
    @IBAction func userDidSelectLocation(_ sender: Any) {
        
        switch locationSelectionType {
        case .newFeature:
            break
        case .offlineExtent:
            prepareForOfflineMapDownloadJob()
            break
        }
        
        mapViewMode = .`default`
    }
    
    @IBAction func userDidCancelSelectLocation(_ sender: Any) {
        
        switch locationSelectionType {
        case .newFeature:
            break
        case .offlineExtent:
            hideMapMaskViewForOfflineDownloadArea()
            break
        }
        
        mapViewMode = .`default`
    }
    
    func adjustForLocationSelectionType() {
        
        selectViewHeaderLabel.text = locationSelectionType.headerText
        selectViewSubheaderLabel.text = locationSelectionType.subheaderText
    }
}
