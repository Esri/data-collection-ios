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
import ArcGISToolkit
import ArcGIS

/// The protocol implemented to respond to floating panel view controller events.
public protocol FloatingPanelViewControllerDelegate: AnyObject {
    /// Tells the delegate that the user has requested to dismiss the floating panel view controller.
    ///
    /// - Parameter floatingPanelViewController: The current floating panel view controller.
    func userDidRequestDismissFloatingPanel(_ floatingPanelViewController: FloatingPanelViewController)
}

/// Defines the vertical state of the floating panel view controller.
public enum FloatingPanelState {
    // Minimized is used to set a default minimum size.
    case minimized
    // A height roughly 40% of the screen.
    case partial
    // Fills available vertical space.
    case full
}

public class FloatingPanelViewController: UIViewController {
    
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var contentView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subTitleLabel: UILabel!
    @IBOutlet var handlebarView: UIView!
    @IBOutlet var visualEffectsView: UIVisualEffectView!
    @IBOutlet var headerStackView: UIStackView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var bottomHandlebarView: UIView!
    @IBOutlet var headerSpacerView: UIView!
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    
    /// The delegate to be notified of FloatingPanelViewControllerDelegate events.
    var delegate: FloatingPanelViewControllerDelegate?
    
    /// The "partial height" vertical size of the floating panel view controller.
    var partialHeight: CGFloat = 0
    
    // Returns the user-specified height or a calculated default value.
    internal var internalPartialHeight: CGFloat {
        return partialHeight > 0 ? partialHeight : maximumHeight * 0.40
    }

    private var minimumHeight: CGFloat {
        return headerStackView.frame.origin.y + headerStackView.frame.size.height
    }
    
    private var maximumHeight: CGFloat {
        if let superview = view.superview {
            return superview.frame.height - edgeInsets.top - edgeInsets.bottom
        }
        else {
            return 320
        }
    }
    
    /// The width of the floating panel.
    private let floatingPanelWidth: CGFloat = 320

    //TODO: check on other override of UIView.transiation (or maybe UIView.animate) that uses "Springs", to get cool
    // rubberbanding effect.  Look at GitHub repo (and maybe Nathan's code) for that.
    
    // TODO: make public the anchor which can be used to anchor movable content  (maybe not necessary if user can use the bottom of the floating panel vc.view)
    
    /// The vertical state of the floating panel.
    var state: FloatingPanelState = .partial {
        didSet {
            var newConstant: CGFloat = 0
            switch state {
            case .minimized:
                newConstant = minimumHeight
            case .partial:
                newConstant = internalPartialHeight
            case .full:
                newConstant = maximumHeight
            }
            
            // Animate to the new vertical state.
            animateResizableConstrant(newConstant)
        }
    }
    
    /// Determines whether the close button is hidden or not.
    var closeButtonHidden: Bool = false {
        didSet {
            closeButton.isHidden = closeButtonHidden
        }
    }
    
    /// Determines whether to allow user to resize the floating panel.
    var allowManualResize = true {
        didSet {
            handlebarView.isHidden = !allowManualResize && !isCompactWidth
            bottomHandlebarView.isHidden = !allowManualResize && isCompactWidth
            panGestureRecognizer.isEnabled = allowManualResize
        }
    }
    
    /// The image to display in the header.
    var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = (image == nil)
        }
    }
    
    /// The title to display in the header.
    var floatingPanelTitle: String? {
        didSet {
            let _ = view // Make sure we're loaded...
            titleLabel.text = floatingPanelTitle
            titleLabel.isHidden = floatingPanelTitle?.isEmpty ?? true
        }
    }
    
    /// The subtitle to display in the header.
    var floatingPanelSubtitle: String? {
        didSet {
            subTitleLabel.text = floatingPanelSubtitle
            subTitleLabel.isHidden = floatingPanelSubtitle?.isEmpty ?? true
        }
    }
    
    /// The view controller to display in the content area of the floating panel view controller.
    var initialViewController: UIViewController? {
        didSet {
            if let viewController = initialViewController {
                let _ = view // Make sure we're loaded...
                addChild(viewController)
                contentView.addSubview(viewController.view)
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    viewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    viewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    viewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                    viewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
            }
        }
    }
    
    /// The constraint used by the gesture to resize the floating panel view.
    internal var resizeableLayoutConstraint = NSLayoutConstraint()
    internal var initialResizableLayoutConstraintConstant: CGFloat = 0.0
    
    /// The insets from the edge of the screen for both compact and regular layouts.
    /// The client can override the insets for various layout options.
    var regularWidthInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    var compactWidthInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    /// The edge insets for the current layout.
    var edgeInsets: UIEdgeInsets {
        return isCompactWidth ? compactWidthInsets : regularWidthInsets
    }
    
    /// Denotes whether the floating panel view controller is being displayed in
    /// a compact width layout.
    internal var isCompactWidth: Bool = false {
        didSet {
            handlebarView.isHidden = !isCompactWidth
            bottomHandlebarView.isHidden = isCompactWidth
            
            updateInterfaceForCurrentTraits()
            
            // Set corner masks
            view.layer.maskedCorners = isCompactWidth ?
                [.layerMinXMinYCorner, .layerMaxXMinYCorner] :
                [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
    }
    
    private var initialized = false
    
    private var regularWidthConstraints = [NSLayoutConstraint]()
    private var compactWidthConstraints = [NSLayoutConstraint]()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        isCompactWidth = traitCollection.horizontalSizeClass == .compact
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Skip if already initialized or we don't have a superview.
        guard !initialized, let superview = view.superview else { return }
        
        // Enable the panGesture if manual resize is allowed.
        panGestureRecognizer.isEnabled = allowManualResize
        
        // Set the resizable constraint used by the panGestureRecognizer to resize the panel.
        resizeableLayoutConstraint = view.heightAnchor.constraint(equalToConstant: internalPartialHeight)
        resizeableLayoutConstraint.priority = .defaultLow

        // Define the constraints used for a regular-width layout.
        regularWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: regularWidthInsets.left),
            view.widthAnchor.constraint(equalToConstant: floatingPanelWidth),
            view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: regularWidthInsets.top),
            view.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -regularWidthInsets.bottom),

            bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerSpacerView.bottomAnchor),

            resizeableLayoutConstraint
        ]

        // Define the constraints used for a compact-width layout.
        compactWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: compactWidthInsets.left),
            view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: compactWidthInsets.right),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: compactWidthInsets.bottom),
            
            view.topAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.topAnchor, constant: compactWidthInsets.top),
            
            headerSpacerView.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor/*, constant: compactWidthInsets.bottom*/),
            
            resizeableLayoutConstraint
        ]

        initialized = true
        updateInterfaceForCurrentTraits()
    }
    
    // Update constrains for current horizontal layout.
    private func updateInterfaceForCurrentTraits() {
        NSLayoutConstraint.deactivate(regularWidthConstraints)
        NSLayoutConstraint.deactivate(compactWidthConstraints);
                
        NSLayoutConstraint.activate(isCompactWidth ? compactWidthConstraints : regularWidthConstraints);
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        delegate?.userDidRequestDismissFloatingPanel(self)
    }

    // Handles the pan gesture.
    @IBAction func handlePanGesture(_ gestureRecognizer : UIPanGestureRecognizer) {
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview)

        if gestureRecognizer.state == .began {
            // Save the view's original constant.
            initialResizableLayoutConstraintConstant = resizeableLayoutConstraint.constant
        }
        
        // velocity will be used to determine whether to handle
        // the 'flick' gesture to switch between states
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview)
        if gestureRecognizer.state == .ended {
            if abs(velocity.y) > 0 {
                handleFlick(velocity);
            }
            else if resizeableLayoutConstraint.constant < minimumHeight {
                state = .minimized
            }
            else if resizeableLayoutConstraint.constant > maximumHeight {
                state = .full
            }
            else {
                state = .partial
            }
        }
        else if gestureRecognizer.state != .cancelled {
            // Calculate the new constraint constant, based on changes from the initial constant.
            var newConstant = initialResizableLayoutConstraintConstant + (isCompactWidth ? -translation.y : translation.y)
            
            // Limit the constant to be within min/max.
            newConstant = max(minimumHeight, newConstant)
            newConstant = min(maximumHeight, newConstant)

            // Set the new constant on the resizable constraint.
            resizeableLayoutConstraint.constant = newConstant
        }
        else {
            // On cancellation, animate the panel height to its original size.
            animateResizableConstrant(initialResizableLayoutConstraintConstant)
        }
    }
    
    /// Handles resizing the panel when the user resizes via a "flick".
    /// - Parameter velocity: The velocity of the gesture.
    public func handleFlick(_ velocity: CGPoint) {
        if isCompactWidth {
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraing constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
            else {
                // The user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraing constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
        }
        else {
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraing constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
            else {
                // The user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraing constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        isCompactWidth = traitCollection.horizontalSizeClass == .compact
    }
    
    private func animateResizableConstrant(_ newConstant: CGFloat) {
        guard let superview = view.superview else { return }
        // Complete all pending layout operations.
        superview.layoutIfNeeded()

        // Animate the transition to the new constraint constant value.
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 25,
                       options: [.layoutSubviews, .curveEaseInOut],
                       animations: { [weak self] in
                        self?.resizeableLayoutConstraint.constant = newConstant
                        self?.view.setNeedsUpdateConstraints()
                        superview.layoutIfNeeded()
        })
    }
}
