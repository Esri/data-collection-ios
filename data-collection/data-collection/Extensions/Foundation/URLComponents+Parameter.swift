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

extension URLComponents {
    
    /// Facilitates retrieving the value for a query parameter name, if one exists.
    ///
    /// - Parameter name: The query parameter name for which we would like the value.
    ///
    /// - Returns: The value as a string, if one exits.
    
    func queryParameter(named name:String) -> String? {
        return self.queryItems?.first(where: { (item) -> Bool in item.name == name })?.value
    }
    
    /// Informs the app if a URL has a certain parameter.
    ///
    /// - Parameter name: The query parameter name for which we would like to determine if it exists.
    ///
    /// - Returns: Whether the parameter name does exist or not.
    
    func hasParameter(named name: String) -> Bool {
        return queryParameter(named: name) != nil
    }
}
