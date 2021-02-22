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
import AVFoundation
import Photos
import MobileCoreServices

fileprivate protocol ImagePickerPermission {
    
    var title: String { get }
    var actionTitle: String { get }
    
    static var usageDescriptionKeys: [String] { get }
    
    func isAuthorized() -> Bool
    func shouldRequest() -> Bool
    func request(_ completion: @escaping (_ granted: Bool, _ shouldOpenSettings: Bool) -> Void )
    
    var sourceType: UIImagePickerController.SourceType { get }
    
    var mediaTypes: [CFString] { get }
}

fileprivate extension ImagePickerPermission {
    
    static var plistContainsUsageDescriptions: Bool {
        
        let infoDictionary = Bundle.main.infoDictionary!
        
        return usageDescriptionKeys.allSatisfy { infoDictionary[$0] != nil }
    }
    
    func select(_ completion: @escaping (_ granted: Bool, _ shouldOpenSettings: Bool) -> Void ) {
        
        if isAuthorized() {
            completion(true, false)
        }
        else if shouldRequest() {
            request { (granted, shouldOpenSettings) in
                DispatchQueue.main.async {
                    completion(granted, shouldOpenSettings)
                }
            }
        }
        else {
            completion(false, true)
        }
    }
    
    var isSourceTypeAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(sourceType)
    }
    
    func buildImagePicker() -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = mediaTypes as [String]
        return imagePicker
    }
}

public protocol ImagePickerPermissionsDelegate: AnyObject {
    
    func imagePickerPermissionsRequestsPresentingViewController() -> UIViewController
    func imagePickerPermissionsFinishedWith(imagePicker: UIImagePickerController?)
}

/// An end-to-end solution for access to the user's camera and library.
///
/// - NOTE: This end-to-end tool is tighly coupled to the `UIImagePickerController`. Requires some abstraction for introducing new permissions.
///
public struct ImagePickerPermissions {
    
    public enum OptionType {
        
        case photo, library
        
        fileprivate var permission: ImagePickerPermission? {
            
            switch self {
            case .photo:
                return Photo()
            case .library:
                return Library()
            }
        }
    }
    
    public weak var delegate: ImagePickerPermissionsDelegate?
    
    /// Begins the process of obtaining an image.
    ///
    /// Process:
    /// * Check source type availability
    /// * Ask user for desired source type
    /// * Check & ask device permissions
    /// * Kick to Settings for denied permissions
    /// * Build `UIImagePickerController`
    ///
    /// - NOTE: Must have specified `ImagePickerPermissionsDelegate`.
    ///
    public func request(options types: [OptionType]) {
        
        guard let delegate = self.delegate else { return }
        
        let permissions = types.compactMap { $0.permission }
        
        func select(permission: ImagePickerPermission) {
            
            permission.select { (granted, shouldOpenSettingsApp) in
                
                if granted {
                    // Build image picker.
                    let imagePicker = permission.buildImagePicker()
                    
                    // Finish with built image picker.
                    delegate.imagePickerPermissionsFinishedWith(imagePicker: imagePicker)
                }
                else if shouldOpenSettingsApp {
                    
                    // Ask to open Settings
                    let viewController = delegate.imagePickerPermissionsRequestsPresentingViewController()
                    
                    let alert = UIAlertController(title: "Not Authorized", message: "Go to Settings and authorize the use of the \(permission.title).", preferredStyle: .alert)
                    
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                        
                        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
                            UIApplication.shared.open(settingsUrl)
                        })
                        
                        alert.addAction(settingsAction)
                    }
                    
                    let okayAction = UIAlertAction.okay()
                    alert.addAction(okayAction)
                    alert.preferredAction = okayAction
                    
                    viewController.present(alert, animated: true)
                    
                    // Finish with no image picker.
                    delegate.imagePickerPermissionsFinishedWith(imagePicker: nil)
                }
                else {
                    
                    // Finish with no image picker.
                    delegate.imagePickerPermissionsFinishedWith(imagePicker: nil)
                }
            }
        }
        
        guard !permissions.isEmpty else {
            delegate.imagePickerPermissionsFinishedWith(imagePicker: nil)
            return
        }
        
        guard permissions.count > 1 else {
            select(permission: permissions.first!)
            return
        }
        
        let viewController = delegate.imagePickerPermissionsRequestsPresentingViewController()
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for permission in permissions {
            
            let alertAction = UIAlertAction(title: permission.actionTitle, style: .default) { (action) in
                select(permission: permission)
            }
            
            alertController.addAction(alertAction)
        }

        alertController.addAction(.cancel())

        viewController.present(alertController, animated: true)
    }
}

extension ImagePickerPermissions {
    
    fileprivate class Photo: ImagePickerPermission {
        
        init?() {
            
            guard Photo.plistContainsUsageDescriptions else {
                assertionFailure("Info.plist must contain value for keys \(Photo.usageDescriptionKeys)")
                return nil
            }
            
            guard isSourceTypeAvailable else {
                print("Source type \(sourceType) unavailable.")
                return nil
            }
        }
        
        // MARK: Permission
        
        class var usageDescriptionKeys: [String] {
            return ["NSCameraUsageDescription"]
        }
        
        var title: String {
            return "Camera"
        }
        
        var actionTitle: String {
            return "Take Photo"
        }
        
        func isAuthorized() -> Bool {
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        }
        
        func shouldRequest() -> Bool {
            return AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
        }
        
        func request(_ completion: @escaping (_ granted: Bool, _ shouldOpenSettings: Bool) -> Void ) {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                DispatchQueue.main.async {
                    completion(granted, false)
                }
            }
        }
        
        // MARK: Image Picker Permission
        
        var sourceType: UIImagePickerController.SourceType {
            return .camera
        }
        
        var mediaTypes: [CFString] {
            return [kUTTypeImage]
        }
    }
}

extension ImagePickerPermissions {
    
    fileprivate class Library: ImagePickerPermission {
        
        init?() {
            
            guard Library.plistContainsUsageDescriptions else {
                assertionFailure("Info.plist must contain value for keys \(Library.usageDescriptionKeys)")
                return nil
            }
            
            guard isSourceTypeAvailable else {
                print("Source type \(sourceType) unavailable.")
                return nil
            }
        }
        
        // MARK: Permission
        
        static let usageDescriptionKeys = ["NSPhotoLibraryUsageDescription"]
        
        var title: String {
            return "Photos"
        }
        
        var actionTitle: String {
            return "Image Library"
        }

        func isAuthorized() -> Bool {
            if #available(iOS 14, *) {
                return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
            }
            else {
                return PHPhotoLibrary.authorizationStatus() == .authorized
            }
        }
        
        func shouldRequest() -> Bool {
            return PHPhotoLibrary.authorizationStatus() == .notDetermined
        }
        
        func request(_ completion: @escaping (_ granted: Bool, _ shouldOpenSettings: Bool) -> Void) {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    var granted: Bool
                    var shouldOpenSettings: Bool
                    if #available(iOS 14, *) {
                        granted = PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized
                        shouldOpenSettings = !granted
                    }
                    else {
                        granted = PHPhotoLibrary.authorizationStatus() == .authorized
                        shouldOpenSettings = false
                    }
                    completion(granted, shouldOpenSettings)
                }
            }
        }
        
        // MARK: Image Picker Permission
        
        var sourceType: UIImagePickerController.SourceType {
            return .photoLibrary
        }
        
        var mediaTypes: [CFString] {
            return [kUTTypeImage]
        }
    }
}
