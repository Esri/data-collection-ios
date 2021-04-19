// Copyright 2020 Esri
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
import Combine

class IdentifyResultsViewController: UITableViewController, FloatingPanelEmbeddable {
    var popupChangedHandler: ((RichPopup?) -> Void)?

    var floatingPanelItem = FloatingPanelItem()
    
    private let cellIdentifier = "Cell"
    var selectedPopups = [RichPopup]() {
        didSet {
            if isViewLoaded {
                tableView.reloadData()
            }
            
            // Set Floating Panel item properties.
            floatingPanelItem.title = "Identify Results"
            let selected = self.selectedPopups.count
            floatingPanelItem.subtitle = String("\(selected) Feature\(selected > 1 ? "s" : "")")
        }
    }
    
    // Dictionary of symbol swatches (images); keys are the symbol used to create the swatch.
    private var swatches = NSCache<AGSSymbol, UIImage>()
    private var subtitles = NSCache<RichPopup, NSString>()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
        navigationController?.isToolbarHidden = true
        
        popupChangedHandler?(nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
       1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       selectedPopups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        let richPopup = selectedPopups[indexPath.row]
        cell.textLabel?.text = richPopup.title
        if let symbol = richPopup.symbol {
            if let swatch = swatches.object(forKey: symbol) {
                // we have a swatch, so set it into the imageView and stop the activity indicator
                cell.imageView?.image = swatch
            } else {
                // tag the cell so we know what index path it's being used for
                cell.tag = indexPath.hashValue

                // we don't have a swatch for the given symbol, start the activity indicator
                // and create the swatch
                symbol.createSwatch(completion: { [weak self] (image, _) -> Void in
                    // make sure this is the cell we still care about and that it
                    // wasn't already recycled by the time we get the swatch
                    guard cell.tag == indexPath.hashValue, let image = image else { return }

                    // set the swatch into our dictionary and reload the row
                    self?.swatches.setObject(image, forKey: symbol)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                })
            }
        }
        if let subtitle = subtitles.object(forKey: richPopup) as String? {
            cell.detailTextLabel?.text = subtitle
        }
        else {
            richPopup.evaluateSubtitle { [weak self] (subtitle) in
                self?.subtitles.setObject(subtitle as NSString, forKey: richPopup)
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        
        return cell
    }

    // MARK: - Navigation

    private var popupEditing: Cancellable?

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        let richPopup = selectedPopups[indexPath.row]
        popupChangedHandler?(richPopup)

        guard let destination = segue.destination as? RichPopupViewController else { return }
        destination.popupManager = RichPopupManager(richPopup: richPopup)

        popupEditing?.cancel()
        popupEditing = destination.editsMade.sink { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.showError(error)
            case .success(let richPopup):
                if !richPopup.isFeatureAddedToTable,
                   let index = self?.selectedPopups.firstIndex(of: richPopup) {
                    self?.selectedPopups.remove(at: index)
                }
            }
        }
    }
}
