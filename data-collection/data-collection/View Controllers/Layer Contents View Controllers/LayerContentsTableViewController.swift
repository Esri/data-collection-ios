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

let indentationConstant: CGFloat = 10.0
let legendInfoCellReuseIdentifier = "LegendInfo"
let layerCellReuseIdentifier = "LayerTitle"
let sublayerCellReuseIdentifier = "SublayerTitle"

/// The protocol you implement to respond to user content accordion and visibility changes.
internal protocol LayerCellDelegate: AnyObject {
    /// Tells the delegate that the user has change the accordion state for `content`.
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
    
    var delegate: LayerCellDelegate?

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
    // This is the array of data to display.  'Content' contains either:
    // - layers of type AGSLayers,
    // - sublayers which implement AGSLayerContent but are not AGSLayers,
    // - legend infos of type AGSLegendInfo.
    var contents = [Content]() {
        didSet {
            updateVisibleContents()
            tableView.reloadData()
        }
    }
    
    var config: LayerContentsConfiguration = LayerContentsViewController.TableOfContents() {
        didSet {
            tableView.separatorStyle = .none
            title = config.title
            tableView.reloadData()
        }
    }
    
    // Dictionary of symbol swatches (images); keys are the symbol used to create the swatch.
    private var symbolSwatches = [AGSSymbol: UIImage]()
    var visibleContents = [Content]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func updateVisibleContents() {
        visibleContents = contents.filter({ (content) -> Bool in
            // If any of content's parent's accordionDisplay is `.collapsed`, don't show it.
            return content.parents.filter { $0.accordion == .collapsed }.isEmpty
        })
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleContents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create and configure the cell...
        let cell: UITableViewCell
        let rowItem: Content = visibleContents[indexPath.row]
        switch rowItem.contentType {
        case .layer, .sublayer:
            // rowItem is a layer or a sublayer which implements AGSLayerContent
            let layerCell: LayerCell!
            if rowItem.contentType == .layer {
                layerCell = (tableView.dequeueReusableCell(withIdentifier: layerCellReuseIdentifier) as! LayerCell)
            } else {
                layerCell = (tableView.dequeueReusableCell(withIdentifier: sublayerCellReuseIdentifier) as! LayerCell)
            }
            cell = layerCell
            layerCell.delegate = self
            layerCell.showRowSeparator = (indexPath.row > 0) && config.showRowSeparator
            layerCell.accordionButton.setImage(LayerContentsTableViewController.accordianImage(rowItem.accordion), for: .normal)
            layerCell.nameLabel.text = rowItem.name
            let enabled = rowItem.isVisibilityToggleOn && (rowItem.isVisibleAtScale)
            layerCell.nameLabel.textColor = enabled ? UIColor.black : UIColor.lightGray
            layerCell.accordionButton.isHidden = (rowItem.accordion == AccordionDisplay.none)
            layerCell.accordionButtonWidthConstraint.constant = !layerCell.accordionButton.isHidden ? layerCell.accordionButton.frame.height : 0.0
            layerCell.accordionButton.setImage(LayerContentsTableViewController.accordianImage(rowItem.accordion), for: .normal)
            layerCell.visibilitySwitch.isHidden = !rowItem.allowToggleVisibility
            layerCell.visibilitySwitch.isOn = rowItem.isVisibilityToggleOn
            layerCell.layerIndentationLevel = rowItem.indentationLevel
        case .legendInfo:
            // rowItem is a legendInfo.
            let legendInfoCell = tableView.dequeueReusableCell(withIdentifier: legendInfoCellReuseIdentifier) as! LegendInfoCell
            cell = legendInfoCell
            legendInfoCell.nameLabel.text = rowItem.name
            legendInfoCell.layerIndentationLevel = rowItem.indentationLevel

            if let legendInfo = rowItem.content as? AGSLegendInfo,
                let symbol = legendInfo.symbol {
                if let swatch = self.symbolSwatches[symbol] {
                    // We have a swatch, so set it into the imageView.
                    legendInfoCell.symbolImage = swatch
                } else {
                    // Tag the cell so we know what index path it's being used
                    // for once we create the swatch.
                    cell.tag = indexPath.hashValue
                    legendInfoCell.symbolImage = nil
                    
                    // We don't have a swatch for the given symbol, so create the swatch.
                    symbol.createSwatch(completion: { [weak self] (image, _) -> Void in
                        // Make sure this is the cell we still care about and that it
                        // wasn't already recycled by the time we get the swatch.
                        if cell.tag != indexPath.hashValue {
                            return
                        }
                        
                        // Set the swatch into our dictionary and reload the row
                        self?.symbolSwatches[symbol] = image
                        self?.tableView.reloadData()
                    })
                }
            }
        }
        return cell
    }
    
    static internal func accordianImage(_ accordion: AccordionDisplay) -> UIImage? {
        return (accordion == .expanded) ? UIImage.init(named: "caret-down") : UIImage.init(named: "caret-right")
    }
}

extension LayerContentsTableViewController {
    func accordionChanged(_ layerCell: LayerCell) {
        guard let indexPath = tableView.indexPath(for: layerCell) else { return }
        let content = visibleContents[indexPath.row]
        guard content.accordion != AccordionDisplay.none  else { return }

        let newAccordian: AccordionDisplay = (content.accordion == .expanded) ? .collapsed : .expanded
        content.accordion = newAccordian
        layerCell.accordionButton.setImage(LayerContentsTableViewController.accordianImage(newAccordian), for: .normal)

        updateVisibleContents()
        tableView.reloadData()
    }

    func visibilityChanged(_ layerCell: LayerCell) {
        guard let indexPath = tableView.indexPath(for: layerCell) else { return }
        let content = visibleContents[indexPath.row]

        (content.content as? AGSLayerContent)?.isVisible = layerCell.visibilitySwitch.isOn
        content.isVisibilityToggleOn = layerCell.visibilitySwitch.isOn
        layerCell.nameLabel.textColor = content.isVisibilityToggleOn ? UIColor.black : UIColor.lightGray
    }
}
