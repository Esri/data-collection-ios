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

class AppDateFormatter: DateFormatter {
    
    private static let appShared = AppDateFormatter()
    
    private static let appFormatterQueue = DispatchQueue(label: "\(appBundleID).dateFormatter")
    
    /// Uses static synchronous dispatch queue to produce a formatted date.
    ///
    /// - Parameter date: The `Date` to format.
    ///
    /// - Returns: A string formatted with date style `.medium` and time style `.none`.
    
    static func format(mediumDate date: Date) -> String {
        
        return appFormatterQueue.sync {
            
            appShared.dateStyle = .medium
            appShared.timeStyle = .none
            
            return appShared.string(from: date)
        }
    }
    
    /// Uses static synchronous dispatch queue to produce a formatted date (and time).
    ///
    /// - Parameter date: The `Date` to format.
    ///
    /// - Returns: A string formatted with date style `.short` and time style `.short`.
    
    static func format(shortDateTime date: Date) -> String {
        
        return appFormatterQueue.sync {
            
            appShared.dateStyle = .short
            appShared.timeStyle = .short
            
            return appShared.string(from: date)
        }
    }
}
