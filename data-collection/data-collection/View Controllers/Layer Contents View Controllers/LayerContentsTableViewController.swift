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

private let indentationConstant: CGFloat = 10.0

/// The protocol you implement to respond to user accordion and visibility changes.
internal protocol LayerCellDelegate: AnyObject {
    /// Tells the delegate that the user has changed the accordion state.
    func accordionChanged(_ layerCell: LayerCell)
    func visibilityChanged(_ layerCell: LayerCell)
}

/// LegendInfoCell - cell representing a LegendInfo.
class LegendInfoCell: UITableViewCell {
    var symbolImage: UIImage? {
        didSet {
            legendImageView.image = symbolImage
            symbolImage != nil ? activityIndicatorView.stopAnimating() : activityIndicatorView.startAnimating()
        }
    }
    
    var layerIndentationLevel: Int = 0 {
        didSet {
            // Set constraint constant; use +1 to account for initial indentation.
            indentationConstraint.constant = CGFloat(layerIndentationLevel + 1) * indentationConstant
        }
    }
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var legendImageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
}

/// LayerCell - cell representing either a Layer or LayerContent (i.e., a sublayer).
/// The difference is in which table view cell prototype is used for the cell.
class LayerCell: UITableViewCell {
    var layerIndentationLevel: Int = 0 {
        didSet {
            // Set constraint constant; use +1 to account for initial indentation.
            indentationConstraint.constant = CGFloat(layerIndentationLevel + 1) * indentationConstant
        }
    }
    
    var showRowSeparator: Bool = true {
        didSet {
            separatorView.isHidden = !showRowSeparator
        }
    }
    
    weak var delegate: LayerCellDelegate?

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var accordionButton: UIButton!
    @IBOutlet var visibilitySwitch: UISwitch!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet var accordionButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var separatorView: UIView!
    
    @IBAction func accordionAction(_ sender: UIButton) {
        delegate?.accordionChanged(self)
    }
    
    @IBAction func visibilityChanged(_ sender: Any) {
        delegate?.visibilityChanged(self)
    }
}

class LayerContentsTableViewController: UITableViewController, LayerCellDelegate {
    static let legendInfoCellReuseIdentifier = "LegendInfo"
    static let layerCellReuseIdentifier = "LayerTitle"
    static let sublayerCellReuseIdentifier = "SublayerTitle"

    // This is the array of data to display.  'rowConfigurations' contains either:
    // - layers of type AGSLayers,
    // - sublayers which implement AGSLayerContent but are not AGSLayers,
    // - legend infos of type AGSLegendInfo.
    var rowConfigurations = [LayerContentsRowConfiguration]() {
        didSet {
            updateVisibleConfigurations()
        }
    }
    
    var configuration: LayerContentsConfiguration = LayerContentsViewController.TableOfContents() {
        didSet {
            tableView.separatorStyle = .none
            title = configuration.title
            tableView.reloadData()
        }
    }
    
    // NSCache of symbol swatches (images); keys are the symbol used to create the swatch.
    private var symbolSwatchesCache = NSCache<AGSSymbol, UIImage>()

    var visibleConfigurations = [LayerContentsRowConfiguration]()
    
    private func updateVisibleConfigurations() {
        visibleConfigurations = rowConfigurations.filter({ (configuration) -> Bool in
            // If any of content's parent's accordionDisplay is `.collapsed`, don't show it.
            !configuration.parents.contains { $0.accordion == .collapsed }
        })

        if isViewLoaded {
            tableView.reloadData()
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleConfigurations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create and configure the cell...
        let cell: UITableViewCell
        let rowItem: LayerContentsRowConfiguration = visibleConfigurations[indexPath.row]
        switch rowItem.kind {
        case .layer:
            // rowItem is a layer or a sublayer which implements AGSLayerContent
            let layerCell = (tableView.dequeueReusableCell(withIdentifier: LayerContentsTableViewController.layerCellReuseIdentifier) as! LayerCell)
            cell = layerCell
            setupLayerCell(layerCell, indexPath, rowItem)
        case .sublayer:
            // rowItem is a layer or a sublayer which implements AGSLayerContent
            let layerCell = (tableView.dequeueReusableCell(withIdentifier: LayerContentsTableViewController.sublayerCellReuseIdentifier) as! LayerCell)
            cell = layerCell
            setupLayerCell(layerCell, indexPath, rowItem)
        case .legendInfo(let legendInfo):
            // rowItem is a legendInfo.
            let legendInfoCell = tableView.dequeueReusableCell(withIdentifier: LayerContentsTableViewController.legendInfoCellReuseIdentifier) as! LegendInfoCell
            cell = legendInfoCell
            legendInfoCell.nameLabel.text = rowItem.name
            legendInfoCell.layerIndentationLevel = rowItem.indentationLevel
            
            if let symbol = legendInfo.symbol {
                if let swatch = symbolSwatchesCache.object(forKey: symbol) {
                    // We have a swatch, so set it into the imageView.
                    legendInfoCell.symbolImage = swatch
                } else {
                    legendInfoCell.symbolImage = nil
                    
                    // We don't have a swatch for the given symbol, so create the swatch.
                    symbol.createSwatch(completion: { [weak self] (swatch, _) -> Void in
                        guard let self = self,
                            let swatch = swatch else { return }
                        
                        // Set the swatch into our dictionary and reload the row
                        self.symbolSwatchesCache.setObject(swatch, forKey: symbol)
                        
                        // Make sure our cell is still displayed and update the symbolImage.
                        if let indexPath = self.indexPath(for: rowItem),
                            let cell = self.tableView.cellForRow(at: indexPath) as? LegendInfoCell {
                            cell.symbolImage = swatch
                        }
                    })
                }
            }
        case .none:
            cell = (tableView.dequeueReusableCell(withIdentifier: LayerContentsTableViewController.layerCellReuseIdentifier) as! LayerCell)
        }
        return cell
    }
    
    private func indexPath(for configuration: LayerContentsRowConfiguration) -> IndexPath? {
        visibleConfigurations
            .firstIndex(where: { $0.object === configuration.object })
            .map { IndexPath(row: $0, section: 0) }
    }
    
    fileprivate func setupLayerCell(_ layerCell: (LayerCell), _ indexPath: IndexPath, _ rowItem: LayerContentsRowConfiguration) {
        layerCell.delegate = self
        layerCell.showRowSeparator = (indexPath.row > 0) && configuration.showRowSeparator
        layerCell.nameLabel.text = rowItem.name
        let enabled = rowItem.isVisibilityToggleOn && (rowItem.isVisibleAtScale)
        layerCell.nameLabel.textColor = enabled ? UIColor.black : UIColor.lightGray
        layerCell.accordionButton.isHidden = (rowItem.accordion == LayerContentsRowConfiguration.AccordionDisplay.none)
        layerCell.accordionButtonWidthConstraint.constant = !layerCell.accordionButton.isHidden ? layerCell.accordionButton.frame.height : 0.0
        layerCell.accordionButton.setImage(rowItem.accordion.image, for: .normal)
        layerCell.visibilitySwitch.isHidden = !rowItem.allowToggleVisibility
        layerCell.visibilitySwitch.isOn = rowItem.isVisibilityToggleOn
        layerCell.layerIndentationLevel = rowItem.indentationLevel
    }
}

extension LayerContentsRowConfiguration.AccordionDisplay {
    var image: UIImage? {
        let name = self == .expanded ? "chevron-down" : "chevron-right"
        return UIImage(named: name)
    }
}

extension LayerContentsTableViewController {
    func accordionChanged(_ layerCell: LayerCell) {
        guard let indexPath = tableView.indexPath(for: layerCell) else { return }
        let configuration = visibleConfigurations[indexPath.row]
        guard configuration.accordion != .none  else { return }

        let newAccordian: LayerContentsRowConfiguration.AccordionDisplay = (configuration.accordion == .expanded) ? .collapsed : .expanded
        configuration.accordion = newAccordian
        layerCell.accordionButton.setImage(newAccordian.image, for: .normal)

        updateVisibleConfigurations()
    }

    func visibilityChanged(_ layerCell: LayerCell) {
        guard let indexPath = tableView.indexPath(for: layerCell) else { return }
        let configuration = visibleConfigurations[indexPath.row]
        (configuration.object as? AGSLayerContent)?.isVisible = layerCell.visibilitySwitch.isOn
        configuration.isVisibilityToggleOn = layerCell.visibilitySwitch.isOn
        layerCell.nameLabel.textColor = configuration.isVisibilityToggleOn ? UIColor.black : UIColor.lightGray
    }
}
