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

extension AGSRelationshipInfo {
    
    /// Facilitates asking a relationship info object if it is the colloquial many-to-one relationship type.
    public var isManyToOne: Bool {
        return cardinality == .oneToMany && role == .destination
    }
    
    /// Facilitates asking a relationship info object if it is the colloquial one-to-many relationship type.
    public var isOneToMany: Bool {
        return cardinality == .oneToMany && role == .origin
    }
}
