//// Copyright 2019 Esri
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

// This class is intended to be subclassed and is done so in `RichPopupViewController`.
class SegmentedViewController: UIViewController {
    
    // MARK: Views
    
    private let effectsSegmentedControlContainerView: UIVisualEffectView = {
        
        // Build visual effect view with blur view.
        let visualEffect = UIBlurEffect(style: .extraLight)
        let visualEffectView = UIVisualEffectView(effect: visualEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        // Build 1pt spacer view.
        let spacer = UIView(frame: .zero)
        spacer.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
        spacer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add and constrain spacer.
        visualEffectView.contentView.addSubview(spacer)
        
        var constraints = [NSLayoutConstraint]()
        constraints.append( spacer.leadingAnchor.constraint(equalTo: visualEffectView.contentView.leadingAnchor) )
        constraints.append( spacer.trailingAnchor.constraint(equalTo: visualEffectView.contentView.trailingAnchor) )
        constraints.append( spacer.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor) )
        constraints.append( spacer.heightAnchor.constraint(equalToConstant: (1.0/UIScreen.main.scale)) )
        NSLayoutConstraint.activate(constraints)
        
        return visualEffectView
    }()
    
    let segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: .zero)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueDidChange(_:)), for: .valueChanged)
        return segmentedControl
    }()
    
    // MARK: Public Interface
    
    /// Refreshes titles for each segment with title of the cooresponding controller.
    func refreshSegmentTitles() {
        
        for (index, child) in childrenViewControllers.enumerated() {
            segmentedControl.setTitle(child.title, forSegmentAt: index)
        }
    }
    
    /// Should override and provide array of segue identifiers.
    public func segmentedViewControllerChildIdentifiers() -> [String] { return [] }
    
    private var childrenIdentifiers: [String]!
    
    // MARK: Segmented View Controllers
    
    fileprivate(set) weak var currentViewController: UIViewController?
    
    @objc func segmentedControlValueDidChange(_ sender: Any) {
        
        guard segmentedControl.selectedSegmentIndex < childrenViewControllers.count else { return }
        
        transitionToViewController(childrenViewControllers[segmentedControl.selectedSegmentIndex])
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.childrenIdentifiers = segmentedViewControllerChildIdentifiers()

        addSubviews()
        performChildViewControllersSegues()
        embedFirstChildViewController()
    }
    
    // MARK: Subviews
    
    private func addSubviews() {
        
        // Build Constraints
        var constraints = [NSLayoutConstraint]()
        
        // Add Subviews
        view.addSubview(effectsSegmentedControlContainerView)
        effectsSegmentedControlContainerView.contentView.addSubview(segmentedControl)
        
        // Hide segmented control container view if applicable.
        effectsSegmentedControlContainerView.isHidden = segmentedControl.numberOfSegments < 2
        
        // Effects View
        constraints.append( effectsSegmentedControlContainerView.topAnchor.constraint(equalTo: view.topAnchor) )
        constraints.append( effectsSegmentedControlContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor) )
        constraints.append( effectsSegmentedControlContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor) )
        constraints.append( effectsSegmentedControlContainerView.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8.0) )
        
        // Segmented Control
        constraints.append( segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8.0) )
        constraints.append( segmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8.0) )
        constraints.append( segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8.0) )
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: Children View Controllers
    
    private var childrenViewControllers = [UIViewController]()
    
    private func performChildViewControllersSegues() {
        
        // Embed all children.
        childrenIdentifiers.forEach { (identifier) in
            performSegue(withIdentifier: identifier, sender: self)
        }
        
        // Update view layout.
        view.layoutIfNeeded()
    }
    
    // MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let segue = segue as? SegmentedViewSegue {
            
            guard childrenIdentifiers.contains(segue.identifier ?? "") else {
                return assertionFailure("A Segmented View Segue must have an identifier.")
            }
            
            childrenViewControllers.append(segue.destination)
            
            segmentedControl.insertSegment(withTitle: segue.destination.title ?? "", at: childrenViewControllers.count, animated: false)
            effectsSegmentedControlContainerView.isHidden = segmentedControl.numberOfSegments < 2
        }
    }
    
    // MARK: Embed First Child
    
    private func embedFirstChildViewController() {
        
        segmentedControl.selectedSegmentIndex = 0
        
        transitionToViewController(childrenViewControllers[0])
    }
    
    private func transitionToViewController(_ to: UIViewController) {
        
        // Add destination
        
        func addAndConstrainViewControllerView(_ to: UIViewController) {
            
            to.loadViewIfNeeded()
            to.view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(to.view)
            self.view.sendSubviewToBack(to.view)
            
            let top = to.view.topAnchor.constraint(equalTo: view.topAnchor)
            let trailing = to.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let bottom = to.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            let leading = to.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            
            NSLayoutConstraint.activate([top, trailing, bottom, leading])
        }
        
        // This is not the first time a child view controller is embed, swap the two view controllers.
        if let from = currentViewController {
            
            // 1. Send message that view controller will be removed from parent.
            from.willMove(toParent: nil)
            
            // 2. Remove previous view controller view (automatically removes auto layout constraints).
            from.view.removeFromSuperview()
            
            // 3. Remove child view controller from parent container.
            from.removeFromParent()
            
            // 4. Add view controller view as subview.
            addAndConstrainViewControllerView(to)
            
            // 5. Add child view controller to parent.
            addChild(to)
            
            // 6. Send message that view controller was added to parent and will appear.
            to.didMove(toParent: self)
            
            // 7. Point to current view controller.
            currentViewController = to
            
            // 8. Finish.
            view.layoutIfNeeded()
        }
            // This is the first time a child view controller is embed.
        else {
            
            // 1. Add child view controller to parent.
            addChild(to)
            
            // 2. Add view controller view as subview.
            addAndConstrainViewControllerView(to)
            
            // 3. Ensure editing session of child reflects that of parent.
            to.setEditing(isEditing, animated: false)
            
            // 4. Send message that view controller was added to parent and will appear.
            to.didMove(toParent: self)
            
            // 5. Point to current view controller.
            currentViewController = to
            
            // 6. Finish.
            view.layoutIfNeeded()
        }
    }
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        let topOffset = effectsSegmentedControlContainerView.isHidden ? 0.0 : segmentedControl.bounds.height + 16
        
        children.forEach { (child) in
            child.additionalSafeAreaInsets = UIEdgeInsets(top: topOffset, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    // MARK: Editing
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        childrenViewControllers.forEach { (child) in
            child.setEditing(editing, animated: animated)
        }
    }
}

class SegmentedViewSegue: UIStoryboardSegue {
    override func perform() { }
}
