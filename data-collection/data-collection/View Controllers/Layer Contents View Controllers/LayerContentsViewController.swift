//
// Copyright 2020 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

/// Defines how to display layers in the table.
/// - Since: 100.8.0
public enum LayerContentsConfigurationStyle {
    // Displays all layers.
    case allLayers
    // Only displays layers that are in scale and visible.
    case visibleLayersAtScale
}

/// Configuration is a protocol (interface) that drives how to format the layer contents table.
/// - Since: 100.8.0
public protocol LayerContentsConfiguration {
    /// Specifies the `LayerContentsConfigurationStyle` applied to the table.
    /// - Since: 100.8.0
    var layersStyle: LayerContentsConfigurationStyle { get }
    
    /// Specifies whether layer/sublayer cells will include a switch used to toggle visibility of the layer.
    /// - Since: 100.8.0
    var allowToggleVisibility: Bool { get }
    
    /// Specifies whether layer/sublayer cells will include a chevron used show/hide the contents of a layer/sublayer.
    /// - Since: 100.8.0
    var allowLayersAccordion: Bool { get }
    
    /// Specifies whether layers/sublayers should show it's symbols.
    /// - Since: 100.8.0
    var showSymbology: Bool { get }
    
    /// Specifies whether to respect the layer order or to reverse the layer order supplied.
    /// If provided a geoView, the layer will include the basemap.
    /// - If `false`, the top layer's information appears at the top of the legend and the base map's layer information appears at the bottom of the legend.
    /// - If `true`, this order is reversed.
    /// - Since: 100.8.0
    var respectInitialLayerOrder: Bool { get }
    
    /// Specifies whether to respect `LayerConents.showInLegend` when deciding whether to include the layer.
    /// - Since: 100.8.0
    var respectShowInLegend: Bool { get }
    
    /// Specifies whether to include separators between layer cells.
    /// - Since: 100.8.0
    var showRowSeparator: Bool { get }
    
    /// The title of the view.
    /// - Since: 100.8.0
    var title: String { get }
}

/// Describes a `LayerContents` view configured to display a legend.
/// - Since: 100.8.0
public class LegendViewController: LayerContentsViewController {
    override public init() {
        super.init()
        configuration = LayerContentsViewController.Legend()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Describes a `LayerContents` view configured to display a table of contents.
/// - Since: 100.8.0
public class TableOfContentsViewController: LayerContentsViewController {
    override public init() {
        super.init()
        configuration = LayerContentsViewController.TableOfContents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Defines how to display layer contents in rows in a table view.
/// - Since: 100.8.0
internal class LayerContentsRowConfiguration {
    /// The kind of data represented by LayerContentsRowConfiguration
    /// - Since: 100.8.0
    internal enum Kind {
        // An `AGSLayer`.
        case layer(AGSLayer)
        // A sublayer which implements `AGSLayerContent` but does not inherit from`AGSLayer`.
        case sublayer(AGSLayerContent)
        // An `AGSLegendInfo`.
        case legendInfo(AGSLegendInfo)
    }

    /// Defines how to display the accordion control for the layer.
    /// - Since: 100.8.0
    internal enum AccordionDisplay {
        // The layer is expanded.
        case expanded
        // The layer is collapsed.
        case collapsed
        // No accordion control.
        case none
    }

    var kind: Kind
    var name: String = ""
    var indentationLevel: Int = 0
    var accordion: AccordionDisplay = .expanded
    var allowToggleVisibility: Bool = false
    var isVisibilityToggleOn: Bool = false
    var isVisibleAtScale: Bool = true
    var parents = [LayerContentsRowConfiguration]()
    
    init(_ kind: Kind, configuration: LayerContentsConfiguration, legendInfos: [AGSLegendInfo]) {
        self.kind = kind
        switch kind {
        case let .layer(layer):
            name = layer.name
            accordion = configuration.allowLayersAccordion &&
                (layer.subLayerContents.count > 1 || legendInfos.count > 0) ? .expanded : .none
            allowToggleVisibility = configuration.allowToggleVisibility && layer.canChangeVisibility
            isVisibilityToggleOn = layer.isVisible
        case let .sublayer(layerContent):
            name = layerContent.name
            accordion = configuration.allowLayersAccordion &&
                (layerContent.subLayerContents.count > 1 || legendInfos.count > 0) ? .expanded : .none
            allowToggleVisibility = configuration.allowToggleVisibility && layerContent.canChangeVisibility
            isVisibilityToggleOn = layerContent.isVisible
        case let .legendInfo(legendInfo):
            name = legendInfo.name
        }
    }
}

/// Describes a `LayerContentsViewController` for a list of Layers, possibly contained in a GeoView.
/// The `LayerContentsViewController` can be styled to that of a legend, table of contents or some custom derivative.
/// - Since: 100.8.0
public class LayerContentsViewController: UIViewController {
    /// Provide an out of the box TOC configuration.
    internal struct TableOfContents: LayerContentsConfiguration {
        var layersStyle: LayerContentsConfigurationStyle = .allLayers
        var allowToggleVisibility: Bool = true
        var allowLayersAccordion: Bool = true
        var showSymbology: Bool = true
        var respectInitialLayerOrder: Bool = false
        var respectShowInLegend: Bool = false
        var showRowSeparator: Bool = true
        var title: String = "Table of Contents"
    }
    
    /// Provide an out of the box Legend configuration.
    internal struct Legend: LayerContentsConfiguration {
        var layersStyle: LayerContentsConfigurationStyle = .visibleLayersAtScale
        var allowToggleVisibility: Bool = false
        var allowLayersAccordion: Bool = false
        var showSymbology: Bool = true
        var respectInitialLayerOrder: Bool = false
        var respectShowInLegend: Bool = true
        var showRowSeparator: Bool = false
        var title: String = "Legend"
    }
    
    private var dataSourceObservation: NSKeyValueObservation?
    
    /// The `LayerContentsDataSource` specifying the list of `AGSLayerContent` to display.
    /// - Since: 100.8.0
    public var dataSource: LayerContentsDataSource? = nil {
        didSet {
            // Add ourselves as delegate to catch changes to the dataSource.layerContents.
            dataSource?.delegate = self
            generateLayerList()
        }
    }
    
    /// The default configuration is a TOC. Setting a new configuration redraws the view.
    /// - Since: 100.8.0
    public var configuration: LayerContentsConfiguration = TableOfContents() {
        didSet {
            layerContentsTableViewController?.configuration = configuration
            title = configuration.title
            generateLayerList()
        }
    }
    
    // The table view controller which displays the list of layers.
    private var layerContentsTableViewController: LayerContentsTableViewController?
    
    // Dictionary of legend infos; keys are AGSLayerContent objectIdentifier values.
    private var legendInfos = [UInt: [AGSLegendInfo]]()
    
    // Dictionary of symbol swatches (images); keys are the symbol used to create the swatch.
    private var symbolSwatches = [AGSSymbol: UIImage]()
    
    // The array of all layer contents to display in the table view.
    private var displayedLayers = [AGSLayerContent]()
    
    // The array of all row configurations (`AGSLayer`, `AGSLayerContent`, `AGSLegendInfo`) to display in the table view.
    private var rowConfigurations = [LayerContentsRowConfiguration]()
    
    // Array of child:parent used when determining accordion status.
    private var parents = [LayerContentsRowConfiguration.Kind : [AGSLayerContent]]()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public convenience init(dataSource: LayerContentsDataSource) {
        self.init()
        self.dataSource = dataSource
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        if title?.isEmpty ?? false {
            // Set the title to our config.title if it hasn't been set already.
            title = configuration.title
        }

        // Get the bundle and then the storyboard for the LayerContentsTableViewController.
        let bundle = Bundle(for: LayerContentsTableViewController.self)
        let storyboard = UIStoryboard(name: "LayerContentsTableViewController", bundle: bundle)
        
        // Create the layerContentsTableViewController from the storyboard.
        layerContentsTableViewController = storyboard.instantiateInitialViewController() as? LayerContentsTableViewController
        
        if let tableViewController = layerContentsTableViewController {
            // Setup our internal LayerContentsTableViewController and add it as a child.
            addChild(tableViewController)
            view.addSubview(tableViewController.view)
            tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            tableViewController.didMove(toParent: self)
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Generate and set the layerContent list.
        generateLayerList()
        
        // Set the config on our newly-created tableViewController.
        layerContentsTableViewController?.configuration = configuration
    }
    
    /// Using the LayerContentsDataSource's `layercontents` as a starting point, generate the list of `AGSLayerContent` to include in the table view.
    private func generateLayerList() {
        // Remove all saved data.
        legendInfos.removeAll()
        symbolSwatches.removeAll()
        rowConfigurations.removeAll()
        displayedLayers.removeAll()
        
        if let layerContents = dataSource?.layerContents,
            !layerContents.isEmpty {
            // Reverse layerContents array if needed.
            displayedLayers = configuration.respectInitialLayerOrder ? layerContents : layerContents.reversed()
            
            // Filter out layers based on visibility and `showInLegend` flag (if `respectShowInLegend` is true).
            if configuration.layersStyle == .visibleLayersAtScale {
                displayedLayers = displayedLayers.filter { $0.isVisible &&
                    (configuration.respectShowInLegend ? $0.showInLegend : true)
                }
            }
            
            // Load all displayed layers if we have any.
            displayedLayers.forEach { loadIndividualLayer($0) }
        }
        
        if displayedLayers.isEmpty {
            // No layers in dataSource, set empty array on tableViewController.
            layerContentsTableViewController?.rowConfigurations = []
        }
    }
    
    /// Load an individual layer as AGSLayerContent.
    private func loadIndividualLayer(_ layerContent: AGSLayerContent) {
        if let layer = layerContent as? AGSLayer {
            // We have an AGSLayer, so make sure it's loaded.
            layer.load { [weak self] (_) in
                self?.loadSublayersOrLegendInfos(layerContent)
            }
        } else {
            // Not an AGSLayer, so just continue.
            loadSublayersOrLegendInfos(layerContent)
        }
    }
    
    /// Load sublayers or legends.
    private func loadSublayersOrLegendInfos(_ layerContent: AGSLayerContent) {
        // This is the deepest level we can go and we're assured that
        // the AGSLayer is loaded for this layer/sublayer, so
        // set the contents changed handler.
        layerContent.subLayerContentsChangedHandler = { [weak self] () in
            DispatchQueue.main.async {
                self?.updateRowConfigurations()
            }
        }
        
        // This is the parent Kind.
        let parentKind = LayerContentsRowConfiguration.Kind.sublayer(layerContent)

        // If we have sublayer contents, load those as well.
        if !layerContent.subLayerContents.isEmpty {
            layerContent.subLayerContents.forEach {
                let kind = LayerContentsRowConfiguration.Kind.sublayer($0)
                let parentsParents = parents[parentKind] ?? []
                parents[kind] = parentsParents + [layerContent]
                loadIndividualLayer($0)
            }
        } else if configuration.showSymbology {
            // Fetch the legend infos.
            layerContent.fetchLegendInfos { [weak self] (legendInfos, _) in
                guard let self = self else { return }

                // Store legendInfos and then update contents.
                guard let legendInfos = legendInfos else { return }
                self.legendInfos[layerContent.objectIdentifier()] = legendInfos
                
                // Add legendInfo parent info to parents array
                legendInfos.forEach { legendInfo in
                    let kind = LayerContentsRowConfiguration.Kind.legendInfo(legendInfo)
                    let parentsParents = self.parents[parentKind] ?? []
                    self.parents[kind] = parentsParents + [layerContent]
                }
                
                self.updateRowConfigurations()
            }
        } else {
            updateRowConfigurations()
        }
    }
    
    /// Because of the loading mechanism and the fact that we need to store
    /// our legend data in dictionaries, we need to update the array of legend
    /// items once layers load.  Updating everything here will make
    /// implementing the table view data source methods much easier.
    private func updateRowConfigurations() {
        rowConfigurations.removeAll()

        displayedLayers.forEach { layerContent in
            // If we're displaying only visible layers at scale,
            // make sure our layerContent is visible at the current scale.
            let showAtScale = layerContent.isVisible && shouldShowAtScale(layerContent)
            
            // If we're showing the layerContent, add it to our legend array.
            if (configuration.layersStyle == .visibleLayersAtScale && showAtScale) || configuration.layersStyle == .allLayers {
                if let featureCollectionLayer = layerContent as? AGSFeatureCollectionLayer {
                    // only show Feature Collection layer if the sublayer count is > 1
                    // but always show the sublayers (the call to `updateLayerLegend`)
                    if featureCollectionLayer.layers.count > 1 {
                        let internalLegendInfos = legendInfos[layerContent.objectIdentifier()] ?? []
                        let rowConfiguration = LayerContentsRowConfiguration(LayerContentsRowConfiguration.Kind.layer(featureCollectionLayer), configuration: configuration, legendInfos: internalLegendInfos)
                        rowConfiguration.isVisibleAtScale = showAtScale
                        rowConfigurations.append(rowConfiguration)
                    }
                } else {
                    let internalLegendInfos = legendInfos[layerContent.objectIdentifier()] ?? []
                    var rowConfiguration: LayerContentsRowConfiguration
                    var kind: LayerContentsRowConfiguration.Kind
                    if let layer = layerContent as? AGSLayer {
                        kind = LayerContentsRowConfiguration.Kind.layer(layer)
                    }
                    else {
                        kind = LayerContentsRowConfiguration.Kind.sublayer(layerContent)
                    }
                    rowConfiguration = LayerContentsRowConfiguration(kind,
                                                                     configuration: configuration,
                                                                     legendInfos: internalLegendInfos)

                    rowConfiguration.isVisibleAtScale = showAtScale
                    rowConfigurations.append(rowConfiguration)
                }
                updateLayerLegend(layerContent, parentShowAtScale: showAtScale)
            }
        }
        
        // Our dictionary of child:parents was set up in `loadSublayersOrLegendInfos`.
        // Now we need to populate the `Content.parents` array for each content.
        // Start by looping through all `content` items.
        rowConfigurations.forEach { configuration in
            // Get the array of parents for `content`.
            let parentArray = parents[configuration.kind] ?? []
            configuration.indentationLevel = parentArray.count
            
            // For each parent object, find the matching Content.
            parentArray.forEach { parent in
                rowConfigurations.forEach { potentialParentContent in
                    // Search all contents to see if it's a match.
                    if potentialParentContent.kind == .sublayer(parent) {
                        configuration.parents.append(potentialParentContent)
                    }
                }
            }
        }

        // Set the contents on the table view controller.
        layerContentsTableViewController?.rowConfigurations = rowConfigurations
    }
    
    private func updateLayerLegend(_ layerContent: AGSLayerContent, parentShowAtScale: Bool) {
        if !layerContent.subLayerContents.isEmpty {
            // Filter any sublayers which are not visible or not showInLegend.
            let sublayerContents = layerContent.subLayerContents.filter { ($0.isVisible &&
                (configuration.respectShowInLegend ? $0.showInLegend : true)) || configuration.layersStyle == .allLayers}
            
            sublayerContents.forEach { subLayerContent in
                let showAtScale = parentShowAtScale && shouldShowAtScale(subLayerContent)
                
                if (configuration.layersStyle == .visibleLayersAtScale && showAtScale) || configuration.layersStyle == .allLayers {
                    let internalLegendInfos = legendInfos[layerContent.objectIdentifier()] ?? []
                    let rowConfiguration = LayerContentsRowConfiguration(LayerContentsRowConfiguration.Kind.sublayer(subLayerContent),
                                                                         configuration: configuration,
                                                                         legendInfos: internalLegendInfos)
                    rowConfiguration.isVisibleAtScale = showAtScale
                    rowConfigurations.append(rowConfiguration)
                    updateLayerLegend(subLayerContent, parentShowAtScale: parentShowAtScale)
                }
            }
        } else {
            if let internalLegendInfos = legendInfos[layerContent.objectIdentifier()] {
                let showAtScale = parentShowAtScale && shouldShowAtScale(layerContent)
                let contentArray = internalLegendInfos.map { legendInfo -> LayerContentsRowConfiguration in
                    let rowConfiguration = LayerContentsRowConfiguration(LayerContentsRowConfiguration.Kind.legendInfo(legendInfo),
                                                                         configuration: configuration,
                                                                         legendInfos: [])
                    rowConfiguration.isVisibleAtScale = showAtScale
                    return rowConfiguration
                }
                
                rowConfigurations += contentArray
            }
        }
    }
    
    // MARK: - Utility
    
    /// Returns a unique UInt for each object. Used because AGSLayerContent is not hashable
    /// and we need to use it as the key in our dictionary of legendInfo arrays.
    private static func objectIdentifierFor(_ obj: AnyObject) -> UInt {
        return UInt(bitPattern: ObjectIdentifier(obj))
    }
    
    // Determine if the layerContent is visible at the current GeoView scale.
    fileprivate func shouldShowAtScale(_ layerContent: AGSLayerContent) -> Bool {
        if let viewpoint = dataSource?.geoView?.currentViewpoint(with: .centerAndScale),
            !viewpoint.targetScale.isNaN {
            return layerContent.isVisible(atScale: viewpoint.targetScale)
        }
        
        return true
    }
}

extension LayerContentsViewController: LayerContentsDataSourceDelegate {
    public func layerContentsDidChange(_ dataSource: LayerContentsDataSource) {
        generateLayerList()
    }
}

private extension AGSLayerContent {
    func objectIdentifier() -> UInt {
        return UInt(bitPattern: ObjectIdentifier(self))
    }
}

extension LayerContentsRowConfiguration.Kind: Hashable {
    private var wrappedObject: AnyObject {
        switch self {
        case .layer(let layer):
            return layer
        case .sublayer(let layerContents):
            return layerContents
        case .legendInfo(let legendInfo):
            return legendInfo
        }
    }
    
    static func == (lhs: LayerContentsRowConfiguration.Kind, rhs: LayerContentsRowConfiguration.Kind) -> Bool {
        lhs.wrappedObject === rhs.wrappedObject
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(wrappedObject))
    }
    
    /// Compares the private `Kind.wrappedObject` to a given `object`.
    /// - Parameter object: The object to compare to `Kind.wrappedObject`
    /// - Returns: `true` if it matches, `false` otherwise.
    func matches(object: AnyObject) -> Bool {
        var kind: LayerContentsRowConfiguration.Kind?
        switch object {
        case let layer as AGSLayer:
            kind = LayerContentsRowConfiguration.Kind.layer(layer)
        case let layerContent as AGSLayerContent:
            kind = LayerContentsRowConfiguration.Kind.sublayer(layerContent)
        case let legendInfo as AGSLegendInfo:
            kind = LayerContentsRowConfiguration.Kind.legendInfo(legendInfo)
        default:
            kind = nil
        }

        return self == kind
    }
}
