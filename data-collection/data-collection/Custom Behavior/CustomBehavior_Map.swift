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

/// Quickly determines if the app is configured to consume the _Trees of Portland_ web map,
/// and thus should perform custom behaviors required of that web map.
var shouldEnactCustomBehavior: Bool {
    
    // The Trees of Portland item ID.
    // See: https://www.arcgis.com/home/item.html?id=fcc7fc65bb96464c9c0986576c119a92
    let treesOfPortlandWebmapItemID = "fcc7fc65bb96464c9c0986576c119a92"
    
    // The current map's item will be an `AGSPortalItem` if the current map is a portal web map.
    if let portalItem = appContext.currentMap?.item as? AGSPortalItem {
        return portalItem.itemID == treesOfPortlandWebmapItemID
    }
    // The current map's item will be an `AGSLocalItem` if the current map is an offline map.
    else if let localItem = appContext.currentMap?.item as? AGSLocalItem {
        return localItem.originalPortalItemID == treesOfPortlandWebmapItemID
    }
    else {
        return false
    }
}
