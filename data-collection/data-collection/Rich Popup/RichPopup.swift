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

import ArcGIS

class RichPopup: AGSPopup {
    
    // MARK: Initializer
    
    init(popup: AGSPopup) {
        super.init(geoElement: popup.geoElement, popupDefinition: popup.popupDefinition)
    }
    
    // MARK: Relationships

    /// A data structure that contains related records of the feature.
    ///
    /// Because `Relationships` conforms to `AGSLoadable`, there is a choice whether to load the feature's related records.
    ///
    lazy private(set) var relationships: Relationships? = { [unowned self] in
        return Relationships(popup: self)
    }()
}

extension RichPopup {
    override var description: String {
        return "\(geoElement.attributes["Address"] ?? ""); Diameter: \(geoElement.attributes["DBH"] ?? "")"
    }
}
