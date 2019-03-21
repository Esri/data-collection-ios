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
- Higher contrast colors are chosen to improve accessibility.

**AppColors**

- This release contains a massive overhaul of `AppColors.swift`. The app globalizes house colors via an Xcode asset catalog named `HouseColors.xcassets`. House colors can be accessed both in storyboards and in code (and conformance to `UIApperance`). Specify your organization's colors in the Xcode asset catalog and see your colors across the app.

# Release 1.0

**Initial Release**

An example app used for collecting survey data about city trees in Portland, OR, built generic such that your organization can access its own portal web maps with little to no changes to code.

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
