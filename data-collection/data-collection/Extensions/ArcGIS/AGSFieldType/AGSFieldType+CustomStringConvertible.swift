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

extension AGSFieldType: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .int16:
            return "Int16"
        case .int32:
            return "Int32"
        case .GUID:
            return "GUID"
        case .float:
            return "Float"
        case .double:
            return "Double"
        case .date:
            return "Date"
        case .text:
            return "Text"
        case .OID:
            return "OID"
        case .globalID:
            return "GlobalID"
        case .blob:
            return "Blob"
        case .geometry:
            return "Geometry"
        case .raster:
            return "Raster"
        case .XML:
            return "XML"
        }
    }
}
