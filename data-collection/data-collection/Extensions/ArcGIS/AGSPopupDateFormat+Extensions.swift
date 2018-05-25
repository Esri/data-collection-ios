//// Copyright 2018 Esri
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
import ArcGIS

extension AGSPopupDateFormat {
    
    var dateFormatter: DateFormatter? {
        
        var formattedString: String!
        
        switch self {
        case .dayShortMonthYear:
            formattedString = "d MMM y"
        case .longDate:
            formattedString = "EEEE, MMMM d, y"
        case .longMonthDayYear:
            formattedString = "MMMM d y"
        case .longMonthYear:
            formattedString = "MMMM y"
        case .shortDate:
            formattedString = "M/d/y"
        case .shortDateLE:
            formattedString = "M/d/y"
        case .shortDateLELongTime:
            formattedString = "M/d/y h:mm:ss a"
        case .shortDateLELongTime24:
            formattedString = "M/d/y H:mm:ss"
        case .shortDateLEShortTime:
            formattedString = "M/d/y h:mm a"
        case .shortDateLEShortTime24:
            formattedString = "M/d/y H:mm"
        case .shortDateLongTime:
            formattedString = "M/d/y h:mm:ss a"
        case .shortDateLongTime24:
            formattedString = "M/d/y H:mm:ss"
        case .shortDateShortTime:
            formattedString = "M/d/y h:mm a"
        case .shortDateShortTime24:
            formattedString = "M/d/y H:mm"
        case .shortMonthYear:
            formattedString = "MMM y"
        case .year:
            formattedString = "y"
        default:
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = formattedString
        
        // ?
        // formatter.locale = Locale.current
        // ?
        
        return formatter
    }
}
