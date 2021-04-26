//// Copyright 2021 Esri
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

import ArcGIS
import PhotosUI

extension RichPopupViewController {
    func selectMedia() {
        let actionSheet = UIAlertController(
            title: nil,
            message: "Select media",
            preferredStyle: .actionSheet
        )
        let camera = UIAlertAction(
            title: "Camera",
            style: .default,
            handler: selectCamera
        )
        actionSheet.addAction(camera)
        if #available(iOS 14.0, *) {
            let photoPicker = UIAlertAction(
                title: "Image Library",
                style: .default,
                handler: selectPhotoPicker
            )
            actionSheet.addAction(photoPicker)
        }
        else {
            let imagePicker = UIAlertAction(
                title: "Image Library",
                style: .default,
                handler: selectImagePicker
            )
            actionSheet.addAction(imagePicker)
        }
        actionSheet.addAction(.cancel())
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func selectCamera(_ action: UIAlertAction) {
        let usageDescription = "NSCameraUsageDescription"
        let sourceType = UIImagePickerController.SourceType.camera
        guard Bundle.main.infoDictionary![usageDescription] != nil else {
            preconditionFailure("Info.plist must contain the \(usageDescription) key/value combination.")
        }
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            presentUnavailable(title: action.title)
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
            guard let self = self else { return }
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                DispatchQueue.main.async {
                    let imagePicker = UIImagePickerController()
                    imagePicker.sourceType = sourceType
                    imagePicker.mediaTypes = [kUTTypeImage] as [String]
                    imagePicker.delegate = self
                    self.present(imagePicker, animated: true, completion: nil)
                }
            case .denied:
                self.presentSettings(title: action.title)
            case .restricted:
                self.presentRestricted(title: action.title)
            case .notDetermined:
                break
            @unknown default:
                fatalError("Unsupported type.")
            }
        }
    }
    
    private func selectImagePicker(_ action: UIAlertAction) {
        let usageDescription = "NSPhotoLibraryUsageDescription"
        let sourceType = UIImagePickerController.SourceType.photoLibrary
        guard Bundle.main.infoDictionary![usageDescription] != nil else {
            preconditionFailure("Info.plist must contain the \(usageDescription) key/value combination.")
        }
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            presentUnavailable(title: action.title)
            return
        }
        
        if #available(iOS 14.0, *) {
            fatalError("Devices running iOS 14.0 should use PHPickerViewController by calling `selectPhotoPicker`")
        }
        else {
            PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                guard let self = self else { return }
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        let imagePicker = UIImagePickerController()
                        imagePicker.sourceType = sourceType
                        imagePicker.mediaTypes = [kUTTypeImage] as [String]
                        imagePicker.delegate = self
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                case .denied:
                    self.presentSettings(title: action.title)
                case .restricted:
                    self.presentRestricted(title: action.title)
                case .notDetermined, .limited:
                    // .limited won't be reached because this request won't be performed on devices running iOS 14.0
                    // .notDetermined won't be reached because the request was performed
                    break
                @unknown default:
                    fatalError("Unsupported type.")
                }
            }
        }
    }
    
    @available(iOS 14.0, *)
    private func selectPhotoPicker(_ action: UIAlertAction) {
        DispatchQueue.main.async {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 8
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    private func presentSettings(title: String?) {
        let alert = UIAlertController(
            title: "Not Authorized",
            message: "Go to Settings and authorize the use of the \(title ?? "media").",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "Settings", style: .default) { _ in
                UIApplication.shared.open(
                    URL(string: UIApplication.openSettingsURLString)!
                )
            }
        )
        let okay: UIAlertAction = .okay()
        alert.addAction(okay)
        alert.preferredAction = okay
        showAlert(alert, animated: true, completion: nil)
    }
    
    private func presentRestricted(title: String?) {
        let alert = UIAlertController(
            title: "Restricted",
            message: "You do not have access to the \(title ?? "media").",
            preferredStyle: .alert
        )
        alert.addAction(.okay())
        showAlert(alert, animated: true, completion: nil)
    }
    
    private func presentUnavailable(title: String?) {
        let alert = UIAlertController(
            title: "Unavailable",
            message: "\(title?.capitalized ?? "Media") is unavailable on this device.",
            preferredStyle: .alert
        )
        alert.addAction(.okay())
        showAlert(alert, animated: true, completion: nil)
    }
}

extension RichPopupViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard !isProcessingNewAttachmentImage else { return }
        isProcessingNewAttachmentImage = true
        
        if let newAttachment = RichPopupStagedImagePickerAttachment(imagePickerMediaInfo: info) {
            // After selecting a size, that size is stored in `UserDefaults`. Default the new attachment with the last selected size.
            if let preferredSize = UserDefaults.standard.preferredAttachmentSize {
                newAttachment.preferredSize = preferredSize
            }
            // Insert newly staged attachment.
            attachmentsViewController.addAttachment(newAttachment)
        }
        else {
            showMessage(message: "Something went wrong adding the image attachment.")
        }
        
        picker.dismiss(animated: true) { [weak self] in
            self?.isProcessingNewAttachmentImage = false
        }
    }
}

fileprivate struct InvalidTypeIdentifier: LocalizedError {
    let typeIdentifiers: [String]?
    var errorDescription: String? {
        return "Failed to create an attachment with picked media."
    }
}

fileprivate struct UnknownError: LocalizedError {
    var errorDescription: String? { "Unknown error occured." }
}

@available(iOS 14.0, *)
extension RichPopupViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else { return }
        guard !isProcessingNewAttachmentImage else { return }
        isProcessingNewAttachmentImage = true
        let attachments = results.compactMap { RichPopupStagedPhotoPickerAttachment(itemProvider: $0.itemProvider) }
        picker.dismiss(animated: true) {
            attachments.forEach { self.attachmentsViewController.addAttachment($0) }
            self.isProcessingNewAttachmentImage = false
        }
    }
}
