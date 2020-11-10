// Copyright 2017 Esri
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

/// This class facilitates reverse geocoding, contingent on app work mode.
class AddressLocator {
    
    // Online locator using the world geocoder service.
    private lazy var onlineLocator = AGSLocatorTask(url: OnlineGeocoderConfig.url)
    
    // Offline locator using the side loaded 'AddressLocator'.
    private lazy var offlineLocator = AGSLocatorTask(name: OfflineGeocoderConfig.name)
    
    init(default workMode: AppContext.WorkMode) {
        prepareLocator(for: workMode)
    }
    
    func prepareLocator(for workMode: AppContext.WorkMode) {
        switch workMode {
        case .offline:
            offlineLocator.load(completion: nil)
            currentLocator = offlineLocator
        case .online:
            onlineLocator.load(completion: nil)
            currentLocator = onlineLocator
        case .none:
            currentLocator = nil
        }
    }
    
    private var currentLocator: AGSLocatorTask?
    
    // MARK: Errors
    
    struct NoLocatorError: LocalizedError {
        let localizedDescription = "No locator."
    }
    
    struct NoResultsError: LocalizedError {
        let localizedDescription = "Operation yeilded no results."
    }
    
    struct MissingAttribute: LocalizedError {
        let key: String
        var localizedDescription: String {
            String(format: "Geocode result missing value for key '%@'", key)
        }
    }
    
    struct UnknownError: LocalizedError {
        let localizedDescription = "An unknown error occured."
    }
    
    /// Reverse geocode an address from a map point.
    ///
    /// - Parameters:
    ///   - point: The point used in the reverse geocode operation.
    ///   - completion: A closure called upon completion of the reverse geocode.
    ///   - result: The result of the reverse geocode operation, with either the
    ///   address or an error.
    func reverseGeocodeAddress(for point: AGSPoint, completion: @escaping (_ result: Result<String, Error>) -> Void) {
        
        guard let locator = currentLocator else {
            completion(.failure(NoLocatorError()))
            return
        }
        
        locator.load { [weak self] (error) in
            // If the locator load failed, end early.
            if let error = error {
                completion(.failure(error))
                return
            }
            // We need to set the geocode parameters for storage true because the results of this reverse geocode is persisted to a table.
            // Please familiarize yourself with the implications of this credits-consuming operation:
            // https://developers.arcgis.com/rest/geocode/api-reference/geocoding-free-vs-paid.htm
            let params: AGSReverseGeocodeParameters = {
                let params = AGSReverseGeocodeParameters()
                params.forStorage = true
                return params
            }()
            // Perform the reverse geocode task.
            locator.reverseGeocode(withLocation: point, parameters: params) { (results, error) in
                guard let self = self else {
                    completion(.failure(UnknownError()))
                    return
                }
                if let error = error {
                    completion(.failure(error))
                }
                else if let result = results?.first {
                    let key: String
                    if locator == self.onlineLocator {
                        key = OnlineGeocoderConfig.addressAttributeKey
                    }
                    else {
                        key = OfflineGeocoderConfig.addressAttributeKey
                    }
                    if let address = result.attributes?[key] as? String {
                        completion(.success(address))
                    }
                    else {
                        completion(.failure(MissingAttribute(key: key)))
                    }
                }
                else {
                    completion(.failure(NoResultsError()))
                }
            }
        }
    }
    
    func removeCredentialsFromServices() {
        onlineLocator.credential = nil
        offlineLocator.credential = nil
    }
    
    deinit {
        removeCredentialsFromServices()
    }
}
