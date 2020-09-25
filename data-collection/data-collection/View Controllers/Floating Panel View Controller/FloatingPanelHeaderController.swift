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
    private var closeButtonObservation: NSKeyValueObservation?
    private var titleLabelObservation: NSKeyValueObservation?
    private var subtitleLabelObservation: NSKeyValueObservation?
    private var imageViewObservation: NSKeyValueObservation?
    
    var floatingPanelItem: FloatingPanelItem? {
        didSet {
            guard let fpItem = floatingPanelItem else { return }
            
            // Ensure the view is loaded.
            loadViewIfNeeded()
            
            // Set the applicable `FloatingPanelItem` properties on our controls.
            titleLabel.text = fpItem.title
            subtitleLabel.text = fpItem.subtitle
            imageView.image = fpItem.image
            setImageViewHidden(imageView.image == nil)
            closeButton.isHidden = fpItem.closeButtonHidden
            
            // Set up the `FloatingPanelItem` observers.
            closeButtonObservation = fpItem.observe(\.closeButtonHidden, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    self?.closeButton.isHidden = fpItem.closeButtonHidden
                }
            }
            
            titleLabelObservation = fpItem.observe(\.title, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    self?.titleLabel.text = fpItem.title
                }
            }
            
            subtitleLabelObservation = fpItem.observe(\.subtitle) { [weak self] (_, _) in
                DispatchQueue.main.async {
                    self?.subtitleLabel.text = fpItem.subtitle
                }
            }
            
            imageViewObservation = fpItem.observe(\.image, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    self?.imageView.image = fpItem.image
                    self?.setImageViewHidden(self?.imageView.image == nil)
                }
            }
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
    
    /// Shows or hides the imageView and associated subtitle spacer.
    /// - Parameter isHidden: Denotes whether the imageView should be hidden.
    private func setImageViewHidden(_ isHidden: Bool) {
        imageView.isHidden = isHidden
        subtitleSpacerView.isHidden = isHidden
    }
}
