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

/// `FloatingPanelItem` dictates the appearance of a `FloatingPanelViewController`.
public class FloatingPanelItem : NSObject {
    /// The title to display in the header.
    @objc
    dynamic var title: String?
    
    /// The subtitle to display in the header.
    @objc
    dynamic var subtitle: String?
    
    /// The image to display in the header.
    @objc
    dynamic var image: UIImage? = UIImage(named: "goose.png")
    
    /// Determines whether the close button is hidden or not.
    @objc
    dynamic var closeButtonHidden: Bool = false
    
    /// The vertical size of the floating panel view controller used
    /// when the `FloatingPanelState` is set to `.partial`.
    @objc
    dynamic var partialHeight: CGFloat = 0.0
    
    /// The state representing the vertical size of the floating panel.
    @objc
    dynamic var state: FloatingPanelViewController.State = .partial
    
    /// The visibility of the floating panel header view.
    @objc
    dynamic var headerHidden: Bool = false

}

/// The protocol implemented to respond to floating panel view controller events.
public protocol FloatingPanelViewControllerDelegate: AnyObject {
    /// Tells the delegate that the user has requested to dismiss the floating panel view controller.
    ///
    /// - Parameter floatingPanelViewController: The floating panel view controller to dismiss.
    func userDidRequestDismissFloatingPanel(_ floatingPanelViewController: FloatingPanelViewController)
}

/// Protocol used by a `UIViewController` embedded in a `FloatingPanelViewController`
/// if the embedded controller needs to modify some floating panel properties.
public protocol FloatingPanelEmbeddable: UIViewController {
    /// The `FloatingPanelItem` used to access and change certain
    /// floating panel view controller properties.
    var floatingPanelItem: FloatingPanelItem { get set }
}

/// Helper class used to embed a view controller in a `FloatingPanelViewController`.
public class FloatingPanelEmbeddableViewController: UIViewController, FloatingPanelEmbeddable {
    /// The `FloatingPanelItem` used to access and change certain
    /// floating panel view controller properties.
    lazy public var floatingPanelItem: FloatingPanelItem = {
        return FloatingPanelItem()
    }()
}

/// Helper class used to embed a table view controller in a `FloatingPanelViewController`.
public class FloatingPanelEmbeddableTableViewController: UITableViewController, FloatingPanelEmbeddable {
    /// The `FloatingPanelItem` used to access and change certain
    /// floating panel view controller properties.
    lazy public var floatingPanelItem: FloatingPanelItem = {
        return FloatingPanelItem()
    }()
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
    /// Defines the vertical state of the floating panel view controller.
    @objc
    public enum State: Int {
        /// The floating panel is displayed at its minimum height.
        case minimized
        /// The floating panel is displayed at a height roughly 40% of the screen.
        /// The actual value is user-customizable.
        case partial
        /// The floating panel is displayed at its maximum height.
        case full
    }
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var topHandlebarView: UIView!
    @IBOutlet private var bottomHandlebarView: UIView!
    @IBOutlet private var panGestureRecognizer: UIPanGestureRecognizer!

    /// The vertical size of the floating panel view controller used
    /// when the `FloatingPanelState` is set to `.partial`.
    /// The computed default is 40% of the maximum panel height.
    public lazy var partialHeight: CGFloat = {
        currentFloatingPanelItem.partialHeight
    }()
    
    /// The delegate to be notified of FloatingPanelViewControllerDelegate events.
    public var delegate: FloatingPanelViewControllerDelegate?
    
    /// Returns the user-specified partial height or a calculated default value.
    private var internalPartialHeight: CGFloat {
        return partialHeight > 0 ? partialHeight : maximumHeight * 0.40
    }
    
    /// The minimum height of the floating panel, taking into account the
    /// horizontal size class.
    private var minimumHeight: CGFloat {
        let headerBottom = headerView.frame.origin.y + headerView.frame.size.height
        let handlebarHeight = bottomHandlebarView.frame.height
        
        // For compactWidth, handlebar is on top, so headerBottom is the limit;
        // For regularWidth, handlebar is on bottom, so we need to add that.
        return isCompactWidth ? headerBottom : headerBottom + (allowManualResize ? handlebarHeight : 0)
    }
    
    /// The maximum height of the floating panel, taking into account the edge insets.
    private var maximumHeight: CGFloat {
        if let superview = view.superview {
            return superview.frame.height - internalEdgeInsets.top - internalEdgeInsets.bottom
        }
        else {
            return 320
        }
    }
    
    /// The width of the floating panel for regular width size class scenarios.
    private let floatingPanelWidth: CGFloat = 320

    /// The vertical state of the floating panel.  When changed, the
    /// floating panel will animate to the new state.
    fileprivate func updateState(_ animate: Bool = true) {
        var newConstant: CGFloat = 0
        switch currentFloatingPanelItem.state {
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
    
    /// Determines whether the header view, comprising the image, title,
    /// subtitle and close button is hidden or not.
    /// Defaults to `false`.
    private func updateHeaderView() {
        headerView.isHidden = headerViewHidden
        headerView.alpha = headerViewHidden ? 0 : 1
}
    
    /// Determines whether the header view, comprising the image, title,
    /// subtitle and close button is hidden or not.
    /// Defaults to `false`.
    public var headerViewHidden: Bool = false {
        didSet {
            // TODO: test this stuff and all the changes in the test app with a navigation controller and check the feasibility of this stuff.
            guard isViewLoaded else { return }
            updateHeaderView()
        }
    }
    
    private func updateAllowManualResize() {
        updateHandlebarVisibility()
        panGestureRecognizer.isEnabled = allowManualResize
    }
    
    /// Determines whether the floating panel is resizable via user interaction.
    /// Defaults to `true`.
    public var allowManualResize = true {
        didSet {
            guard isViewLoaded else { return }
            updateAllowManualResize()
        }
    }
    private var partialHeightObservation: NSKeyValueObservation?
    private var stateObservation: NSKeyValueObservation?
    private var headerHiddenObservation: NSKeyValueObservation?
    private var currentFloatingPanelItem = FloatingPanelItem() {
        didSet {
            partialHeightObservation = currentFloatingPanelItem.observe(\.partialHeight, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.partialHeight = self.currentFloatingPanelItem.partialHeight
                }
            }
            
            stateObservation = currentFloatingPanelItem.observe(\.state, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    self?.updateState(true)
                }
            }
            
            headerHiddenObservation = currentFloatingPanelItem.observe(\.headerHidden, options: [.new]) { [weak self] (_, change) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.headerViewHidden = self.currentFloatingPanelItem.headerHidden
                }
            }
        }
    }
    
    /// The initial view controller to display in the content area of
    /// the floating panel view controller.
    public var initialViewController: FloatingPanelEmbeddable? {
        willSet {
            if let viewController = initialViewController {
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
            }
        }
        didSet {
            if let viewController = initialViewController {
                // Make sure we're loaded...
                loadViewIfNeeded()
                
                contentNavigationController.setViewControllers([viewController], animated: true)
                // TODO: Maybe remove `floatingPanelItem` and make it a computed property which returns `currentFloatingPanelHeaderViewController.floatingPanelItem`
                currentFloatingPanelItem = viewController.floatingPanelItem
                
                let headerViewController = instantiateHeaderViewController(for: viewController)
                headerNavigationController.setViewControllers([headerViewController], animated: true)
                headerNavigationController.view.layoutSubviews()
                headerConstraints = [
                    headerNavigationController.view.heightAnchor.constraint(equalTo: headerViewController.view.heightAnchor, multiplier: 1.0),
                    headerViewController.view.widthAnchor.constraint(equalTo: headerNavigationController.view.widthAnchor, multiplier: 1.0)
                ]
                NSLayoutConstraint.activate(headerConstraints)
            }
        }
    }
    
    private func instantiateHeaderViewController(for fpEmbeddable: FloatingPanelEmbeddable) -> FloatingPanelHeaderViewController {
        let headerViewController = FloatingPanelHeaderViewController.instantiateFloatingPanelHeaderViewController()
        headerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        headerViewController.floatingPanelItem = fpEmbeddable.floatingPanelItem

        headerViewController.closeButtonHandler = { [weak self] in
            guard let self = self else { return }
            if self.contentNavigationController.topViewController == self.contentNavigationController.viewControllers.first {
                // We're showing the "root" view controller, user requested dismiss.
                self.delegate?.userDidRequestDismissFloatingPanel(self)
            }
            else {
                // We're showing pushed view controller, pop it and the header vc.
                let _ = self.contentNavigationController.popViewController(animated: true)
//                self.headerNavigationController.popViewController(animated: true)
            }
        }

        return headerViewController
    }
    
    /// The constraint used by the gesture to resize the floating panel view.
    private var resizeableLayoutConstraint = NSLayoutConstraint()
    
    /// The `resizableLayoutConstraint` constant at the beginning of
    /// user interaction; used to reset the constant in the event the
    /// user cancels the gesture.
    private var initialResizableLayoutConstraintConstant: CGFloat = 0.0
    
    /// The insets from the edge of the screen for the regular width size class.
    /// Defaults to `8.0, 8.0, 8.0, 8.0`
    public var regularWidthInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0) {
        didSet {
            setupConstraints()
        }
    }
    
    /// The insets from the edge of the screen for the compact width size class.
    /// Defaults to `8.0, 0.0, 0.0, 0.0`
    public var compactWidthInsets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 0.0, right: 0.0) {
        didSet {
            setupConstraints()
        }
    }
    
    /// The edge insets for the current layout.
    private var internalEdgeInsets: UIEdgeInsets {
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
    
    /// Constraints for the header.
    private var headerConstraints = [NSLayoutConstraint]()

    private let contentNavigationController = FloatingPanelNavigationController()
    private let headerNavigationController = UINavigationController()
    
    /// Add our internal header navigation controller to the `headerView`.
    private func setupHeaderNavigationController() {
        headerNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
//        headerNavigationController.view.setContentHuggingPriority(.required, for: .vertical)
        headerNavigationController.view.backgroundColor = .blue
        addChild(headerNavigationController)
        headerView.addSubview(headerNavigationController.view)
        headerNavigationController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            headerNavigationController.view.topAnchor.constraint(equalTo: headerView.topAnchor),
            headerNavigationController.view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerNavigationController.view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerNavigationController.view.leadingAnchor.constraint(equalTo: headerView.leadingAnchor)
        ])
        headerNavigationController.navigationBar.isHidden = true
//        headerNavigationController.delegate = self
    }
    
    /// Add our internal navigation controller to the `contentView`.
    private func setupContentNavigationController() {
        contentNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(contentNavigationController)
        //TODO: Is this right?  should this be in the `contentView`?
        contentView.addSubview(contentNavigationController.view)
        contentNavigationController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            contentNavigationController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentNavigationController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentNavigationController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentNavigationController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        contentNavigationController.navigationBar.isHidden = true
        contentNavigationController.delegate = self
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        setupContentNavigationController()
        setupHeaderNavigationController()
        
        contentNavigationController.headerNavigationController = headerNavigationController
        contentNavigationController.createHeaderViewControllerHandler = { [weak self] (floatingPanelEmbeddable: FloatingPanelEmbeddable) in
            return self?.instantiateHeaderViewController(for: floatingPanelEmbeddable)
        }
        
        // Set `isCompactWidth`.
        isCompactWidth = traitCollection.horizontalSizeClass == .compact
    }
    
    override public func removeFromParent() {
        super.removeFromParent()
        NSLayoutConstraint.deactivate(regularWidthConstraints)
        NSLayoutConstraint.deactivate(compactWidthConstraints);
        initialized = false
    }
    
    /// Sets up the constrains for both regular and compact horizontal size classes.
    /// - Parameter superview: The superview of the floating panel.
    private func setupConstraints() {
        guard let superview = view.superview else { return }
        
        // Set the resizable constraint used by the panGestureRecognizer to resize the panel.
        resizeableLayoutConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        resizeableLayoutConstraint.priority = .defaultLow
        
        // Define the constraints used for a regular-width layout.
        regularWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: regularWidthInsets.left),
            view.widthAnchor.constraint(equalToConstant: floatingPanelWidth),
            view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: regularWidthInsets.top),
            view.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -regularWidthInsets.bottom),
            
            bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerView.bottomAnchor),
            
            resizeableLayoutConstraint
        ]
        
        // Define the constraints used for a compact-width layout.
        compactWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: compactWidthInsets.left),
            view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: compactWidthInsets.right),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: compactWidthInsets.bottom),
            view.topAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.topAnchor, constant: compactWidthInsets.top),
            
            headerView.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -compactWidthInsets.bottom),
            
            resizeableLayoutConstraint
        ]
        
        // This will activate the appropriate set of constraints.
        updateInterfaceForCurrentTraits()
        
        // updateState will update the resizableLayoutConstraint constant
        // based on the current state.
        updateState(false)
    }
    
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
    
    /// Handles the pan gesture used to resize the floating panel.
    /// - Parameter gestureRecognizer: The active gesture recognizer.
    @IBAction private func handlePanGesture(_ gestureRecognizer : UIPanGestureRecognizer) {
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
                currentFloatingPanelItem.state = .minimized
                resizeableLayoutConstraint.constant = minimumHeight
            }
            else if resizeableLayoutConstraint.constant > maximumHeight {
                // Constraint is greater than maximum.
                currentFloatingPanelItem.state = .full
                resizeableLayoutConstraint.constant = maximumHeight
            }
            else {
                currentFloatingPanelItem.state = .partial
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
                currentFloatingPanelItem.state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
            }
            else {
                // The user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraint constant value.
                currentFloatingPanelItem.state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
        }
        else {
            // Regular width size class.
            if velocity.y > 0 {
                // Velocity > 0 means the user is dragging the view larger.
                // Switch to either .partial or .full depending on the constraint constant value.
                currentFloatingPanelItem.state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .partial : .full
            }
            else {
                // The user is dragging the view shorter.
                // Switch to either .minimized or .partial depending on the constraint constant value.
                currentFloatingPanelItem.state = resizeableLayoutConstraint.constant <= internalPartialHeight ? .minimized : .partial
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
                        self?.contentView?.alpha = (self?.currentFloatingPanelItem.state == .minimized ? 0.0 : 1.0)
                        self?.view.setNeedsUpdateConstraints()
                        superview.layoutIfNeeded()
        })
    }
    
    /// For some reason, the first time the initial view controller is set there
    /// are two calls to `navigationController:didShow:viewController:animated`.
    /// The second call messes up the logic for which header view controller to show.
    /// Adding a check for `animating` prevents the second call from happening.
    fileprivate var animating = false
}

fileprivate let transitionAnimationDuration: TimeInterval = 0.5

fileprivate class PushTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        toViewController.view.frame = finalFrameForVC.offsetBy(dx: 0, dy: finalFrameForVC.size.height)
        containerView.addSubview(toViewController.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromViewController.view.alpha = 0.5
            toViewController.view.frame = finalFrameForVC
        }) { (_) in
            transitionContext.completeTransition(true)
            fromViewController.view.alpha = 1.0
        }
    }
}

fileprivate class PopTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
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
            fromViewController.view.frame = finalFrameForVC.offsetBy(dx: 0, dy: finalFrameForVC.size.height)
        }) { (_) in
            transitionContext.completeTransition(true)
        }
    }
}

extension FloatingPanelViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // For a `pop` operation, use pop animation; for all other operations, use push.
        return operation == .pop ? PopTransitionAnimation() : PushTransitionAnimation()
    }
    
//    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
////        print("count: \(navigationController.viewControllers.count); Will show vc: \(viewController); topmost = \(String(describing: navigationController.topViewController))")
////        guard navigationController == contentNavigationController else { return }
////        if !(viewController == initialViewController) {
//////            // We're not the initial view controller, so create and setup
//////            // a new headerVC to push onto the header navigation controller stack.
//////            guard let fpEmbeddable = viewController as? FloatingPanelEmbeddable else { return }
//////            let headerViewController = instantiateHeaderViewController(for: fpEmbeddable)
//////            headerNavigationController.pushViewController(headerViewController, animated: true)
//////            headerNavigationController.view.layoutSubviews()
//////            NSLayoutConstraint.activate([
//////                headerNavigationController.view.heightAnchor.constraint(equalTo: headerNavigationController.topViewController!.view.heightAnchor, multiplier: 1.0),
//////                headerNavigationController.view.widthAnchor.constraint(equalTo: headerNavigationController.topViewController!.view.widthAnchor, multiplier: 1.0)
//////            ])
//////            print("count - ending: \(navigationController.viewControllers.count) headernav count: \(headerNavigationController.viewControllers.count)")
////        }
////        else {
////            headerNavigationController.popViewController(animated: true)
////        }
//
//
//////        if (viewController == initialViewController) {
////            animateHeader(true)
//////        }
//    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        print("Did show vc: \(viewController)")

        // Setup FloatingPanelItem if we transitioned with the floatingPanelNavigationController
        guard navigationController == contentNavigationController, let floatingPanelItem = (viewController as? FloatingPanelEmbeddable)?.floatingPanelItem else { return }
        self.currentFloatingPanelItem = floatingPanelItem

//        if !(viewController == initialViewController) {
//            animateHeader(false)
//        }

        // TODO:  Need to get better animation for this... Maybe a view containing the header stuff and then animating that up/down
        // based on push/pop and sliding in/out the new one?
        
        // Then, better animation
        // and make sure that we can change values and have them be shown in the header.
        // Also, make sure setting image to nil doesn't mess up the header title display
//        let currentFrame = currentFloatingPanelHeaderViewController.view.frame
//        pendingFloatingPanelHeaderViewController.view.frame = CGRect(origin: CGPoint(x: currentFrame.minX, y: currentFrame.minY + currentFrame.height), size: currentFrame.size)
//        pendingFloatingPanelHeaderViewController.view.alpha = 1.0
//        self.floatingPanelItem = floatingPanelItem
//
//        UIView.animate(withDuration: transitionAnimationDuration, animations: { [weak self] in
//            guard let self = self, !self.animating else { return }
//            self.currentFloatingPanelHeaderViewController.view.alpha = 0.0
//            self.pendingFloatingPanelHeaderViewController.view.frame = currentFrame
//            self.animating = true
//        }) { [weak self] (finished) in
//            guard let self = self, self.animating else { return }
//            let tmp = self.currentFloatingPanelHeaderViewController
//            self.currentFloatingPanelHeaderViewController = self.pendingFloatingPanelHeaderViewController
//            self.pendingFloatingPanelHeaderViewController = tmp
//            self.animating = false
//        }
    }
}

fileprivate class FloatingPanelNavigationController: UINavigationController {
    public typealias CreateHeaderViewControllerHandler = (FloatingPanelEmbeddable) -> UIViewController?

    var headerNavigationController: UINavigationController?
    var createHeaderViewControllerHandler: CreateHeaderViewControllerHandler?
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        print(".pushViewController: \(viewController)")
        
        guard let headerNavVC = headerNavigationController,
            let fpEmbeddable = viewController as? FloatingPanelEmbeddable,
            let newHeaderVC = createHeaderViewControllerHandler?(fpEmbeddable) else { return }

        headerNavVC.pushViewController(newHeaderVC, animated: animated)
        headerNavVC.view.layoutSubviews()
        NSLayoutConstraint.activate([
            headerNavVC.view.heightAnchor.constraint(equalTo: headerNavVC.topViewController!.view.heightAnchor, multiplier: 1.0),
            headerNavVC.view.widthAnchor.constraint(equalTo: headerNavVC.topViewController!.view.widthAnchor, multiplier: 1.0)
        ])
        
        //We're pushing a new content VC; create a header VC and push that...
        //TODO:  this stuff!!!
//        guard navigationController == contentNavigationController else { return }
//        if !(viewController == initialViewController) {
            // We're not the initial view controller, so create and setup
            // a new headerVC to push onto the header navigation controller stack.
//            guard let fpEmbeddable = viewController as? FloatingPanelEmbeddable else { return }
//            let headerViewController = instantiateHeaderViewController(for: fpEmbeddable)
//            headerNavigationController.pushViewController(headerViewController, animated: true)
//            headerNavigationController.view.layoutSubviews()
//            NSLayoutConstraint.activate([
//                headerNavigationController.view.heightAnchor.constraint(equalTo: headerNavigationController.topViewController!.view.heightAnchor, multiplier: 1.0),
//                headerNavigationController.view.widthAnchor.constraint(equalTo: headerNavigationController.topViewController!.view.widthAnchor, multiplier: 1.0)
//            ])
//            print("count - ending: \(navigationController.viewControllers.count) headernav count: \(headerNavigationController.viewControllers.count)")
//        }
//        else {
//            headerNavigationController.popViewController(animated: true)
//        }

        
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let returnVC = super.popViewController(animated: animated)
        print(".popViewController: \(String(describing: returnVC))")
        let poppedHeaderVC = headerNavigationController?.popViewController(animated: animated)
        print(".poppedHeaderVC: \(String(describing: poppedHeaderVC)); firstHeaderVC = \(String(describing: headerNavigationController?.topViewController))")
        

        return returnVC
    }
}
