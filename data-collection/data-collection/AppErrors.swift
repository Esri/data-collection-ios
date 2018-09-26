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

protocol AppError: CustomNSError, LocalizedError {
    var baseCode: AppErrorBaseCode { get }
}

struct AppErrorBaseCode: RawRepresentable {
    
    typealias RawValue = Int
    
    var rawValue: RawValue
    
    init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    // Needed to satisfy the protocol requirement.
    init?(rawValue: RawValue) {
        self.init(rawValue)
    }
}

extension AppErrorBaseCode {
    
    static let RelatedRecordsManagerError = AppErrorBaseCode(1000)
    static let FeatureTableError = AppErrorBaseCode(2000)
    static let PopupSortingError = AppErrorBaseCode(3000)
    static let GeocoderResultsError = AppErrorBaseCode(4000)
    static let RelatedRecordsTableLoadError = AppErrorBaseCode(5000)
    static let MapViewError = AppErrorBaseCode(6000)
}
