//
// Copyright 2020 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

/// A protocol for allowing clients to determine when the contents of the `layerContents` property changed.
public protocol LayerContentsDataSourceDelegate: AnyObject {
    /// Method called when the `layerContents` array changes.
    /// - Parameter dataSource: The data source triggering the change.
    func layerContentsDidChange(_ dataSource: LayerContentsDataSource)
}

/// The data source is used to represent an array of `AGSLayerContent` for use in a variety of
/// implementations. It is initialized with either an array of `AGSLayerContent`
/// or an `AGSGeoView` from whose `AGSMap` or `AGSScene` the  operational and
/// base map layers (`AGSLayerContent`) are extracted.
/// - Since: 100.8.0
public class LayerContentsDataSource: NSObject {
    /// Creates a `DataSource` initialized with a sequence of `AGSLayerContent` objects.
    /// - Parameter layers: The layers with which to initialize the data source.
    /// - Since: 100.8.0
    public init<S: Sequence>(layers: S) where S.Element == AGSLayerContent {
        super.init()
        layerContents.append(contentsOf: layers)
    }
    
    /// Returns a `DataSource` initialized with the operational and base map layers of a
    /// map or scene in an `AGSGeoView`.
    /// - Parameter geoView: The `AGSGeoView` containing the map/scene's
    /// operational and base map layers.
    /// - Since: 100.8.0
    public init(geoView: AGSGeoView) {
        super.init()
        self.geoView = geoView
        geoViewDidChange()
    }
    
    /// The `AGSGeoView` containing either an `AGSMap` or `AGSScene` with the operational and
    /// base map layers to use as data.
    /// If the `DataSource` was initialized with an array of `AGSLayerContent`, `geoView` will be nil.
    /// - Since: 100.8.0
    public private(set) var geoView: AGSGeoView? {
        didSet {
            geoViewDidChange()
        }
    }

    /// The list of all layers used to generate the TOC/Legend, read-only.  It contains both the
    /// operational layers of the map/scene and the reference and base layers of the basemap.
    /// The order of the layer contents is the order in which they are drawn
    /// in a map or scene:  bottom up (the first layer in the array is at the bottom and drawn first; the last
    /// layer is at the top and drawn last).
    /// - Since: 100.8.0
    public private(set) var layerContents = [AGSLayerContent]() {
        didSet {
            self.delegate?.layerContentsDidChange(self)
        }
    }
    
    private var mapOrSceneObservation: NSKeyValueObservation?
    
    public weak var delegate: LayerContentsDataSourceDelegate?

    private func geoViewDidChange() {
        mapOrSceneObservation?.invalidate()
        if let mapView = geoView as? AGSMapView {
            mapView.map?.load { [weak self] (_) in
                guard let self = self,
                    let map = mapView.map else { return }
                let layerContents = map.operationalLayers as? [AGSLayerContent] ?? []
                self.appendBasemap(map.basemap, layerContents) { [weak self] (newLayerContents) in
                    self?.layerContents = newLayerContents
                }
            }
            
            // Add an observer to handle changes to the mapView.map.
            mapOrSceneObservation = mapView.observe(\.map) { [weak self] (_, _) in
                self?.geoViewDidChange()
            }
        } else if let sceneView = geoView as? AGSSceneView {
            sceneView.scene?.load { [weak self] (_) in
                guard let self = self,
                    let scene = sceneView.scene,
                    let basemap = scene.basemap else { return }
                let layerContents = scene.operationalLayers as? [AGSLayerContent] ?? []
                self.appendBasemap(basemap, layerContents) { [weak self] (newLayerContents) in
                    self?.layerContents = newLayerContents
                }
            }
            
            // Add an observer to handle changes to the sceneView.scene.
            mapOrSceneObservation = sceneView.observe(\.scene) { [weak self] (_, _) in
                self?.geoViewDidChange()
            }
        }
        
        // Set the layerViewStateChangedHandler on the GeoView.
        geoView?.layerViewStateChangedHandler = { [weak self] (_, _) in
            self?.geoViewDidChange()
        }
    }

    private func appendBasemap(_ basemap: AGSBasemap, _ layerContents: [AGSLayerContent], _ completion:  @escaping ([AGSLayerContent]) -> Void) {
        basemap.load { (_) in
            var newLayerContents = layerContents
            // Append any reference layers to the `newLayerContents` array.
            if let referenceLayers = basemap.referenceLayers as? [AGSLayerContent] {
                newLayerContents.append(contentsOf: referenceLayers)
            }
            
            // Insert any base layers at the beginning of the `newLayerContents` array.
            if let baseLayers = basemap.baseLayers as? [AGSLayerContent] {
                newLayerContents.insert(contentsOf: baseLayers, at: 0)
            }
            
            completion(newLayerContents)
        }
    }
}
