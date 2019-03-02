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

import Foundation

protocol PopupAttributeCell: AnyObject {
    
    typealias AttributeValue = (formatted: String, raw: Any?)
    
    func setTitle(_ title: String, value: AttributeValue)
    func setValidity(_ error: Error?)
    
    var firstResponder: UIView? { get }
    
    var delegate: PopupAttributeCellDelegate? { get set }
}

protocol PopupAttributeCellDelegate: AnyObject {
    @discardableResult func popupAttributeCell(_ cell: PopupAttributeCell, valueDidChange value: Any?) -> String
    func popupAttributeCell(_ cell: PopupAttributeCell, didBecomeFirstResponder firstResponder: UIResponder)
}
