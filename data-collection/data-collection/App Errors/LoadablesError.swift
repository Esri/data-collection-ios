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

enum LoadableError: AppError {
    
    var baseCode: AppErrorBaseCode { return .LoadableError }
    
    case multiLoadableFailure(String, [Error])
    
    var errorCode: Int {
        let base = baseCode.rawValue
        switch self {
        case .multiLoadableFailure(_):
            return base + 1
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .multiLoadableFailure(let objectLocalizedDescription, let errors):
            return [NSLocalizedFailureReasonErrorKey: "One or more loadable objects failed to load. Interrogate the \"MultiLoadablesFailureErrors\" key to learn more.",
                    NSLocalizedDescriptionKey: "Error loading \(objectLocalizedDescription.localizedLowercase).",
                    "MultiLoadablesFailureErrors": errors]
        }
    }
    
    var localizedDescription: String {
        return errorUserInfo[NSLocalizedDescriptionKey] as! String
    }
}
