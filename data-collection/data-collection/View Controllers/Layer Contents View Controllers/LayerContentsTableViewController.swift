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

let initialIndentation: CGFloat = 16.0

class LegendInfoCell: UITableViewCell {
    var legendInfo: AGSLegendInfo? {
        didSet {
            nameLabel.text = legendInfo?.name
        }
    }
    
    var symbolImage: UIImage? {
        didSet {
            legendImageView.image = symbolImage
            activityIndicatorView.isHidden = (symbolImage != nil)
        }
    }
    
    var layerIndentationLevel: Int = 0 {
        didSet {
            indentationConstraint.constant = CGFloat(layerIndentationLevel) * 8.0 + initialIndentation
        }
    }
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var legendImageView: UIImageView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
}

class LayerCell: UITableViewCell {
    var content: Content? {
        didSet {
            nameLabel.text = content?.name
            nameLabel.textColor = (content?.isVisibilityToggleOn ?? false) ? UIColor.black : UIColor.lightGray
            accordianButton.isHidden = (content?.accordian == AccordianDisplay.none)
            accordianButtonWidthConstraint.constant = !accordianButton.isHidden ? accordianButton.frame.height : 0.0

            visibilitySwitch.isHidden = !(content?.allowToggleVisibility ?? false)
            visibilitySwitch.isOn = content?.isVisibilityToggleOn ?? false
        }
    }
    
    var layerIndentationLevel: Int = 0 {
        didSet {
            indentationConstraint.constant = CGFloat(layerIndentationLevel) * 8.0 + initialIndentation
        }
    }
    
    var showRowSeparator: Bool = true {
        didSet {
            separatorView.isHidden = !showRowSeparator
        }
    }

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var accordianButton: UIButton!
    @IBOutlet var visibilitySwitch: UISwitch!
    @IBOutlet var indentationConstraint: NSLayoutConstraint!
    @IBOutlet var accordianButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet var separatorView: UIView!
    
    @IBAction func accordianAction(_ sender: Any) {
    }
    
    @IBAction func visibilityChanged(_ sender: Any) {
        (content?.content as? AGSLayerContent)?.isVisible = (sender as! UISwitch).isOn
        content?.isVisibilityToggleOn = (sender as! UISwitch).isOn
        nameLabel.textColor = (content?.isVisibilityToggleOn ?? false) ? UIColor.black : UIColor.lightGray
    }
}

class LayerContentsTableViewController: UITableViewController {
    var legendInfoCellReuseIdentifier = "LegendInfo"
    var layerCellReuseIdentifier = "LayerTitle"
    var sublayerCellReuseIdentifier = "SublayerTitle"
    
    var geoView: AGSGeoView?
    
    // This is the array of data to display.  It can contain either:
    // layers of type AGSLayers,
    // sublayers which implement AGSLayerContent but are not AGSLayers,
    // legend infos of type AGSLegendInfo
    var contents = [Content]() {
        didSet {
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
    
    // dictionary of symbol swatches (images); keys are the symbol used to create the swatch
    private var symbolSwatches = [AGSSymbol: UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
//        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//        self.parent?.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create and configure the cell...
        var cell: UITableViewCell!
        let rowItem: Content = contents[indexPath.row]
        switch rowItem.contentType {
        case .layer:
            // rowItem is a layer
            let layerCell = tableView.dequeueReusableCell(withIdentifier: layerCellReuseIdentifier) as! LayerCell
            cell = layerCell
            layerCell.content = rowItem
            layerCell.showRowSeparator = (indexPath.row > 0) && config.showRowSeparator
        case .sublayer:
            // rowItem is not a layer, but still implements AGSLayerContent, so it's a sublayer
            let layerCell = tableView.dequeueReusableCell(withIdentifier: sublayerCellReuseIdentifier) as! LayerCell
            cell = layerCell
            layerCell.content = rowItem
            layerCell.showRowSeparator = (indexPath.row > 0) && config.showRowSeparator
        case .legendInfo:
            // rowItem is a legendInfo
            let layerInfoCell = tableView.dequeueReusableCell(withIdentifier: legendInfoCellReuseIdentifier) as! LegendInfoCell
            cell = layerInfoCell
            layerInfoCell.legendInfo = rowItem.content as? AGSLegendInfo
            layerInfoCell.layerIndentationLevel = 0
            
            //            let imageview = cell.viewWithTag(LegendViewController.imageViewTag) as? UIImageView
            if let symbol = layerInfoCell.legendInfo?.symbol {
                //                let activityIndicator = cell.viewWithTag(LegendViewController.activityIndicatorTag) as! UIActivityIndicatorView
                if let swatch = self.symbolSwatches[symbol] {
                    // We have a swatch, so set it into the imageView and stop the activity indicator
                    layerInfoCell.symbolImage = swatch
                    //                    activityIndicator.stopAnimating()
                } else {
                    // Tag the cell so we know what index path it's being used for
                    cell.tag = indexPath.hashValue
                    layerInfoCell.symbolImage = nil
                    
                    // We don't have a swatch for the given symbol, so create the swatch
                    symbol.createSwatch(completion: { [weak self] (image, _) -> Void in
                        // Make sure this is the cell we still care about and that it
                        // wasn't already recycled by the time we get the swatch
                        if cell.tag != indexPath.hashValue {
                            return
                        }
                        
                        // set the swatch into our dictionary and reload the row
                        self?.symbolSwatches[symbol] = image
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    })
                }
            }
        }
        return cell
    }
}
