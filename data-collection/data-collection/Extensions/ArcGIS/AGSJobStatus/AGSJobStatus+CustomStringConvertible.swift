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

/// Facilitates logging `AGSJobStatus` to console.
///
/// - Note: Calling `description` directly is discouraged.

extension AGSJobStatus: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .started:
            return "Started"
        case .paused:
            return "Paused"
        case .succeeded:
            return "Succeeded"
        case .failed:
            return "Failed"
        @unknown default:
            fatalError("Unsupported case \(self).")
        }
    }
}
