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

/// The protocol you implement to respond as the user interacts with the
/// floating panel view controller.
public protocol FloatingPanelViewControllerDelegate: AnyObject {
    /// Tells the delegate that the user has requested to dismiss the floating panel view controller.
    ///
    /// - Parameter floatingPanelViewController: The current floating panel view controller.
    func userDidRequestDismissFloatingPanel(_ floatingPanelViewController: FloatingPanelViewController)
}

/// Defines how to display layers in the table.
/// - Since: 100.8.0
public enum FloatingPanelState {
    // Minimized is used to set a default minimum size.
    case minimized
    // Fits intrinsic size of content, assuming content is in stack view.
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
    
    var delegate: FloatingPanelViewControllerDelegate?
    
    let floatingPanelWidth: CGFloat = 320
    
    let defaultPartialHeight: CGFloat = 160
    var minimumHeight: CGFloat {
        return headerStackView.frame.origin.y + headerStackView.frame.size.height
    }
    

    var maximumHeight: CGFloat {
        if let superview = view.superview {
            return superview.frame.height - edgeInsets.top - edgeInsets.bottom
        }
        else {
            return 320
        }
    }
    
    //TODO:  consider putting all header stuff and header spacers in one header view (vert stack view?) and
    // then using that height as the minimum height (+ the bottom handlebar view, if we're .regular
    // Then figure out how to do the same for maximumHeight; then use those heights in the "state" stuff.
    
    fileprivate func animateResizableConstrant(_ newConstant: CGFloat) {
        // Ensures that all pending layout operations have been completed
        view.layoutIfNeeded()

        UIView.transition(with: view,
                          duration: 2.5,
                          options: [.layoutSubviews, .curveEaseOut],
                          animations: { [weak self] in
                            self?.resizeableLayoutConstraint.constant = newConstant
//                            self?.view.layoutIfNeeded()
        })
    }
    
    var state: FloatingPanelState = .full {
        didSet {
            var newConstant: CGFloat = 0
            switch state {
            case .minimized:
//                bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerSpacerView.bottomAnchor),
//                let distance = bottomHandlebarView.topAnchor - headerSpacerView.bottomAnchor
                newConstant = minimumHeight
            case .partial:
                newConstant = defaultPartialHeight
            case .full:
                newConstant = maximumHeight
            }
            
            animateResizableConstrant(newConstant)
//            UIView.animate(withDuration: 0.5) { [weak self] in
//                self?.resizeableLayoutConstraint.constant = newConstant
//                self?.view.layoutIfNeeded()
//            }

//            resizeableLayoutConstraint.constant = newConstant
        }
    }
    
    var closeButtonHidden: Bool = false {
        didSet {
            closeButton.isHidden = closeButtonHidden
        }
    }
    
    var allowManualResize = true {
        didSet {
            handlebarView.isHidden = !allowManualResize && !isCompactWidth
            bottomHandlebarView.isHidden = !allowManualResize && isCompactWidth
        }
    }
    
    var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = (image == nil)
        }
    }
    
    var floatingPanelTitle: String? {
        didSet {
            let _ = view // Make sure we're loaded...
            titleLabel.text = floatingPanelTitle
            titleLabel.isHidden = floatingPanelTitle?.isEmpty ?? true
        }
    }
    
    var floatingPanelSubtitle: String? {
        didSet {
            subTitleLabel.text = floatingPanelSubtitle
            subTitleLabel.isHidden = floatingPanelSubtitle?.isEmpty ?? true
        }
    }
    
    var initialViewController: UIViewController? {
        didSet {
            if let viewController = initialViewController {
                let _ = view // Make sure we're loaded...
                addChild(viewController)
                contentView.addSubview(viewController.view)
            }
        }
    }
    
    internal var resizeableLayoutConstraint: NSLayoutConstraint = NSLayoutConstraint() {
        didSet {
            initialResizableLayoutConstraintConstant = resizeableLayoutConstraint.constant
        }
    }
    var initialResizableLayoutConstraintConstant: CGFloat = 0.0
    
    
    /// The insets from the edge of the screen. The client can override the insets for various layout options.
    var edgeInsets: UIEdgeInsets {
        // Add trait collection stuff here
        // if compact width, then no left/right/bottom insets.
        let offsetForTrait: CGFloat = isCompactWidth ? 0.0 : 8.0
        return UIEdgeInsets(top: 8.0, left: offsetForTrait, bottom: offsetForTrait, right: offsetForTrait)
    }
    
    internal var isCompactWidth: Bool = false {
        didSet {
            handlebarView.isHidden = !isCompactWidth
            bottomHandlebarView.isHidden = isCompactWidth
            updateInterfaceForCurrentTraits()
        }
    }
    
    private var initialized = false
    
    private var regularWidthConstraints = [NSLayoutConstraint]()
    private var compactWidthConstraints = [NSLayoutConstraint]()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        isCompactWidth = traitCollection.horizontalSizeClass == .compact
    }
    
    //    override public func viewDidAppear(_ animated: Bool) {
    //        print("viewDidAppear; superview = \(String(describing: view.superview))")
    //    }
    
    override public func viewDidAppear(_ animated: Bool) {
        print("viewDidAppear; superview = \(String(describing: view.superview))")
        super.viewWillAppear(animated)
        
        // Skip if already initialized
        guard !initialized, let superview = view.superview else { return }
        
        if allowManualResize
        {
            //            _blurView.AddGestureRecognizer(_gesture);
        }
        
        //                resizeableLayoutConstraint = view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: edgeInsets.top)
//        resizeableLayoutConstraint = view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -edgeInsets.bottom)
        //                resizeableLayoutConstraint = view.heightAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.heightAnchor)
        resizeableLayoutConstraint = view.heightAnchor.constraint(equalToConstant: defaultPartialHeight)
        resizeableLayoutConstraint.priority = .defaultLow
        //                view.setContentCompressionResistancePriority(.defaultLow  , for: .vertical)
        regularWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: edgeInsets.left),
            view.widthAnchor.constraint(equalToConstant: floatingPanelWidth),
            view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: edgeInsets.top),
            view.bottomAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -edgeInsets.bottom),


//            view.bottomAnchor.constraint(greaterThanOrEqualTo: headerStackView.bottomAnchor),
//            bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerStackView.bottomAnchor),
            bottomHandlebarView.topAnchor.constraint(greaterThanOrEqualTo: headerSpacerView.bottomAnchor),

            
//            view.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: edgeInsets.top),
            //View.BottomAnchor.ConstraintLessThanOrEqualTo(View.Superview.SafeAreaLayoutGuide.BottomAnchor)
            
//            view.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumHeight),

            resizeableLayoutConstraint
            //            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -edgeInsets.bottom)
        ]
        
        //                resizeableLayoutConstraint = view.heightAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.heightAnchor)
        //                view.setContentCompressionResistancePriority(.defaultLow  , for: .vertical)
        //                regularWidthConstraints = [
        //                    view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: edgeInsets.left),
        //                    view.widthAnchor.constraint(equalToConstant: floatingPanelWidth),
        //                    view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: edgeInsets.top),
        //
        //                    view.bottomAnchor.constraint(greaterThanOrEqualTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: edgeInsets.bottom),
        //                    view.heightAnchor.constraint(greaterThanOrEqualToConstant: 88.0),
        //                    resizeableLayoutConstraint
        //        //            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -edgeInsets.bottom)
        //                ]
        
        //        if allowManualResize
        //        {
        //            regularWidthConstraints(equalTo: superview.bottomAnchor, constant: edgeInsets.left),
        //            regularWidthConstraints.add(_handlebar.BottomAnchor.ConstraintEqualTo(View.BottomAnchor, -(0.5f * ApplicationTheme.Margin)));
        //            regularWidthConstraints.add(DisplayedContentView.BottomAnchor.ConstraintEqualTo(_handlebarSeparator.TopAnchor, -ApplicationTheme.Margin));
        //            regularWidthConstraints.add(_handlebarSeparator.BottomAnchor.ConstraintEqualTo(_handlebar.TopAnchor, -(0.5f * ApplicationTheme.Margin)));
        //        }
        //        else
        //        {
        //            regularWidthConstraints.Add(DisplayedContentView.BottomAnchor.ConstraintEqualTo(View.BottomAnchor));
        //        }
        
        //
        compactWidthConstraints = [
            view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: edgeInsets.left),
            view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: edgeInsets.right),
            view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: edgeInsets.bottom),
            
            view.topAnchor.constraint(lessThanOrEqualTo: superview.safeAreaLayoutGuide.topAnchor, constant: edgeInsets.top),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 88.0),
            
            resizeableLayoutConstraint
            //            DisplayedContentView.BottomAnchor.ConstraintEqualTo(View.BottomAnchor)
        ]
        //
        //        if (AllowsManualResize)
        //        {
        //            compactWidthConstraints.Add(_handlebarSeparator.TopAnchor.ConstraintEqualTo(_handlebar.BottomAnchor, (0.5f * ApplicationTheme.Margin)));
        //            compactWidthConstraints.Add(_handlebar.TopAnchor.ConstraintEqualTo(View.TopAnchor, ApplicationTheme.Margin));
        //            compactWidthConstraints.Add(DisplayedContentView.TopAnchor.ConstraintEqualTo(_handlebar.BottomAnchor));
        //        }
        //        else
        //        {
        //            compactWidthConstraints.Add(DisplayedContentView.TopAnchor.ConstraintEqualTo(View.TopAnchor));
        //        }
        //
        //        _compactWidthConstraints = compactWidthConstraints.ToArray();
        //
        //        _heightConstraint = View.HeightAnchor.ConstraintEqualTo(DefaultPartialHeight);
        //        _heightConstraint.Active = true;
        //
        //        UpdateInterfaceForCurrentTraits();
        //
        //        _initialized = true;
        initialized = true
        updateInterfaceForCurrentTraits()
    }
    
    private func updateInterfaceForCurrentTraits() {
        
        NSLayoutConstraint.deactivate(regularWidthConstraints)
        NSLayoutConstraint.deactivate(compactWidthConstraints);
        
        if isCompactWidth {
            NSLayoutConstraint.activate(compactWidthConstraints);
            //                if (_handlebarSeparator != null)
            //                {
            //                    _handlebarSeparator.BackgroundColor = UIColor.Clear;
            //                }
        }
        else {
            NSLayoutConstraint.activate(regularWidthConstraints);
            //                if (_handlebarSeparator != null)
            //                {
            //                    _handlebarSeparator.BackgroundColor = ApplicationTheme.SeparatorColor;
            //                }
        }
        
        //            SetState(_currentState);
        
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func closeButtonAction(_ sender: Any) {
        delegate?.userDidRequestDismissFloatingPanel(self)
    }
    
    var initialConstant: CGFloat = 0.0
    @IBAction func handlePanGesture(_ gestureRecognizer : UIPanGestureRecognizer) {
//        guard let superview = gestureRecognizer.view?.superview else { return }
        
//        let piece = gestureRecognizer.view!
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview)
        if gestureRecognizer.state == .began {
            // Save the view's original constant.
            initialResizableLayoutConstraintConstant = resizeableLayoutConstraint.constant
        }
        
        // Update the position for the .began, .changed, and .ended states
        // Enables 'flick' gesture to switch between states
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
            
//            else if resizeableLayoutConstraint.constant > minimumHeight &&
//                resizeableLayoutConstraint.constant < maximumHeight {
////            if resizeableLayoutConstraint.constant <= minimumHeight {
////                _currentState = BottomSheetState.Minimized;
////            }
////            else if resizeableLayoutConstraint.constant >= maximumHeight {
////                _currentState = BottomSheetState.Full;
////            }
////            else {
//                state = .partial;
//            }
        }
        else if gestureRecognizer.state != .cancelled {
            // Use the initialTopLayoutConstraintConstant value when determining minimum
            var newConstant = initialResizableLayoutConstraintConstant + (isCompactWidth ? -translation.y : translation.y)
//            if resizeableLayoutConstraint.constant < minimumHeight {
//                newConstant = minimumHeight
//            }
//            else if resizeableLayoutConstraint.constant > maximumHeight {
//                newConstant = maximumHeight
//            }
//            newConstant = min(superview.frame.height, newConstant)
            
            newConstant = max(minimumHeight, newConstant)
            newConstant = min(maximumHeight, newConstant)

//            let constant = isCompactWidth ?
//                max(superview.frame.height, initialResizableLayoutConstraintConstant + delta) :
//                max(superview.frame.height, initialResizableLayoutConstraintConstant + delta)
            
            resizeableLayoutConstraint.constant = newConstant
        }
        else {
            // On cancellation, return the piece to its original location.
            animateResizableConstrant(initialResizableLayoutConstraintConstant)
        }
    }
    
    public func handleFlick(_ velocity: CGPoint) {
        switch (state) {
        case .minimized:
            if isCompactWidth && velocity.y < 0 {
                state = .partial
            }
            else if !isCompactWidth && velocity.y > 0 {
                state = .partial
            }
        case .partial:
            if isCompactWidth && velocity.y < 0 {
                state = .full
            }
            else if !isCompactWidth && velocity.y < 0 {
                state = .minimized
            }
            else if isCompactWidth && velocity.y > 0 {
                state = .minimized
            }
            else if !isCompactWidth && velocity.y > 0 {
                state = .full
            }
        case .full:
            if isCompactWidth && velocity.y > 0 {
                state = .partial
            }
            else if !isCompactWidth && velocity.y < 0 {
                state = .partial
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        isCompactWidth = traitCollection.horizontalSizeClass == .compact
    }
}


// TODO: - for iPad (regular width) put handlebar on bottom!!!!