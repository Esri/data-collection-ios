# Release 1.3

- Introduces an improved `AppContext` state-based architecture and more clear separation of responsibility. This architecture achieves more stability and resolves some found Portal related edge cases. Consult [docs](./docs/README.md#app-context) for more information.
- Dissolves `AppLocation` into sub-component of `AppContext`.
- Dissolves `AppGlobals` into `AppContext`.
- Dissolves `AppFiles` into `OfflineMapManager`.
- Removes `AppFonts` as it provides very little utility.
- Removes `NetworkReachabilityManager` as a first class state mechanism allowing app to determine reachability with every network request, removes `Alamofire` swift package.
- Reformats `AppConfiguration` to be more clear.
- Introduces `GlobalAlertQueue`, a utility for enqueueing and presenting alerts in a stand-alone alert window (`UIWindow`). This change improves the reliability of presenting alerts from any app component - context, view, or otherwise.
- Introduces nuanced offline map icons in Profile view.
- Dissolves `AppError` protocol, reconsiders errors instead as members of types.
- Fixes bug where `AddressLocator.onlineLocator` issues an authentication challenge amid creating a new feature.
- Introduces support for iOS 14 PHPickerViewController.
- Removes `SVProgressHUD` dependency, introduces `ProgressViewController` global presenter.
- Introduces `FloatingPanelController` for displaying information in a customizable panel which "floats" about the map.
- Moves the **Bookmarks** and **Layers** views into a `FloatingPanelController`.
- Adds support for displaying multiple identify results from all identifiable layers in a map.
- Adds Dark Mode support in the `RichPopupViewController`.

# Release 1.2.3

- The 100.10.0 release of the ArcGIS Runtime for iOS is now distributed as a binary framework.  This necessitated the following changes in the Data Collection Xcode project file:
    - The `ArcGIS.framework` framework has been replaced with `ArcGIS.xcframework`.
    - The Build Phase which ran the `strip-frameworks.sh` shell script is no longer necessary.
- Certification for the 100.10 release of the ArcGIS Runtime SDK for iOS.
- Updates the ArcGIS Runtime Toolkit submodule to the 100.10 version.
- Increments app and testing deployment targets to iOS 13.0, drops support for iOS 12.0.
- Introduces pop-up date attribute editing support for the new iOS 14 `UIDatePicker`.
- Introduces pop-up date attribute editing support for time as well as date.
- Fixes bug where `SegmentedViewController` does not respond to `segmentedControl`'s `.valueChanged` event.
- Fixes bug where `MapViewController` does not update current pop-up after edits are performed.
- On iOS 14, when adding image attachments to features using the user's "Photo Library", the "Selected Photos" privacy option is not yet supported.  The user will need to grant the app permission to use "All Photos".

# Release 1.2.2

- Introduces new technique for managing [app secrets](./docs#app-configuration).
- At v100.6.0 the ArcGIS Runtime SDK for iOS introduced a [method](https://developers.arcgis.com/ios/latest/api-reference/interface_a_g_s_credential_cache.html#a0796cf2506fa0edfdeb2b62198bbbea7) to remove and revoke all credentials. Data Collection now uses that method to revoke the portal user's credential on the server side.
- Certification for the 100.9.0 release of the ArcGIS Runtime SDK for iOS.
- Updates the ArcGIS Runtime Toolkit submodule to the 100.9.0 version.

# Release 1.2.1

- Renames, updates, and fixes `AddressLocator` (formally `AppReverseGeocoderManager`).
- Swaps _App Container_ & _Drawer_ for _Profile_.
    - Introducing a user experience familiar to iOS users and more in line with the HIG.
    - Introduces calcite iconography.
    - Simplifies app architecture.
- Adds doc table of contents to root README.md and docs/README.md
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
