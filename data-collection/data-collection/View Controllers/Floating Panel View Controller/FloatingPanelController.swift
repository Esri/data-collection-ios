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

/// Defines the vertical state of the floating panel controller.
@objc
public enum FloatingPanelState: Int {
    /// The floating panel is displayed at its minimum height.
    case minimized
    /// The floating panel is displayed at a height roughly 40% of the screen.
    /// The actual value is user-customizable.
    case partial
    /// The floating panel is displayed at its maximum height.
    case full
}

/// Defines the transition direction for the view controller content navigation animation.
public enum TransitionDirection: Int {
    /// The transition push animation happens from right to left (the new view
    /// slides in from the right).  The pop animation is the reverse.
    case horizontal
    /// The transition push animation happens from bottom to top (the new view
    /// slides up from the bottom).  The pop animation is the reverse.
    case vertical
}

/// `FloatingPanelItem` dictates the appearance of a `FloatingPanelController`.
public class FloatingPanelItem : NSObject {
    /// The title to display in the header.
    @objc
    dynamic var title: String?
    
    /// The subtitle to display in the header.
    @objc
    dynamic var subtitle: String?
    
    /// The image to display in the header.
    @objc
    dynamic var image: UIImage?
    
    /// Determines whether the close button is hidden or not.
    @objc
    dynamic var closeButtonHidden: Bool = false
    
    /// The vertical size of the floating panel view controller used
    /// when the `FloatingPanelState` is set to `.partial`.
    @objc
    dynamic var partialHeight: CGFloat = FloatingPanelController.automaticDimension
    
    /// The state representing the vertical size of the floating panel.
    @objc
    dynamic var verticalState: FloatingPanelState = .partial
    
    /// The visibility of the floating panel header view.
    @objc
    dynamic var headerHidden: Bool = false
    
    /// Determines whether the user can manually resize the floating panel view controller.
    @objc
    dynamic var allowManualResize: Bool = true
}

/// The protocol implemented to respond to floating panel view controller events.
protocol FloatingPanelControllerDelegate: AnyObject {
    /// Tells the delegate that the user has requested to dismiss the floating panel view controller.
    /// - Parameter FloatingPanelController: The floating panel view controller to dismiss.
    func userDidRequestDismissFloatingPanel(_ floatingPanelController: FloatingPanelController)
}

/// Protocol used by a `UIViewController` embedded in a `FloatingPanelController`
/// if the embedded controller needs to modify some floating panel properties.
protocol FloatingPanelEmbeddable: UIViewController {
    /// The `FloatingPanelItem` used to access and change certain
    /// floating panel view controller properties.
    var floatingPanelItem: FloatingPanelItem { get }
}

/// A floating panel is a view that overlays a view and supplies view-related
/// content. For a map view, for instance, it could display a legend, bookmarks, search results, etc..
/// Apple Maps, Google Maps, Windows 10, and Collector have floating panel
/// implementations, sometimes referred to as a "bottom sheet".
///
/// Floating Panels are non-modal and can be transient, only displaying
/// information for a short period of time like identify results,
/// or persistent, where the information is always displayed, for example a
/// dedicated search panel. They will also be primarily simple containers
/// that clients will fill with their own content. However, the
/// `FloatingPanelController` will contain a basic set of optional UI elements
/// for displaying a title, subtitle, image, close button and other common
/// items as a convenience to the client.
public class FloatingPanelController: UIViewController {
    /// Denotes that the partial height of the floating panel should be calculated automatically.
    static let automaticDimension: CGFloat = 0.0
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet fileprivate var headerView: UIView!
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var topHandlebarView: UIView!
    @IBOutlet private var bottomHandlebarView: UIView!
    @IBOutlet private var panGestureRecognizer: UIPanGestureRecognizer!
    
    /// The transition direction for push/pop navigation animation.
    public var transitionDirection: TransitionDirection = .horizontal
    
    /// The delegate to be notified of FloatingPanelControllerDelegate events.
    weak var delegate: FloatingPanelControllerDelegate?
    
    /// Returns the user-specified partial height or a calculated default value.
    private var internalPartialHeight: CGFloat {
        return (currentFloatingPanelItem.partialHeight == FloatingPanelController.automaticDimension) ? maximumHeight * 0.40 : currentFloatingPanelItem.partialHeight
    }
    
    /// The minimum height of the floating panel, taking into account the
    /// horizontal size class.
    private var minimumHeight: CGFloat {
        let headerBottom = headerView.frame.minY + headerView.frame.height
        let handlebarHeight = bottomHandlebarView.frame.height
        
        // For compactWidth, handlebar is on top, so headerBottom is the limit.
        // For regularWidth, handlebar is on bottom, so we need to add that to handlebarHeight.
        var height = headerBottom
        if !isCompactWidth && allowManualResize {
            height += handlebarHeight
        }
        return height
    }
    
    /// The maximum height of the floating panel, taking into account the edge insets.
    private var maximumHeight: CGFloat {
        let edgeInsets = isCompactWidth ? compactWidthInsets : regularWidthInsets
        return view.superview?.frame.inset(by: edgeInsets).height ?? 320
    }
    
    /// The width of the floating panel for regular width size class scenarios.
    static internal let floatingPanelWidth: CGFloat = 320
    
    /// The vertical state of the floating panel.  When changed, the
    /// floating panel will animate to the new state.
    /// - Parameter animated: Denotes whether to animate to the new view height
    /// resulting from the change in state.
    private func stateDidChange(animated: Bool = true) {
        let updatedConstraintConstant: CGFloat
        switch currentFloatingPanelItem.verticalState {
        case .minimized:
            updatedConstraintConstant = minimumHeight
        case .partial:
            updatedConstraintConstant = internalPartialHeight
        case .full:
            updatedConstraintConstant = maximumHeight
        }
        
        if animated {
            // Animate to the new vertical state.
            animateResizableConstraint(updatedConstraintConstant)
        }
        else {
            resizeableLayoutConstraint.constant = updatedConstraintConstant
        }
    }
    
    private func updateHeaderViewVisibility() {
        headerView.isHidden = headerViewHidden
    }
    
    /// Determines whether the header view, comprising the image, title,
    /// subtitle and close button is hidden or not.
    /// Defaults to `false`.
    private var headerViewHidden: Bool = false {
        didSet {
            guard isViewLoaded else { return }
            updateHeaderViewVisibility()
        }
    }
    
    /// Updates the handlebar visibility based on horizontal size class
    /// and the value of `allowManualResize`.
    private func updateHandlebarVisibility() {
        topHandlebarView.isHidden = !allowManualResize || !isCompactWidth
        bottomHandlebarView.isHidden = !allowManualResize || isCompactWidth
    }
    
    private func updateAllowManualResize() {
        updateHandlebarVisibility()
        panGestureRecognizer.isEnabled = allowManualResize
    }
    
    /// Determines whether the floating panel is resizable via user interaction.
    /// Defaults to `true`.
    private var allowManualResize = true {
        didSet {
            guard isViewLoaded else { return }
            updateAllowManualResize()
        }
    }
    private var partialHeightObservation: NSKeyValueObservation?
    private var stateObservation: NSKeyValueObservation?
    private var headerHiddenObservation: NSKeyValueObservation?
    private var allowManualResizeObservation: NSKeyValueObservation?
    private var currentFloatingPanelItem = FloatingPanelItem() {
        didSet {
            partialHeightObservation = currentFloatingPanelItem.observe(\.partialHeight) { [weak self] (_, _) in
                DispatchQueue.main.async {
                    self?.stateDidChange(animated: true)
                }
            }
            
            stateObservation = currentFloatingPanelItem.observe(\.verticalState, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    self?.stateDidChange(animated: true)
                }
            }
            
            headerHiddenObservation = currentFloatingPanelItem.observe(\.headerHidden) { [weak self] (_, _) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.headerViewHidden = self.currentFloatingPanelItem.headerHidden
                }
            }
            
            allowManualResizeObservation = currentFloatingPanelItem.observe(\.allowManualResize) { [weak self] (_, _) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.allowManualResize = self.currentFloatingPanelItem.allowManualResize
                }
            }
            
            // Finally, set the header nav controller's floating panel item:
            (headerNavigationController.topViewController as? FloatingPanelHeaderController)?.floatingPanelItem = currentFloatingPanelItem
        }
    }
    
    /// The initial view controller to display in the content area of
    /// the floating panel view controller.
    private(set) var initialViewController: FloatingPanelEmbeddable? {
        willSet {
            guard let viewController = initialViewController else { return }
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }
        didSet {
            guard let viewController = initialViewController else { return }
            
            // Make sure we're loaded...
            loadViewIfNeeded()
            let previousFloatingPanelItem = (contentNavigationController.topViewController as? FloatingPanelEmbeddable)?.floatingPanelItem
            // Set the view controllers to be just our initial view controller.
            contentNavigationController.setViewControllers([viewController], animated: false)
            
            // If we already displaying a content view controller,
            // set the state of the new view controller to match.
            if let floatingPanelItem = previousFloatingPanelItem {
                viewController.floatingPanelItem.verticalState = floatingPanelItem.verticalState
            }
            
            // Create the initial header view controller and set it
            // on the header navigation controller.
            let headerViewController = instantiateHeaderViewController(for: viewController.floatingPanelItem)
            headerNavigationController.setViewControllers([headerViewController], animated: false)
        }
    }
    
    /// Creates and sets up the floating panel header view controller.
    /// - Parameter floatingPanelItem: The `FloatingPanelItem` containing the header information.
    /// - Returns: The new header view controller.
    private func instantiateHeaderViewController(for floatingPanelItem: FloatingPanelItem) -> FloatingPanelHeaderController {
        let headerViewController = FloatingPanelHeaderController.instantiate()
        headerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        headerViewController.floatingPanelItem = floatingPanelItem
        
        headerViewController.closeButtonHandler = { [weak self] in
            guard let self = self else { return }
            if self.contentNavigationController.topViewController == self.contentNavigationController.viewControllers.first {
                // We're showing the "root" view controller, user requested dismiss.
                self.delegate?.userDidRequestDismissFloatingPanel(self)
            }
            else {
                // We're showing pushed view controller, pop it and the header vc.
                _ = self.contentNavigationController.popViewController(animated: true)
            }
        }
        
        return headerViewController
    }
    
    /// The constraint used by the gesture to resize the floating panel view.
    private var resizeableLayoutConstraint: NSLayoutConstraint!
    
    /// The `resizableLayoutConstraint` constant at the beginning of
    /// user interaction; used to reset the constant in the event the
    /// user cancels the gesture.
    private var initialResizableLayoutConstraintConstant: CGFloat = 0.0
    
    /// The insets from the edge of the screen for the regular width size class.
    /// Defaults to `8.0, 8.0, 8.0, 8.0`
    private(set) var regularWidthInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    
    /// The insets from the edge of the screen for the compact width size class.
    /// Defaults to `8.0, 0.0, 0.0, 0.0`
    private(set) var compactWidthInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    /// Denotes whether the floating panel view controller is being displayed in
    /// a compact width layout.
    private var isCompactWidth: Bool {
        return traitCollection.horizontalSizeClass == .compact
    }
    
    /// Determines whether we've initialized the initial layout constraints.
    private var layoutConstraintsInitialized = false
    
    private var internalRegularWidthConstraints = [NSLayoutConstraint]()
    
    /// Constraints for the regular width size class.  These will be set
    /// from the `presentFloatingPanel` method in the UIViewController extension.
    var regularWidthConstraints = [NSLayoutConstraint]() {
        didSet {
            setupConstraints()
        }
    }
    
    private var internalCompactWidthConstraints = [NSLayoutConstraint]()
    
    /// Constraints for the compact width size class.  These will be set
    /// from the `presentFloatingPanel` method in the UIViewController extension.
    var compactWidthConstraints = [NSLayoutConstraint]() {
        didSet {
            setupConstraints()
        }
    }
    
    /// Constraints for the header.
    private var headerConstraints = [NSLayoutConstraint]()
    
    private let contentNavigationController = FloatingPanelNavigationController()
    private let headerNavigationController = UINavigationController()
    
    /// Add our internal header navigation controller to the `headerView`.
    private func setupHeaderNavigationController() {
        headerNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        headerNavigationController.view.backgroundColor = .gray
        addChild(headerNavigationController)
        headerView.addSubview(headerNavigationController.view)
        NSLayoutConstraint.activate([
            headerNavigationController.view.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerNavigationController.view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerNavigationController.view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerNavigationController.view.leadingAnchor.constraint(equalTo: headerView.leadingAnchor)
        ])
        headerNavigationController.navigationBar.isHidden = true
        headerNavigationController.delegate = self
        headerNavigationController.didMove(toParent: self)
    }
    
    /// Add our internal content navigation controller to the `contentView`.
    private func setupContentNavigationController() {
        contentNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(contentNavigationController)
        contentView.addSubview(contentNavigationController.view)
        NSLayoutConstraint.activate([
            contentNavigationController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentNavigationController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentNavigationController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentNavigationController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        contentNavigationController.navigationBar.isHidden = true
        contentNavigationController.delegate = self
        contentNavigationController.didMove(toParent: self)
        
        contentNavigationController.parentFloatingPanel = self
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Set clipToBounds = true so that the rounded corner masks will work.
        view.clipsToBounds = true
        
        setupContentNavigationController()
        setupHeaderNavigationController()
        
        contentNavigationController.headerNavigationController = headerNavigationController
        contentNavigationController.createHeaderViewControllerHandler = { [weak self] (floatingPanelEmbeddable: FloatingPanelEmbeddable) in
            return self?.instantiateHeaderViewController(for: floatingPanelEmbeddable.floatingPanelItem)
        }
        
        traitCollectionDidChange(traitCollection)
    }
    
    override public func removeFromParent() {
        super.removeFromParent()
        NSLayoutConstraint.deactivate(internalRegularWidthConstraints)
        NSLayoutConstraint.deactivate(internalCompactWidthConstraints)
        layoutConstraintsInitialized = false
    }
    
    /// Instantiates a `FloatingPanelController` from the storyboard.
    /// - Returns: A `FloatingPanelController`.
    /// - Parameters:
    ///   - initialViewController: The initial view controller to display.
    ///   - regularWidthInsets: The UIEdgeInsets used in a regular width horizontal size class.
    ///   - compactWidthInsets: The UIEdgeInsets used in a compact width horizontal size class.
    static func instantiate(_ initialViewController: FloatingPanelEmbeddable,
                            regularWidthInsets: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0),
                            compactWidthInsets: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)) -> FloatingPanelController {
        // Get the storyboard for the FloatingPanelController.
        let storyboard = UIStoryboard(name: "FloatingPanelController", bundle: .main)
        // Instantiate the FloatingPanelController.
        let floatingPanelController = storyboard.instantiateInitialViewController() as! FloatingPanelController
        floatingPanelController.initialViewController = initialViewController
        floatingPanelController.regularWidthInsets = regularWidthInsets
        floatingPanelController.compactWidthInsets = compactWidthInsets
        return floatingPanelController
    }
    
    /// Sets up the constraints for both regular and compact horizontal size classes.
    private func setupConstraints() {
        // Deactivate existing constraints so we don't end up with duplicates...
        NSLayoutConstraint.deactivate(internalRegularWidthConstraints)
        NSLayoutConstraint.deactivate(internalCompactWidthConstraints)
        
        // Set the resizable constraint used by the panGestureRecognizer to resize the panel.
        resizeableLayoutConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        resizeableLayoutConstraint.priority = .defaultLow
        
        // Get the constraints used for a compact and regular-width layouts.
        internalRegularWidthConstraints = regularWidthConstraints
        internalRegularWidthConstraints.append(contentsOf: [
            bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerView.bottomAnchor),
            resizeableLayoutConstraint
        ])
        
        internalCompactWidthConstraints = compactWidthConstraints
        internalCompactWidthConstraints.append(resizeableLayoutConstraint)
        
        // This will activate the appropriate set of constraints.
        updateInterfaceForCurrentTraits()
        
        // stateDidChange will update the resizableLayoutConstraint
        // constant based on the current state.
        stateDidChange(animated: false)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Skip if already initialized.
        guard !layoutConstraintsInitialized else { return }
        setupConstraints()
        layoutConstraintsInitialized = true
    }
    
    /// Update constraints for current horizontal size class.
    private func updateInterfaceForCurrentTraits() {
        NSLayoutConstraint.deactivate(internalRegularWidthConstraints)
        NSLayoutConstraint.deactivate(internalCompactWidthConstraints)
        
        NSLayoutConstraint.activate(isCompactWidth ? internalCompactWidthConstraints : internalRegularWidthConstraints)
    }
    
    /// Handles the pan gesture used to resize the floating panel.
    /// - Parameter gestureRecognizer: The active gesture recognizer.
    @IBAction private func handlePanGesture(_ gestureRecognizer : UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            // Save the view's original constant.
            initialResizableLayoutConstraintConstant = resizeableLayoutConstraint.constant
        case .ended:
            // Velocity will be used to determine whether to handle
            // the 'flick' gesture to switch between states.
            let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview)
            if velocity.y.magnitude > 0 {
                handleFlick(velocity)
            }
            else if resizeableLayoutConstraint.constant < minimumHeight {
                // Constraint is less than minimum.
                currentFloatingPanelItem.verticalState = .minimized
            }
            else if resizeableLayoutConstraint.constant > maximumHeight {
                // Constraint is greater than maximum.
                currentFloatingPanelItem.verticalState = .full
            }
            else {
                currentFloatingPanelItem.verticalState = .partial
            }
        case .cancelled:
            // On cancellation, animate the panel height to its original size.
            animateResizableConstraint(initialResizableLayoutConstraintConstant)
        default:
            // Get the changes in the X and Y directions relative to
            // the superview's coordinate space.
            let translation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview)
            
            // Calculate the new constraint constant, based on changes from the initial constant.
            var newConstant = initialResizableLayoutConstraintConstant + (isCompactWidth ? -translation.y : translation.y)
            
            // Limit the constant to be within min/max.
            newConstant = max(minimumHeight, newConstant)
            newConstant = min(maximumHeight, newConstant)
            
            // Set the new constant on the resizable constraint.
            resizeableLayoutConstraint.constant = newConstant
        }
    }
    
    /// Handles resizing the panel when the user resizes via a "flick".
    /// - Parameter velocity: The velocity of the gesture.
    private func handleFlick(_ velocity: CGPoint) {
        if isCompactWidth {
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraint constant value.
                currentFloatingPanelItem.verticalState = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
            else {
                // The user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraint constant value.
                currentFloatingPanelItem.verticalState = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
        }
        else {
            // Regular width size class.
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraint constant value.
                currentFloatingPanelItem.verticalState = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
            else {
                // The user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraint constant value.
                currentFloatingPanelItem.verticalState = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Enable the correct handlebar (top vs. bottom) for the current layout.
        updateHandlebarVisibility()
        updateInterfaceForCurrentTraits()
        
        // Set corner masks
        var maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        if !isCompactWidth {
            maskedCorners.formUnion([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        }
        view.layer.maskedCorners = maskedCorners
    }
    
    /// Animates the resizable constraint to the new constant value.
    /// - Parameter newConstant: The constraints new constant.
    private func animateResizableConstraint(_ newConstant: CGFloat) {
        guard let superview = view.superview else { return }
        
        // Complete all pending layout operations.
        superview.layoutIfNeeded()
        
        // Animate the transition to the new constraint constant value.
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 25,
                       options: [.layoutSubviews, .curveEaseInOut],
                       animations: {
                        self.resizeableLayoutConstraint.constant = newConstant
                        self.contentView?.alpha = (self.currentFloatingPanelItem.verticalState == .minimized ? 0.0 : 1.0)
                        self.view.setNeedsUpdateConstraints()
                        superview.layoutIfNeeded()
                       })
    }
    
    /// For some reason, the first time the initial view controller is set there
    /// are two calls to `navigationController(_:didShow:animated:)`.
    /// The second call messes up the logic for which header view controller to show.
    /// Adding a check for `animating` prevents the second call from happening.
    fileprivate var animating = false
}

private let transitionAnimationDuration: TimeInterval = 0.5

/// The class handling push transition animations for the content navigation controller.
fileprivate class PushTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    private var transitionDirection: TransitionDirection = .horizontal
    convenience init(_ transitionDirection: TransitionDirection) {
        self.init()
        self.transitionDirection = transitionDirection
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        
        let finalFrame: CGRect
        switch transitionDirection {
        case .horizontal:
            finalFrame = finalFrameForVC.offsetBy(dx: finalFrameForVC.width, dy: 0)
        case .vertical:
            finalFrame = finalFrameForVC.offsetBy(dx: 0, dy: finalFrameForVC.height)
        }
        toViewController.view.frame = finalFrame
        containerView.addSubview(toViewController.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromViewController.view.alpha = 0.5
            toViewController.view.frame = finalFrameForVC
        }) { finished in
            transitionContext.completeTransition(finished)
            fromViewController.view.alpha = 1.0
        }
    }
}

/// The class handling pop transition animations for the content navigation controller.
fileprivate class PopTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    private var transitionDirection: TransitionDirection = .horizontal
    convenience init(_ transitionDirection: TransitionDirection) {
        self.init()
        self.transitionDirection = transitionDirection
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        
        toViewController.view.frame = finalFrameForVC
        toViewController.view.alpha = 0.5
        containerView.addSubview(toViewController.view)
        containerView.addSubview(fromViewController.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.alpha = 1.0
            
            let finalFrame: CGRect
            switch self.transitionDirection {
            case .horizontal:
                finalFrame = finalFrameForVC.offsetBy(dx: finalFrameForVC.width, dy: 0)
            case .vertical:
                finalFrame = finalFrameForVC.offsetBy(dx: 0, dy: finalFrameForVC.height)
            }
            
            fromViewController.view.frame = finalFrame
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}

/// The class handling push transition animations for the header navigation controller.
fileprivate class HeaderPushTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        
        toViewController.view.frame = finalFrameForVC
        toViewController.view.alpha = 0.0
        containerView.addSubview(toViewController.view)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.alpha = 1.0
        }) { finished in
            transitionContext.completeTransition(finished)
            fromViewController.view.alpha = 1.0
        }
    }
}

/// The class handling pop transition animations for the header navigation controller.
fileprivate class HeaderPopTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let snapshot = fromViewController.view.snapshotView(afterScreenUpdates: false) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        
        containerView.addSubview(toViewController.view)
        containerView.addSubview(snapshot)
        containerView.sendSubviewToBack(fromViewController.view)
        
        snapshot.frame = finalFrameForVC
        
        NSLayoutConstraint.activate([
            toViewController.view.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 1.0),
            toViewController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0),
        ])
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.alpha = 1.0
            snapshot.alpha = 0.0
        }) { finished in
            transitionContext.completeTransition(finished)
            snapshot.removeFromSuperview()
        }
    }
}

extension FloatingPanelController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Set the appropriate push/pop animation for the content/header view controller.
        let animatedTransitioning: UIViewControllerAnimatedTransitioning
        if navigationController == headerNavigationController {
            animatedTransitioning = operation == .pop ? HeaderPopTransitionAnimation() : HeaderPushTransitionAnimation()
        }
        else {
            animatedTransitioning = operation == .pop ? PopTransitionAnimation(transitionDirection) : PushTransitionAnimation(transitionDirection)
        }
        return animatedTransitioning
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // If we're showing the header navigation controller, set
        // the constraints to properly size the displayed view controller.
        if navigationController == headerNavigationController {
            viewController.view.layoutSubviews()
            NSLayoutConstraint.activate([
                viewController.view.heightAnchor.constraint(equalTo: headerNavigationController.view.heightAnchor, multiplier: 1.0),
                viewController.view.widthAnchor.constraint(equalTo: headerNavigationController.view.widthAnchor, multiplier: 1.0)
            ])
        }
        
        // Setup FloatingPanelItem if we transitioned with the floatingPanelNavigationController
        guard navigationController == contentNavigationController, let floatingPanelItem = (viewController as? FloatingPanelEmbeddable)?.floatingPanelItem else { return }
        self.currentFloatingPanelItem = floatingPanelItem
    }
}

/// A subclass of `UINavigationController` used by the floating panel to
/// automatically display the header representing the displayed
/// view controller's floating panel item.
fileprivate class FloatingPanelNavigationController: UINavigationController {
    typealias CreateHeaderViewControllerHandler = (FloatingPanelEmbeddable) -> UIViewController?
    
    /// The header navigation controller which displays the header view controller
    var headerNavigationController: UINavigationController?
    
    /// The handler used to create the header view controller to display.
    var createHeaderViewControllerHandler: CreateHeaderViewControllerHandler?
    
    weak var parentFloatingPanel: FloatingPanelController?
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        
        guard let headerNavVC = headerNavigationController,
              let fpEmbeddable = viewController as? FloatingPanelEmbeddable,
              let newHeaderVC = createHeaderViewControllerHandler?(fpEmbeddable) else { return }
        
        // Push our newly created headerVC.
        headerNavVC.pushViewController(newHeaderVC, animated: animated)
        headerNavVC.view.layoutSubviews()
        NSLayoutConstraint.activate([
            headerNavVC.view.heightAnchor.constraint(equalTo: headerNavVC.topViewController!.view.heightAnchor, multiplier: 1.0),
            headerNavVC.view.widthAnchor.constraint(equalTo: headerNavVC.topViewController!.view.widthAnchor, multiplier: 1.0)
        ])
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        var returnVC: UIViewController?
        if topViewController == viewControllers.first {
            // We're showing the "root" view controller, user requested dismiss.
            if let controller = parentFloatingPanel {
                controller.delegate?.userDidRequestDismissFloatingPanel(controller)
            }
            returnVC = nil
        }
        else {
            returnVC = super.popViewController(animated: animated)
            headerNavigationController?.popViewController(animated: animated)
        }
        
        return returnVC
    }
}

/// An extension allowing view controllers to easily present and dismiss a floating panel.
extension UIViewController {
    /// The presented floating panel controller.  This will be nil
    /// until `presentInFloatingPanel` has been called.
    var floatingPanelController: FloatingPanelController? {
        children.first(where: { $0 is FloatingPanelController }) as? FloatingPanelController
    }
    
    /// Presents a `FloatingPanelController`.
    /// - Parameters:
    ///   - embeddable: The initial `FloatingPanelEmbeddable` view controller to display.
    ///   - regularWidthInsets: The UIEdgeInsets used in a regular width horizontal size class.
    ///   - compactWidthInsets: The UIEdgeInsets used in a compact width horizontal size class.
    func presentInFloatingPanel(_ embeddable: FloatingPanelEmbeddable,
                                regularWidthInsets: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0),
                                compactWidthInsets: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0)) {
        // First, dismiss the existing floating panel.
        dismissFloatingPanel()
        
        // Instantiate a new floating panel.
        let floatingPanel = FloatingPanelController.instantiate(embeddable,
                                                                regularWidthInsets: regularWidthInsets,
                                                                compactWidthInsets: compactWidthInsets)
        floatingPanel.delegate = self as? FloatingPanelControllerDelegate
        if traitCollection.horizontalSizeClass == .compact {
            floatingPanel.view.frame = floatingPanel.view.frame.offsetBy(
                dx: 0.0,
                dy: floatingPanel.view.frame.size.height
            )
        }
        else {
            floatingPanel.view.frame = floatingPanel.view.frame.offsetBy(
                dx: 0.0,
                dy: -floatingPanel.view.frame.size.height
            )
        }
        addChild(floatingPanel)
        view.addSubview(floatingPanel.view)
        floatingPanel.didMove(toParent: self)
        floatingPanel.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Set the constraints needed to position the floating panel on the
        // left side of the screen, taking into account the size class insets.
        if let floatingPanelView = floatingPanel.view {
            floatingPanel.regularWidthConstraints = [
                floatingPanelView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: floatingPanel.regularWidthInsets.left),
                floatingPanelView.widthAnchor.constraint(equalToConstant: FloatingPanelController.floatingPanelWidth),
                floatingPanelView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: floatingPanel.regularWidthInsets.top),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: floatingPanelView.bottomAnchor, constant: floatingPanel.regularWidthInsets.bottom)
            ]
            
            floatingPanel.compactWidthConstraints = [
                floatingPanelView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: floatingPanel.compactWidthInsets.left),
                floatingPanelView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: floatingPanel.compactWidthInsets.right),
                floatingPanelView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: floatingPanel.compactWidthInsets.bottom),
                floatingPanelView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: floatingPanel.compactWidthInsets.top),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: floatingPanel.headerView.bottomAnchor, constant: floatingPanel.compactWidthInsets.bottom)
            ]
        }
    }
    
    /// Dismisses the `FloatingPanelController`.
    func dismissFloatingPanel() {
        guard let floatingPanel = floatingPanelController else { return }
        floatingPanel.willMove(toParent: nil)
        floatingPanel.view.removeFromSuperview()
        floatingPanel.removeFromParent()
    }
}
