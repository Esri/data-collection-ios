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

/// The protocol implemented to respond to floating panel view controller events.
public protocol FloatingPanelViewControllerDelegate: AnyObject {
    /// Tells the delegate that the user has requested to dismiss the floating panel view controller.
    ///
    /// - Parameter floatingPanelViewController: The floating panel view controller to dismiss.
    func userDidRequestDismissFloatingPanel(_ floatingPanelViewController: FloatingPanelViewController)
}

/// Defines the vertical state of the floating panel view controller.
public enum FloatingPanelState {
    /// The floating panel is displayed at its minimum height.
    case minimized
    /// The floating panel is displayed at a height roughly 40% of the screen.
    /// The actual value is user-customizable.
    case partial
    /// The floating panel is displayed at its maximum height.
    case full
}

/// A floating panel is a view that overlays a map view and supplies map-related
/// content such as a legend, bookmarks, search results, etc..
/// Apple Maps, Google Maps, Windows 10, and Collector have floating panel
/// implementations, sometimes referred to as a "bottom sheet".
///
/// Floating Panels are non-modal and can be transient, only displaying
/// information for a short period of time like identify results,
/// or persistent, where the information is always displayed, for example a
/// dedicated search panel. They will also be primarily simple containers
/// that clients will fill with their own content. However, the
/// FloatingPanelViewController will contain a basic set of optional UI elements
/// for displaying a title, subtitle, image, close button and other common
/// items as a convenience to the client.
public class FloatingPanelViewController: UIViewController {
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subTitleLabel: UILabel!
    
    @IBOutlet var topHandlebarView: UIView!
    @IBOutlet var bottomHandlebarView: UIView!

    @IBOutlet var headerStackView: UIStackView!
    @IBOutlet var titleStackView: UIStackView!
    @IBOutlet var subtitleStackView: UIStackView!

    @IBOutlet var imageStackView: UIStackView!
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!

    /// The delegate to be notified of FloatingPanelViewControllerDelegate events.
    public var delegate: FloatingPanelViewControllerDelegate?
    
    /// The vertical size of the floating panel view controller used
    /// when the `FloatingPanelState` is set to `.partial`
    public var partialHeight: CGFloat = 0
    
    // Returns the user-specified partial height or a calculated default value.
    private var internalPartialHeight: CGFloat {
        return partialHeight > 0 ? partialHeight : maximumHeight * 0.40
    }
    
    /// The minimum height of the floating panel, taking into account the
    /// horizontal size class.
    private var minimumHeight: CGFloat {
        let headerBottom = headerStackView.frame.origin.y + headerStackView.frame.size.height
        let handlerbarHeight = bottomHandlebarView.frame.height
        
        // For compactWidth, handlebar is on top, so headerBottom is the limit;
        // For regularWidth, handlebar is on bottom, so we need to add that.
        return isCompactWidth ? headerBottom : headerBottom + (allowManualResize ? handlerbarHeight : 0)
    }
    
    /// The maximum height of the floating panel, taking into account the edge insets.
    private var maximumHeight: CGFloat {
        if let superview = view.superview {
            return superview.frame.height - edgeInsets.top - edgeInsets.bottom
        }
        else {
            return 320
        }
    }
    
    /// The width of the floating panel for regular width size class scenarios.
    private let floatingPanelWidth: CGFloat = 320

    /// The vertical state of the floating panel.  When changed, the
    /// floating panel will animate to the new state.
    private func updateState(_ animate: Bool = true) {
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
        if animate {
            animateResizableConstrant(newConstant)
        }
        else {
            resizeableLayoutConstraint.constant = newConstant
        }
    }
    
    var state: FloatingPanelState = .partial {
        didSet {
            guard isViewLoaded else { return }
            updateState()
        }
    }
    
    /// Determines whether the header view, comprising the image, title,
    /// subtitle and close button is hidden or not.
    private func updateHeaderStackView() {
        headerStackView.isHidden = headerViewHidden
    }
    
    var headerViewHidden: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            updateHeaderStackView()
        }
    }
    
    /// Determines whether the close button is hidden or not.
    private func updateCloseButton() {
        closeButton.isHidden = closeButtonHidden
    }
    
    var closeButtonHidden: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            updateCloseButton()
        }
    }

    /// Determines whether the floating panel is resizable via user interaction.
    private func updateAllowManualResize() {
        updateHandlebarVisibility()
        panGestureRecognizer.isEnabled = allowManualResize
    }
    
    var allowManualResize = true {
        didSet {
            guard isViewLoaded else { return }
            updateAllowManualResize()
        }
    }
    
    /// The image to display in the header.
    private func updateImage() {
        imageView.image = image
        imageStackView.isHidden = (image == nil)
    }
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            updateImage()
        }
    }
    
    /// The title to display in the header.
    private func updateFloatingPanelTitle() {
        titleLabel.text = floatingPanelTitle
    }
    
    var floatingPanelTitle: String? {
        didSet {
            guard isViewLoaded else { return }
            updateFloatingPanelTitle()
        }
    }
    
    /// The subtitle to display in the header.
    private func updateFloatingPanelSubtitle() {
        subTitleLabel.text = floatingPanelSubtitle
    }
    
    var floatingPanelSubtitle: String? {
        didSet {
            guard isViewLoaded else { return }
            updateFloatingPanelSubtitle()
        }
    }
    
    /// The initial view controller to display in the content area of
    /// the floating panel view controller.
    public var initialViewController: UIViewController? {
        didSet {
            if let viewController = initialViewController {
                // Make sure we're loaded...
                loadViewIfNeeded()
                
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
    
    /// The `resizableLayoutConstraint` constant at the beginning of
    /// user interaction; used to reset the constant in the event the
    /// user cancels the gesture.
    internal var initialResizableLayoutConstraintConstant: CGFloat = 0.0
    
    // TODO: test changing the insets after things are setup
    // TODO: test setting title, subtitle, image, etc prior to displaying the panel to make sure the outlets are set up.
    
    /// The insets from the edge of the screen for the regular width size class.
    public var regularWidthInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0) {
        didSet {
            setupConstraints()
        }
    }

    /// The insets from the edge of the screen for the compact width size class.
    public var compactWidthInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0) {
           didSet {
               setupConstraints()
           }
       }
    
    /// The edge insets for the current layout.
    private var edgeInsets: UIEdgeInsets {
        return isCompactWidth ? compactWidthInsets : regularWidthInsets
    }
    
    /// Denotes whether the floating panel view controller is being displayed in
    /// a compact width layout.
    private var isCompactWidth: Bool = false {
        didSet {
            // Enable the correct handlebar (top vs. bottom) for the current layout.
            updateHandlebarVisibility()
            updateInterfaceForCurrentTraits()
            
            // Set corner masks
            view.layer.maskedCorners = isCompactWidth ?
                [.layerMinXMinYCorner, .layerMaxXMinYCorner] :
                [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
    }
    
    /// Determines whether we've initialized the initial layout constraints.
    private var initialized = false
    
    /// Constraints for the regular width size class.
    private var regularWidthConstraints = [NSLayoutConstraint]()

    /// Constraints for the compact width size class.
    private var compactWidthConstraints = [NSLayoutConstraint]()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false

        isCompactWidth = traitCollection.horizontalSizeClass == .compact

        // Initialize controls from properties that may have been set before
        // the view was loaded.
        updateImage()
        updateCloseButton()
        updateHeaderStackView()
        updateAllowManualResize()
        updateFloatingPanelTitle()
        updateFloatingPanelSubtitle()
    }
    
    /// Sets up the constrains for both regular and compact horizontal size classes.
    /// - Parameter superview: The superview of the floating panel.
    private func setupConstraints() {
        guard let superview = view.superview else { return }

        // Set the resizable constraint used by the panGestureRecognizer to resize the panel.
        resizeableLayoutConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        resizeableLayoutConstraint.priority = .defaultLow

        // updateState will update the resizableLayoutConstraint constant
        // based on the current state.
        updateState(false)
        
        // Define the constraints used for a regular-width layout.
        regularWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: regularWidthInsets.left),
            view.widthAnchor.constraint(equalToConstant: floatingPanelWidth),
            view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: regularWidthInsets.top),
            view.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -regularWidthInsets.bottom),
            
            bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerStackView.bottomAnchor),
            
            resizeableLayoutConstraint
        ]
        
        // Define the constraints used for a compact-width layout.
        compactWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: compactWidthInsets.left),
            view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: compactWidthInsets.right),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: compactWidthInsets.bottom),
            view.topAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.topAnchor, constant: compactWidthInsets.top),
            
            headerStackView.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -compactWidthInsets.bottom),
            
            resizeableLayoutConstraint
        ]
        
        // This will activate the appropriate set of constraints.
        updateInterfaceForCurrentTraits()
    }
    
    // TODO:  Test again and make sure things are OK in both apps; test setting edge insets and initializing properties prior to display.
    override public func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Skip if already initialized or we don't have a superview.
        guard !initialized else { return }
        setupConstraints()
        initialized = true
    }
    
    /// Update constraints for current horizontal size class.
    private func updateInterfaceForCurrentTraits() {
        NSLayoutConstraint.deactivate(regularWidthConstraints)
        NSLayoutConstraint.deactivate(compactWidthConstraints);
                
        NSLayoutConstraint.activate(isCompactWidth ? compactWidthConstraints : regularWidthConstraints);
    }
    
    /// Handles a user tap on the close button
    /// - Parameter sender: The button tapped.
    @IBAction func closeButtonAction(_ sender: Any) {
        delegate?.userDidRequestDismissFloatingPanel(self)
    }

    /// Handles the pan gesture used to resize the floating panel.
    /// - Parameter gestureRecognizer: The active gesture recognizer.
    @IBAction func handlePanGesture(_ gestureRecognizer : UIPanGestureRecognizer) {
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview)

        if gestureRecognizer.state == .began {
            // Save the view's original constant.
            initialResizableLayoutConstraintConstant = resizeableLayoutConstraint.constant
        }
        
        // Velocity will be used to determine whether to handle
        // the 'flick' gesture to switch between states.
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview)
        if gestureRecognizer.state == .ended {
            if abs(velocity.y) > 0 {
                handleFlick(velocity);
            }
            else if resizeableLayoutConstraint.constant < minimumHeight {
                // Constraint is less than minimum.
                state = .minimized
                resizeableLayoutConstraint.constant = minimumHeight
            }
            else if resizeableLayoutConstraint.constant > maximumHeight {
                // Constraint is greater than maximum.
                state = .full
                resizeableLayoutConstraint.constant = maximumHeight
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
    
    /// Updates the handlebar visibility based on horizontal size class
    /// and the value of `allowManualResize`.
    private func updateHandlebarVisibility() {
        topHandlebarView.isHidden = !allowManualResize || !isCompactWidth
        bottomHandlebarView.isHidden = !allowManualResize || isCompactWidth
    }

    /// Handles resizing the panel when the user resizes via a "flick".
    /// - Parameter velocity: The velocity of the gesture.
    private func handleFlick(_ velocity: CGPoint) {
        if isCompactWidth {
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraint constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
            else {
                // The user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraint constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
        }
        else {
            // Regular width size class.
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraint constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
            else {
                // The user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraint constant value.
                state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // The trait collection changed; set `isCompactWidth` based on the
        // new horizontal size class.
        isCompactWidth = traitCollection.horizontalSizeClass == .compact
    }
    
    /// Animates the resizable constraint to the new constant value.
    /// - Parameter newConstant: The constraints new constant.
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