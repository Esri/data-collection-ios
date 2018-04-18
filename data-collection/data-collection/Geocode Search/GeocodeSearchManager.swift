//// Copyright 2017 Esri
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

// TODO improve
class ReverseGeocoderManager: AGSLoadableBase {
    
    struct Keys {
        static let address = "Address"
        static let matchAddress = "Match_addr"
    }
    
    private var onlineLocatorTask: AGSLocatorTask = {
        assert(AppConfiguration.geocodeServiceURL != nil, "App Configuration must contain a valid geocode service url.")
        return AGSLocatorTask(url: AppConfiguration.geocodeServiceURL!)
    }()
    
    private var offlineLocatorTask: AGSLocatorTask = {
        return AGSLocatorTask(name: "AddressLocator")
    }()
    
    override func doCancelLoading() {
        loadDidFinishWithError(NSUserCancelledError as? Error)
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        let dispatchGroup = DispatchGroup()
        var loadError: Error? = nil
        
        dispatchGroup.enter(n: 2)
        
        onlineLocatorTask.load { (error) in
            if error != nil {
                print("[Error] Online Locator Task error", error!.localizedDescription)
                loadError = error
                return
            }
            dispatchGroup.leave()
        }
        
        offlineLocatorTask.load { (error) in
            if error != nil {
                print("[Error] Offline Locator Task error", error!.localizedDescription)
                loadError = error
                return
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) { [weak self] in
            self?.loadDidFinishWithError(loadError)
        }
    }
    
    internal func reverseGeocode(forPoint point: AGSPoint, completion: @escaping (String?)->Void) {
        
        guard loadStatus == .loaded else {
            completion(nil)
            return
        }
        
        var locatorTask: AGSLocatorTask?
        
        if appContext.workMode == .online && appReachability.isReachable {
            locatorTask = onlineLocatorTask
        }
        else {
            locatorTask = offlineLocatorTask
        }
        
        locatorTask!.reverseGeocode(withLocation: point) { (geoCodeResults: [AGSGeocodeResult]?, error: Error?) in
            guard error == nil else {
                print("[Error] reverse geocoder error", error!.localizedDescription)
                completion(nil)
                return
            }
            guard let results = geoCodeResults,
                let first = results.first,
                let attributesDict = first.attributes,
                let address = attributesDict[Keys.address] as? String ?? attributesDict[Keys.matchAddress] as? String
                else {
                    completion(nil)
                    return
            }
            completion(address)
        }
    }
}
