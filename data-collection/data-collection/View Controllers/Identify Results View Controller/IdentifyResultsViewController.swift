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

import UIKit
import ArcGIS

class IdentifyResultsViewController: UITableViewController, FloatingPanelEmbeddable {
    var popupChangedHandler: ((RichPopup?) -> Void)?

    var floatingPanelItem: FloatingPanelItem = {
        return FloatingPanelItem()
    }()
    
    let cellIdentifier = "Cell"
    var selectedPopups = [RichPopup]() {
        didSet {
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
    
    // Dictionary of symbol swatches (images); keys are the symbol used to create the swatch.
    private var symbolSwatches = [AGSSymbol: UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedPopups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        let richPopup = selectedPopups[indexPath.row]
        cell.textLabel?.text = richPopup.title
        let attributes = richPopup.geoElement.attributes
        cell.detailTextLabel?.text = "\(attributes["Address"] ?? ""); Diameter: \(attributes["DBH"] ?? "")"
        if let symbol = richPopup.symbol {
            if let swatch = symbolSwatches[symbol] {
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
                    if cell.tag != indexPath.hashValue {
                        return
                    }

                    // set the swatch into our dictionary and reload the row
                    self?.symbolSwatches[symbol] = image
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                })
            }
        }
        return cell
    }
    
    var richPopup: RichPopup?
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        //            // Use the geometry engine to determine the nearest pop-up to the touch point.
//        //            if let nearest = identifyResult.popups.popupNearestTo(mapPoint: mapPoint) {
//        //                let richPopup = RichPopup(popup: nearest)
//        //                self.setCurrentPopup(popup: richPopup)
//        //            }
//        //            else {
//        //                self.clearCurrentPopup()
//        //            }
//        richPopup = selectedPopups[indexPath.row]
//        popupChangedHandler?(richPopup)
//        performSegue(withIdentifier: "showRichPopup", sender: nil)
////        if let popup = richPopup, let vc = prepareRichPopupViewController(popup) {
////            print("pushing popupvc")
////            navigationController?.pushViewController(vc, animated: true)
////        }
//    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    func prepareRichPopupViewController(_ richPopup: RichPopup) -> UIViewController? {
        popupChangedHandler?(richPopup)
        
        let bundle = Bundle(for: RichPopupViewController.self)
        let storyboard = UIStoryboard(name: "RichPopup", bundle: bundle)
        
        // create the legend VC from the storyboard
        let popupVC = storyboard.instantiateInitialViewController() as? AppContextAwareNavigationController
        return popupVC
//        guard let destination = segue.navigationDestination as? RichPopupViewController else { return }
//        if let newPopup = EphemeralCache.shared.object(forKey: .newSpatialFeature) as? RichPopup {
//            //                setCurrentPopup(popup: newPopup)
//            destination.popupManager = RichPopupManager(richPopup: newPopup)
//            destination.setEditing(true, animated: false)
//            //                mapViewMode = .selectedFeature(visible: false)
//        }
//        else if let popupManager = EphemeralCache.shared.object(forKey: .newRelatedRecord) as? RichPopupManager {
//            destination.setEditing(true, animated: false)
//            destination.popupManager = popupManager
//            destination.shouldLoadRichPopupRelatedRecords = false
//        }
//        else {
//        else if let currentPopupManager = currentPopupManager {
//            destination.popupManager = RichPopupManager(richPopup: richPopup!)
//        }
//        else {
//            assertionFailure("A rich popup view controller should not present if any of the above scenarios are not met.")
//        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        richPopup = selectedPopups[indexPath.row]
        popupChangedHandler?(richPopup)

        guard let destination = segue.destination as? RichPopupViewController else { return }
        if let newPopup = EphemeralCache.shared.object(forKey: .newSpatialFeature) as? RichPopup {
            //                setCurrentPopup(popup: newPopup)
            destination.popupManager = RichPopupManager(richPopup: newPopup)
            destination.setEditing(true, animated: false)
            //                mapViewMode = .selectedFeature(visible: false)
        }
        else if let popupManager = EphemeralCache.shared.object(forKey: .newRelatedRecord) as? RichPopupManager {
            destination.setEditing(true, animated: false)
            destination.popupManager = popupManager
            destination.shouldLoadRichPopupRelatedRecords = false
        }
        else {
//        else if let currentPopupManager = currentPopupManager {
            destination.popupManager = RichPopupManager(richPopup: richPopup!)
        }
//        else {
//            assertionFailure("A rich popup view controller should not present if any of the above scenarios are not met.")
//        }
    }

//    override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
//        navigationController?.pushViewController(vc, animated: true)
//    }

    // TODO
//    Add handler property for when current popup changes.  That way the mapViewController
//    can pass in a handler that would take care of selecting the appropriate graphic and UI (if any)
//    based on when the user selects a new popup.  It would have to take nil, which would be the
//    "unselect" case, like when the user goes back to the main list.
    
//    func refreshCurrentPopup() {
//
//        guard case MapViewMode.selectedFeature = mapViewMode, let popup = currentPopupManager?.richPopup else {
//            return
//        }
//
//        guard popup.isFeatureAddedToTable else {
//            clearCurrentPopup()
//            mapViewMode = .defaultView
//            return
//        }
//
//        // Select the underlying feature
//        if let feature = popup.feature {
//            (feature.featureTable?.layer as? AGSFeatureLayer)?.select(feature)
//        }
//
//        if let popupRelationships = popup.relationships {
//
//            popupRelationships.load { [weak self] (error) in
//
//                if let error = error {
//                    print("[Error: RichPopup] relationships load error: \(error)")
//                }
//
//                guard let self = self else { return }
//
//                self.populateContentIntoSmallPopupView(popup)
//            }
//        }
//        else {
//
//            populateContentIntoSmallPopupView(popup)
//        }
//    }
}
