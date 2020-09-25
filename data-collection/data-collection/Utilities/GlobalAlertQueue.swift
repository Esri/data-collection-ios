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

// MARK:- Public Interface

extension UIViewController: GlobalAlertQueueable {
    
    func showAlert(_ alert: UIAlertController, animated: Bool, completion: (() -> Void)?) {
        GlobalAlertQueue.shared.show(alert, window: view.window, animated: animated, completion: completion)
    }
}

extension UIApplication: GlobalAlertQueueable {
    
    func showAlert(_ alert: UIAlertController, animated: Bool, completion: (() -> Void)?) {
        GlobalAlertQueue.shared.show(alert, window: windows.last, animated: animated, completion: completion)
    }
}

protocol GlobalAlertQueueable: class {
    func showAlert(_ alert: UIAlertController, animated: Bool, completion: (() -> Void)?)
}

extension GlobalAlertQueueable {
    
    func showError(_ error: Error, ignoreUserCancelledError: Bool = true) {
        if ignoreUserCancelledError, (error as NSError).code == NSUserCancelledError {
            return
        }
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.okay())
        showAlert(alert, animated: true, completion: nil)
    }
    
    func showMessage(title: String? = nil, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.okay())
        showAlert(alert, animated: true, completion: nil)
    }
}

// MARK:- Private Business Logic

private class GlobalAlertQueue: PhantomDelegate {
    
    static let shared = GlobalAlertQueue()
    
    private init() { }
    
    var alertWindow: UIWindow?
    
    private var queue = Queue<AlertItem>()
    
    func show(_ alert: UIAlertController, window: UIWindow?, animated: Bool, completion: (() -> Void)?) {

        let item = AlertItem(alert: alert, window: window, animated: animated, completion: completion)
        queue.enqueue(item)
        
        if alertWindow == nil {
            showNextAlert()
        }
    }
            
    fileprivate func showNextAlert() {
        
        if let next = queue.dequeue() {
            let window: UIWindow = {
                let window = UIWindow(frame: next.window?.frame ?? UIScreen.main.bounds)
                let phantom = PhantomViewController(next.alert)
                phantom.delegate = self
                window.rootViewController = phantom
                window.windowLevel = max(.alert, (next.window?.windowLevel ?? .alert)) + 1
                return window
            }()

            window.makeKeyAndVisible()
            
            alertWindow = window
        }
        else {
            alertWindow?.resignKey()
            alertWindow = nil
        }
    }
    
    func viewController(_ viewController: PhantomViewController, didDismiss alert: UIAlertController) {
        showNextAlert()
    }
}

fileprivate protocol PhantomDelegate: class {
    func viewController(_ viewController: PhantomViewController, didDismiss alert: UIAlertController)
}

private class PhantomViewController: UIViewController {
    
    private let alert: UIAlertController
    
    weak var delegate: PhantomDelegate?
    
    // MARK: - Init
    
    init(_ alert: UIAlertController) {
        self.alert = alert
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Dismiss
    
    // Overriding this method is key!
    // When a user dismisses the alert, `dismiss` is called on the presenting view controller.
    // This provides us with the opportunity to inform the delegate the alert has dismissed.
    // It is notoriously difficult to capture when an `UIAlertController` is dismissed without overriding the completion block,
    // this technique attempts to solve this notoriously difficult problem.
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            completion?()
            self.delegate?.viewController(self, didDismiss: self.alert)
        }
    }
}

private struct Queue<Element> {
    
    private var elements = [Element]()

    mutating func enqueue(_ element: Element) {
        elements.append(element)
    }

    mutating func dequeue() -> Element? {
        guard !elements.isEmpty else {
            return nil
        }

        return elements.removeFirst()
    }
}

private struct AlertItem {
    let alert: UIAlertController
    weak var window: UIWindow?
    let animated: Bool
    let completion: (() -> Void)?
}

extension UIAlertAction {
    /// Creates a new alert action with "Cancel" as the title and `cancel` as
    /// the style.
    ///
    /// - Parameter handler: A closure to execute when the user selects the
    /// action.
    /// - Returns: A new alert action object.
    class func cancel(handler: ((_ action: UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: "Cancel", style: .cancel, handler: handler)
    }
    
    /// Creates a new alert action with "OK" as the title and `default` as
    /// the style.
    ///
    /// - Parameter handler: A closure to execute when the user selects the
    /// action.
    /// - Returns: A new alert action object.
    class func okay(handler: ((_ action: UIAlertAction) -> Void)? = nil) -> UIAlertAction {
        return UIAlertAction(title: "OK", style: .default, handler: handler)
    }
}

extension UIAlertController {
    
    static func settingsAlert(_ message: String) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let settings = UIAlertAction(title: "Settings", style: .default) { (_) in
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            else {
                fatalError("Something is wrong with iOS.")
            }
        }
        alert.addAction(.cancel())
        alert.addAction(settings)
        return alert
    }
}
