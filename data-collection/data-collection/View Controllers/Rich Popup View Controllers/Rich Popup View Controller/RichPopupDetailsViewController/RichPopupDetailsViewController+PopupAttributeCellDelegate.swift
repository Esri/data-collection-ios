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

import ArcGIS
import UIKit

extension RichPopupDetailsViewController: PopupAttributeCellDelegate {
    
    func popupAttributeCell(_ cell: PopupAttributeCell, didBecomeFirstResponder firstResponder: UIResponder) {
        
        // Add a hide keyboard for table cells that contain a first responder.
        if var responder = firstResponder as? UIResponderInputAccessoryViewProtocol {
            
            let toolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            toolbar.barStyle = .default
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                             UIBarButtonItem(title: "Hide", style: .plain, target: self, action: #selector(userDidRequestDismissKeyboard))]
            toolbar.sizeToFit()
            responder.inputAccessoryView = toolbar
        }

        self.currentFirstResponder = firstResponder
    }
    
    @objc func userDidRequestDismissKeyboard() {
        
        if let firstResponder = currentFirstResponder, firstResponder.isFirstResponder {
            firstResponder.resignFirstResponder()
        }
        
        self.currentFirstResponder = nil
    }
    
    func popupAttributeCell(_ cell: PopupAttributeCell, valueDidChange value: Any?, at indexPath: IndexPath) -> String {
        
        guard let field = popupManager.attributeField(forIndexPath: indexPath) else {
            // something went wrong.
            return ""
        }
        
        try? popupManager.updateValue(value, field: field)
        
        let error = popupManager.validationError(for: field)
        
        cell.setValidity(error)
        
        return popupManager.formattedValue(for: field)
    }
}
