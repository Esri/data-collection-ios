# Release 1.1

## Major Features and Improvements

- UI elements dynamic font sizing is introduced to improve accessibility.
- Higher contrast colors are chosen to improve accessibility.
- Massive overhaul of `AppColors`. Specifying colors has moved from storyboards into code. Statically set your organizations colors and see those colors accross the app through conformance to `UIApperance`.

# Release 1.0

**Initial Release**

An example app used for collecting survey data about city trees in Portland, OR, built generic such that your organization can access it's own portal web maps with little to no changes to code.

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
