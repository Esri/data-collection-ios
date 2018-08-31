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

class ReverseGeocoderManager: AGSLoadableBase {
    
    struct Keys {
        static let address = "Address"
        static let matchAddress = "Match_addr"
    }
    
    private let onlineLocatorTask = AGSLocatorTask(url: AppConfiguration.geocodeServiceURL)
    
    private let offlineLocatorTask = AGSLocatorTask(name: "AddressLocator")
    
//    private let onlineLocatorTask: AGSLocatorTask = {
//        let locator: AGSLocatorTask! = AGSLocatorTask(url: AppConfiguration.geocodeServiceURL)
//        guard locator != nil  else {
//            fatalError("App must be configured with valid world geocoder service URL.")
//        }
//        return locator
//    }()
//
//    private let offlineLocatorTask: AGSLocatorTask = {
//        let offlineLocatorName = "AddressLocator"
//        let locator: AGSLocatorTask! = AGSLocatorTask(name: offlineLocatorName)
//        guard locator != nil  else {
//            fatalError("App must be configured with offline locator named \(offlineLocatorName).")
//        }
//        return locator
//    }()
    
    override func doCancelLoading() {
        
        onlineLocatorTask.cancelLoad()
        offlineLocatorTask.cancelLoad()
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        let dispatchGroup = DispatchGroup()
        var loadError: Error? = nil
        
        dispatchGroup.enter(n: 2)
        
        onlineLocatorTask.load { (error) in
            if error != nil {
                print("[Error] Online Locator Task error", error!.localizedDescription)
                loadError = error
            }
            dispatchGroup.leave()
        }
        
        offlineLocatorTask.load { (error) in
            if error != nil {
                print("[Error] Offline Locator Task error", error!.localizedDescription)
                loadError = error
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) { [weak self] in
            self?.loadDidFinishWithError(loadError)
        }
    }
    
    internal func reverseGeocode(forPoint point: AGSPoint, completion: @escaping (String?, Error?)->Void) {
        
        load { [weak self] error in

            guard let strongSelf = self else { return }

            guard error == nil else {
                completion(nil, error)
                return
            }
            
            let locatorTask: AGSLocatorTask
            
            if appContext.workMode == .online && appReachability.isReachable {
                locatorTask = strongSelf.onlineLocatorTask
            }
            else {
                locatorTask = strongSelf.offlineLocatorTask
            }
            
            let params = AGSReverseGeocodeParameters()
            params.forStorage = true
            
            locatorTask.reverseGeocode(withLocation: point, parameters: params) { (geoCodeResults: [AGSGeocodeResult]?, error: Error?) in
                
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                guard let results = geoCodeResults,
                    let first = results.first,
                    let attributesDict = first.attributes,
                    let address = attributesDict[Keys.address] as? String ?? attributesDict[Keys.matchAddress] as? String
                    else {
                        completion(nil, AppGeocoderError.missingAddressAttribute)
                        return
                }
                completion(address, nil)
            }
        }
    }
}
