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

class AppRules {
    
    /// A rule imposed by the app determining if a layer can be identified.
    ///
    /// The rules determinig if a layer can identified include:
    /// * Is the layer visible?
    /// * Is the layer's underlying table's geometry of type point?
    /// * Are pop-ups enabled on the layer's underlying table?
    ///
    /// - Parameters:
    ///     - layer: The layer in question.
    ///
    /// - Returns: If the layer is identifiable or not.
    
    static func isLayerIdentifiable(_ layer: AGSFeatureLayer) -> Bool {
        guard
            layer.isVisible,
            let featureTable = layer.featureTable,
            featureTable.geometryType == .point,
            featureTable.isPopupActuallyEnabled else {
                return false
        }
        return true
    }
    
    /// A rule imposed by the app determining if a layer can be added to.
    ///
    /// The rules determinig if a layer can identified include:
    /// * Is the layer's underlying table editable?
    /// * Is the layer's underlying table's geometry of type point?
    /// * Are pop-ups enabled on the layer's underlying table?
    ///
    /// - Parameters:
    ///     - layer: The layer in question.
    ///
    /// - Returns: If the layer is identifiable or not.
    
    static func isLayerAddable(_ layer: AGSFeatureLayer) -> Bool {
        guard
            let featureTable = layer.featureTable,
            featureTable.isEditable,
            featureTable.canAddFeature,
            featureTable.geometryType == .point,
            featureTable.isPopupActuallyEnabled else {
                return false
        }
        return true
    }
}

extension Collection where Iterator.Element == AGSFeatureLayer {
    
    /// An array of layers that adhere to the app imposed rule, is layer addable.
    ///
    /// - Note: This can be used by an `AGSMap` to determine which of it's `operationalLayers` can be added to within this app.
    
    var featureAddableLayers: [AGSFeatureLayer] {
        return filter { return AppRules.isLayerAddable($0) }
    }
}
