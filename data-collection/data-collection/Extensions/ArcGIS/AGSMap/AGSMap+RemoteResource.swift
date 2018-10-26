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

import ArcGIS

extension AGSMap {
    
    /// Clears remote resources contained in a map, considering feature layers, feature tables and the basemap.
    
    func clearRemoteResourcesCachedCredentials() {
        
        // clear all tables
        tables.forEach { ($0 as? AGSRemoteResource)?.credential = nil }
        
        // clear all layers, and basemap layers
        [operationalLayers, basemap.baseLayers, basemap.referenceLayers].forEach { (candidate) in
            
            // if the layer itself is a remote resource, clear the credential
            candidate.forEach {
                ($0 as? AGSRemoteResource)?.credential = nil
                (($0 as? AGSFeatureLayer)?.featureTable as? AGSRemoteResource)?.credential = nil
            }
        }
    }
}
