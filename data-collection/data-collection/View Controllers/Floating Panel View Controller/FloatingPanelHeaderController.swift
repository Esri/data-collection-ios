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

/// The `UIViewController` representing the header of a `FloatingPanelController`.
internal class FloatingPanelHeaderController: UIViewController {
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var subtitleSpacerView: UIView!
    
    /// Observers for `FloatingPanelItem` properties that are
    /// displayed by the `FloatingPanelHeaderController`.
    private var observers: [NSKeyValueObservation]?
    
    var floatingPanelItem: FloatingPanelItem? {
        didSet {
            guard let item = floatingPanelItem else { return }
            
            // Ensure the view is loaded.
            loadViewIfNeeded()
            
            // Set the applicable `FloatingPanelItem` properties on our controls.
            titleLabel.text = item.title
            setSubtitle(item.subtitle)
            setImage(from: item)
            closeButton.isHidden = item.closeButtonHidden
            
            // Set up the `FloatingPanelItem` observers.
            observers = [
                item.observe(\.closeButtonHidden) { [weak self] (_, _) in
                    DispatchQueue.main.async {
                        self?.closeButton.isHidden = item.closeButtonHidden
                    }
                },
                item.observe(\.title) { [weak self] (_, _) in
                    DispatchQueue.main.async {
                        self?.titleLabel.text = item.title
                    }
                },
                item.observe(\.subtitle) { [weak self] (_, _) in
                    DispatchQueue.main.async {
                        self?.setSubtitle(item.subtitle)
                    }
                },
                item.observe(\.image) { [weak self] (_, _) in
                    DispatchQueue.main.async {
                        self?.setImage(from: item)
                    }
                }]
        }
    }
    
    /// The handler called when the user taps the button.
    var closeButtonHandler: (() -> Void)?
    
    /// Instantiates a `FloatingPanelHeaderController` from the storyboard.
    /// - Returns: A `FloatingPanelHeaderController`.
    static func instantiate() -> FloatingPanelHeaderController {
        // Get the storyboard for the FloatingPanelHeaderController.
        let storyboard = UIStoryboard(name: "FloatingPanelController", bundle: .main)

        // Instantiate the FloatingPanelHeaderController.
        return storyboard.instantiateViewController(withIdentifier: "FloatingPanelHeaderController") as! FloatingPanelHeaderController
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        closeButtonHandler?()
    }
    
    /// Sets the image on the image view and adjusts the visibility of
    /// the imageView and subtitle spacer view based on the presence
    /// of `item.image`.
    /// - Parameter isHidden: Denotes whether the imageView should be hidden.
    private func setImage(from item: FloatingPanelItem) {
        if let image = item.image {
            imageView.image = image
            imageView.isHidden = false
            subtitleSpacerView.isHidden = false
        }
        else {
            imageView.image = nil
            imageView.isHidden = true
            subtitleSpacerView.isHidden = true
        }
    }
    
    private func setSubtitle(_ subtitle: String?) {
        subtitleLabel.text = subtitle
        subtitleLabel.considerEmptyString()
    }
}
