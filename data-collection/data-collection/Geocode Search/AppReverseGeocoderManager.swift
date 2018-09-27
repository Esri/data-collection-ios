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

enum ReverseGeocoderManagerError: Int, AppError {
    
    var baseCode: AppErrorBaseCode { return .GeocoderResultsError }

    case missingAddressAttribute = 1
    
    var errorCode: Int {
        return baseCode.rawValue + self.rawValue
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .missingAddressAttribute:
            return [NSLocalizedDescriptionKey: "Missing Address (for online locator) or Match_addr (for offline locator) in attributes."]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}

/// This class facilitates reverse geocoding, contingent on app work mode and reachability.
class AppReverseGeocoderManager: AGSLoadableBase {
    
    struct Keys {
        static let address = "Address"
        static let matchAddress = "Match_addr"
    }
    
    // Online locator using the world geocoder service.
    private let onlineLocatorTask = AGSLocatorTask(url: AppConfiguration.geocodeServiceURL)
    
    // Offline locator using the side loaded 'AddressLocator'.
    private let offlineLocatorTask = AGSLocatorTask(name: "AddressLocator")
    
    func removeCredentialsFromServices() {
        onlineLocatorTask.credential = nil
        offlineLocatorTask.credential = nil
    }
    
    override func doCancelLoading() {
        
        onlineLocatorTask.cancelLoad()
        offlineLocatorTask.cancelLoad()
    }
    
    override func doStartLoading(_ retrying: Bool) {
        
        let dispatchGroup = DispatchGroup()
        var loadError: Error? = nil
        
        dispatchGroup.enter(n: 2)
        
        // Load online locator.
        onlineLocatorTask.load { (error) in
            if error != nil {
                print("[Error] Online Locator Task error", error!.localizedDescription)
                loadError = error
            }
            dispatchGroup.leave()
        }
        
        // Load offline locator.
        offlineLocatorTask.load { (error) in
            if error != nil {
                print("[Error] Offline Locator Task error", error!.localizedDescription)
                loadError = error
            }
            dispatchGroup.leave()
        }
        
        // Finish loading with an error, if there is one.
        dispatchGroup.notify(queue: OperationQueue.current?.underlyingQueue ?? .main) { [weak self] in
            self?.loadDidFinishWithError(loadError)
        }
    }
    
    /// Reverse geocode an address from a map point.
    ///
    /// - Parameters:
    ///   - point: The point used in the reverse geocode operation.
    ///   - completion: A closure containing either an address or an error (but not both).
    ///
    internal func reverseGeocode(forPoint point: AGSPoint, completion: @escaping (String?, Error?)->Void) {
        
        load { [weak self] error in

            guard let strongSelf = self else { return }

            guard error == nil else {
                completion(nil, error)
                return
            }
            
            let locatorTask: AGSLocatorTask
            
            // We want to use the online locator if the work mode is online and the app has reachability.
            if appContext.workMode == .online && appReachability.isReachable {
                locatorTask = strongSelf.onlineLocatorTask
            }
            // Otherwise, we'll use the offline locator.
            else {
                locatorTask = strongSelf.offlineLocatorTask
            }
            
            // We need to set the geocode parameters for storage true because the results of this reverse geocode is persisted to a table.
            // Please familiarize yourself with the implications of this credits-consuming operation:
            // https://developers.arcgis.com/rest/geocode/api-reference/geocoding-free-vs-paid.htm
            let params = AGSReverseGeocodeParameters()
            params.forStorage = true
            
            // Perform the reverse geocode task.
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
                        completion(nil, ReverseGeocoderManagerError.missingAddressAttribute)
                        return
                }
                completion(address, nil)
            }
        }
    }
}
