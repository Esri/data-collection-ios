//// Copyright 2020 Esri
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

extension String {

    /// Your organization's ArcGIS Runtime [license](https://developers.arcgis.com/arcgis-runtime/licensing/) key.
    ///
    /// - Add your license key:
    ///   - click **Product** -> **Scheme** -> **Edit Scheme**
    ///   - select **Run** -> **Arguments**
    ///   - add **Environment Variable**:
    ///       - name: `"ARCGIS_LICENSE_KEY"`
    ///       - value: `"your-license-key"`
    ///
    /// _Note, this step is optional during development but required for deployment._
    /// Licensing the app will remove the "Licensed for Developer Use Only" watermark on the map view.
    ///
    static let licenseKey: String = {
        let licenseKeyEnvironmentKey = "ARCGIS_LICENSE_KEY"
        guard let licenseKey = ProcessInfo.processInfo.environment[licenseKeyEnvironmentKey] else {
            #if DEBUG
            return "fake_inconsequential_license_key"
            #else
            fatalError("Scheme must include \"\(licenseKeyEnvironmentKey)\" environment variable.")
            #endif
        }
        return licenseKey
    }()
    
    /// The App's public client ID.
    ///
    /// The client ID is used by oAuth to authenticate a user.
    ///
    /// - Add your client ID:
    ///   - click **Product** -> **Scheme** -> **Edit Scheme**
    ///   - select **Run** -> **Arguments**
    ///   - add **Environment Variable**:
    ///       - name: `"ARCGIS_CLIENT_ID"`
    ///       - value: `"your-client-id"`
    ///
    /// _Note, change this to reflect your organization's client ID._
    /// The client ID can be found in the **Credentials** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    ///
    static let clientID: String = {
        let clientIDEnvironmentKey = "ARCGIS_CLIENT_ID"
        guard let clientID = ProcessInfo.processInfo.environment[clientIDEnvironmentKey] else {
            fatalError("Scheme must include \"\(clientIDEnvironmentKey)\" environment variable.")
        }
        return clientID
    }()
}
