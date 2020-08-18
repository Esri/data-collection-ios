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

// TODO: what about creating FloatingPanelViewController automatically when added to a FloatingPanel?
// Can you access the navigationItem of the ViewController *before* it's added to a UINavigationController?

import UIKit

public class FloatingPanelHeaderViewController: UIViewController {
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var subtitleSpacerView: UIView!

    private var closeButtonObservation: NSKeyValueObservation?
    private var titleLabelObservation: NSKeyValueObservation?
    private var subtitleLabelObservation: NSKeyValueObservation?
    private var imageViewObservation: NSKeyValueObservation?
    
    public var floatingPanelItem: FloatingPanelItem? {
        didSet {
            guard let fpItem = floatingPanelItem else { return }
            loadViewIfNeeded()
            titleLabel.text = fpItem.title
            subtitleLabel.text = fpItem.subtitle
            imageView.image = fpItem.image
            setImageViewHidden(imageView.image == nil)
            closeButton.isHidden = fpItem.closeButtonHidden
            
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
            
            subtitleLabelObservation = fpItem.observe(\.subtitle, options: [.new]) { [weak self] (_, change) in
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
    
    public var closeButtonHandler: (() -> Void)?
    
    // use this static method to instantiate the view controller from our storyboard
    static func instantiateFloatingPanelHeaderViewController() -> FloatingPanelHeaderViewController {
        // Create the FloatingPanelViewController.
        // Create and configure the view controller.
        // Get the bundle and then the storyboard for the LayerContentsTableViewController.
        let bundle = Bundle(for: FloatingPanelHeaderViewController.self)
        let storyboard = UIStoryboard(name: "FloatingPanelViewController", bundle: bundle)
        // Create the layerContentsTableViewController from the storyboard.
        let floatingPanelHeaderVC = storyboard.instantiateViewController(withIdentifier: "FloatingPanelHeaderViewController") as? FloatingPanelHeaderViewController ?? FloatingPanelHeaderViewController()
        return floatingPanelHeaderVC
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        closeButtonHandler?()
    }
    
    private func setImageViewHidden(_ isHidden: Bool) {
        imageView.isHidden = isHidden
        subtitleSpacerView.isHidden = isHidden
    }
}
