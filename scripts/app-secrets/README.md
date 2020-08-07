# secrets

Secrets attempts to solve a complex problem, simply; that is, how to include app secrets in an app's binary without including them in a source code repository.

## Solution

Create a build rule to parse a custom `.secret` text file, swapping keys with supplied values and output the derived file to a derived data folder. The program uses a simple parser to find bracket-key patterns and swap keys with values.

## Usage

The program takes a few parameters:

- i: input file
- s: secrets file
- o: output directory
- f: (optional) a flag to overwrite the output if a file already exists at the location

### Input File `-i`

The input file can be any text file with the extension `.secret`. The file is treated as a text file and as such any source code file can be used as a template. Say, for instance I wanted to generate swift source code to hold static keys, I could supply the program with a file named `AppSecrets.swift.secret` possibly formatted like so:

```swift
import Foundation

extension String {

    /// The App's public client ID.
    ///
    /// The client ID is used by oAuth to authenticate a user.
    ///
    /// _Note, change this to reflect your organization's client ID._
    /// The client ID can be found in the **Credentials** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    ///
    static let clientID: String = {
        let clientID = "{{ ARCGIS_CLIENT_ID }}"
        guard !clientID.isEmpty else {
            fatalError(".secrets must contain ARCGIS_CLIENT_ID variable.")
        }
        return clientID
    }()

    /// Your organization's ArcGIS Runtime [license](https://developers.arcgis.com/arcgis-runtime/licensing/) key.
    ///
    /// _Note, this step is optional during development but required for deployment._
    /// Licensing the app will remove the "Licensed for Developer Use Only" watermark on the map view.
    ///
    static let licenseKey: String = {
        let licenseKey = "{{ ARCGIS_LICENSE_KEY }}"
        guard !licenseKey.isEmpty else {
            #if DEBUG
            return "fake_inconsequential_license_key"
            #else
            fatalError(".secrets must contain ARCGIS_LICENSE_KEY variable.")
            #endif
        }
        return licenseKey
    }()
}
```

Note, there are two bracket-key placeholders in this file:

- `{{ ARCGIS_CLIENT_ID }}`
- `{{ ARCGIS_LICENSE_KEY }}`

### Secrets file `-s`

The secrets file is a plain-text file containing secrets stored as key/value pairs. One key/value pair should be stored per line. Secrets should follow a simple shell-like syntax:

```txt
ARCGIS_CLIENT_ID=fake-client-id
ARCGIS_LICENSE_KEY=fake-license-key
```

Note, keys found in this file match bracket-key placeholders found in the input file.

### Output directory `-d`

The program will generate a new file, preserving the input file name (while stripping `.secret`) and output the file to the supplied directory. For the above examples, the supplied output file `AppSecrets.swift` would look like so:

```swift
import Foundation

extension String {

    /// The App's public client ID.
    ///
    /// The client ID is used by oAuth to authenticate a user.
    ///
    /// _Note, change this to reflect your organization's client ID._
    /// The client ID can be found in the **Credentials** section of the **Authentication** tab within the [Dashboard of the ArcGIS for Developers site](https://developers.arcgis.com/applications).
    ///
    static let clientID: String = {
        let clientID = "fake-client-id"
        guard !clientID.isEmpty else {
            fatalError(".secrets must contain ARCGIS_CLIENT_ID variable.")
        }
        return clientID
    }()

    /// Your organization's ArcGIS Runtime [license](https://developers.arcgis.com/arcgis-runtime/licensing/) key.
    ///
    /// _Note, this step is optional during development but required for deployment._
    /// Licensing the app will remove the "Licensed for Developer Use Only" watermark on the map view.
    ///
    static let licenseKey: String = {
        let licenseKey = "fake-license-key"
        guard !licenseKey.isEmpty else {
            #if DEBUG
            return "fake_inconsequential_license_key"
            #else
            fatalError(".secrets must contain ARCGIS_LICENSE_KEY variable.")
            #endif
        }
        return licenseKey
    }()
}

```
