# Release 1.2.1

- Adds doc table of contents to root README.md and docs/index.md
- Renames docs/index.md to [docs/README.md](/docs/README.md)

# Release 1.2.0

- Adds an "Extras" button containing "Bookmarks" and "Layers" options:
    - Bookmarks:  users can select from a list of web map-defined bookmarks to easily navigate their map.
    - Layers: users can view the layers and symbology in their map and turn the display of layers on and off.
- Incorporate the [ArcGIS Runtime Toolkit for iOS](https://github.com/Esri/arcgis-runtime-toolkit-ios) as a git submodule to provide the BookmarksViewController component.
- Improves some organization of the code.
- Fix build-time warning when building with XCode 11.4 (in LoadableErrors.swift).
- Adds Alamofire dependency as a Swift Package. Updates using the latest `NetworkReachabilityManager` API.
- Improves how the app maintains static configurations.
- Certification for the 100.8.0 release of the ArcGIS Runtime SDK for iOS.

# Release 1.1.4

- Fixes featureLayer deprecation.
- Updates minimum deployment target to match that supported by ArcGIS iOS Runtime SDK.
- Turns off metal validation -> fixes iOS 12 device crash.
- New bundle ID.

# Release 1.1.3

- Certification for the 100.7.0 release of the ArcGIS Runtime SDK for iOS.

# Release 1.1.2

- Fix for [iPad crash](https://github.com/Esri/data-collection-ios/issues/209).
- Fix for [illegal attachment name characters](https://github.com/Esri/data-collection-ios/issues/188).
- Adds [app documentation](/docs/README.md) from the ArcGIS for Developers site.

# Release 1.1.1

- Support for iOS 13

# Release 1.1

## Major Features and Improvements

**RichPopup, Relationships, RichPopupViewController**

- Introduces `RichPopup` which retrieves related records via an `AGSLoadable` implementation.
- As a result, `RichPopupViewController` has undergone a series of changes, bug fixes, and upgrades.

**Attachments**

- View and edit pop-up photo attachments. Add new attachments from a camera or library.

**AppErrors**

- Consolidates and streamlines error handling.

**Accessibility**

- UI elements now leverage Dynamic Type to improve accessibility.
- High contrast colors are added to improve accessibility.

**AppColors**

- This release contains a massive overhaul of `AppColors.swift`. House colors are made global via the Xcode asset catalog `HouseColors.xcassets`. House colors can be accessed both in storyboards and in code (conforming to `UIApperance`). Specify your organization's colors in the Xcode asset catalog and see your colors change throughout the app.

# Release 1.0

**Initial Release**

An example app used for collecting survey data about city trees in Portland, Oregon. The application can easily be modified to access the web maps in your own organization's portal.

Mobile Data Collection leverages several aspects of the Runtime SDK including:

- Portal authentication
- Map feature identification
- Feature table CRUD operations
- Feature table querying for records
- Feature table relating records
- Popups management
- Reverse geocoding using the world geocoder service
- Generating offline map
- Supporting offline map data collection workflow
- Synchronizing offline map geodatabase changes
