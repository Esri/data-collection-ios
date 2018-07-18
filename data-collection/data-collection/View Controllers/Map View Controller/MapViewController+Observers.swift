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

extension MapViewController {
    
    func setupObservers() {
        beginObservingLocationAuthStatus()
        beginObservingCurrentMap()
    }
    
    private func beginObservingLocationAuthStatus() {
        observeLocationAuthorization = appLocation.observe(\.locationAuthorized, options:[.new, .old]) { [weak self] (appLocation, _) in
            print("[Location Authorization] is authorized: \(appLocation.locationAuthorized)")
            self?.adjustForLocationAuthorizationStatus()
        }
    }
    
    private func beginObservingCurrentMap() {
        observeCurrentMap = appContext.observe(\.currentMap, options:[.new, .old]) { [weak self] (appContext, _) in
            self?.mapView.map = appContext.currentMap
            self?.updateForMap()
        }
    }
    
    func invalidateAndReleaseObservations() {
        
        // Invalidate and release KVO observations
        observeLocationAuthorization?.invalidate()
        observeLocationAuthorization = nil
        
        observeCurrentMap?.invalidate()
        observeCurrentMap = nil
    }
}
