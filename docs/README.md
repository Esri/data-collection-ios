# Contents

<!-- MDTOC maxdepth:6 firsth1:0 numbering:0 flatten:0 bullets:1 updateOnSave:1 -->

- [Description](#description)   
   - [Generic application](#generic-application)   
   - [Trees of Portland](#trees-of-portland)   
   - [Custom behavior](#custom-behavior)   
- [Using the app](#using-the-app)   
   - [Manage the app's context](#manage-the-apps-context)   
      - [Sign in and out of Portal](#sign-in-and-out-of-portal)   
      - [App work mode](#app-work-mode)   
   - [View map extras](#view-map-extras)   
   - [View map bookmarks](#view-map-bookmarks)   
   - [View the map's layers](#view-the-maps-layers)   
   - [Identify map features](#identify-map-features)   
   - [Add map feature](#add-map-feature)   
   - [Rich pop-ups](#rich-pop-ups)   
   - [View and edit data with pop-ups](#view-and-edit-data-with-pop-ups)   
      - [View a pop-up](#view-a-pop-up)   
      - [Edit a feature](#edit-a-feature)   
- [Using web maps](#using-web-maps)   
   - [Configure web map & feature services for data collection](#configure-web-map-feature-services-for-data-collection)   
      - [Map title](#map-title)   
      - [Organizing feature layers](#organizing-feature-layers)   
      - [Feature layer visibility range](#feature-layer-visibility-range)   
      - [Enable editing on feature layers and tables](#enable-editing-on-feature-layers-and-tables)   
      - [Enable pop-up on feature layers and tables](#enable-pop-up-on-feature-layers-and-tables)   
      - [Configure pop-up on feature layers and tables](#configure-pop-up-on-feature-layers-and-tables)   
      - [Enable attachments on feature layers](#enable-attachments-on-feature-layers)   
- [Identity model](#identity-model)   
   - [Public map, social login](#public-map-social-login)   
- [Using map definition & pop-up configurations to drive app behavior](#using-map-definition-pop-up-configurations-to-drive-app-behavior)   
   - [Map identify rules](#map-identify-rules)   
   - [Small pop-up view rules](#small-pop-up-view-rules)   
   - [Add feature rules](#add-feature-rules)   
   - [Pop-up view rules](#pop-up-view-rules)   
      - [View mode](#view-mode)   
      - [Edit mode](#edit-mode)   
- [Consuming ArcGIS](#consuming-arcgis)   
   - [Identifying map features](#identifying-map-features)   
   - [Offline map jobs](#offline-map-jobs)   
      - [Download map offline](#download-map-offline)   
      - [Synchronize offline map](#synchronize-offline-map)   
      - [Job status view controller](#job-status-view-controller)   
      - [Deleting offline map](#deleting-offline-map)   
   - [Querying feature tables](#querying-feature-tables)   
      - [Query for all features](#query-for-all-features)   
      - [Query for related features](#query-for-related-features)   
      - [Spatial query](#spatial-query)   
   - [Editing features](#editing-features)   
      - [Creating features](#creating-features)   
      - [Rich pop-up](#rich-pop-up)   
      - [Editing features lifecycle](#editing-features-lifecycle)   
      - [Editing related records](#editing-related-records)   
      - [Editing attachments](#editing-attachments)   
   - [Reverse geocoding](#reverse-geocoding)   
- [Architecture](#architecture)   
   - [App configuration](#app-configuration)   
   - [App secrets](#app-secrets)   
      - [Masquerade](#masquerade)   
      - [Build rule](#build-rule)   
         - [Usage](#usage)   
   - [App context](#app-context)   
      - [App context change handler](#app-context-change-handler)   
   - [Model: Pop-up configuration driven](#model-pop-up-configuration-driven)   
   - [View: storyboards](#view-storyboards)   
      - [Custom views](#custom-views)   
   - [Controller: app context aware](#controller-app-context-aware)   
   - [App location](#app-location)   
   - [Network reachability manager](#network-reachability-manager)   
   - [Ephemeral cache](#ephemeral-cache)   
   - [File manager](#file-manager)   
   - [App defaults](#app-defaults)   
   - [App colors & fonts](#app-colors-fonts)   
   - [App errors](#app-errors)   
- [Xcode project configuration](#xcode-project-configuration)   
   - [Privacy strings](#privacy-strings)   

<!-- /MDTOC -->
---
## Description

Collect data in an app consuming your organization's web maps driven by the ArcGIS Web GIS information model. We provide an example *Trees of Portland* web map and dataset to get you started.

### Generic application

The app was designed to work in a generic context and thus your organization can configure the app to consume your own web map, out of the box. To accomplish this, first the web map is configured by a set of rules and then the app adheres to that same set of rules, driving the app's behavior. These rules are defined by the map's definition and by the map's layers' pop-up configurations. To learn more about what drives the app's behavior, read the section entitled [_Using Map Definition & Pop-up Configurations to Drive App Behavior_](#using-map-definition--pop-up-configurations-to-drive-app-behavior).

### Trees of Portland

The capabilities of the app can be demonstrated using *Trees of Portland*, a web map hosted and maintained by the Esri ArcGIS Runtime organization that ships with the app by default. *Trees of Portland* tells the story of a city arborist or engaged citizens who maintains inspections for all street trees in the city of Portland, OR.

Users can identify existing or create new street trees of a certain species on a map. Street trees are symbolized on a map based on their condition. Users can collect or view inspection records of those trees over time. The map also contains a symbolized neighborhoods layer to help distribute inspection regions.

The *Trees of Portland* dataset schema is simple.

![Trees of Portland dataset schema](/docs/images/dataset-schema.png)

A street tree can be one of many species and a street tree can contain zero to many inspection records. A neighborhood is a spatial feature symbolized on the map that does not relate to other tables.

_The neighborhood layer is not related to the other layers and provides the map with a visual context through the use of symbology. The neighborhood layer is queried to populate an attribute of the tree layer._

### Custom behavior

There are a select few custom behaviors displayed in this example application that help tell the *Trees of Portland* story that won't fit a generic context. The app only performs these custom behaviors if the current map's portal item id matches that of the *Trees of Portland* web map. In the event a different map is configured, these custom behaviors are ignored. These custom behaviors accomplish the following:

* Upon the creation of a new street tree feature, the app reverse geocodes the tree's location for an address to populate the tree feature's attributes.
* Upon the creation of a new street tree feature, the app queries the neighborhood feature layer for features where the new tree's location falls within the neighborhood's polygon.
* A third customization addresses a current limitation in the SDK. As noted earlier, the symbology in the web map reflects a tree's last reported condition. Representing symbology based on a related record is not yet available in the SDK. In this app, custom logic is applied whenever a tree inspection is updated or added. All inspections for the given tree are sorted in descending order by inspection date. The condition and DBH (diameter at breast height) of the most recent inspection are used to update the corresponding fields in the tree feature table. In this way, the symbology in the web map reflects the latest inspection.

While these custom behaviors may not work with your web map, they illustrate best practices for using the ArcGIS Runtime SDK. You can remove this custom behavior logic altogether, if you prefer.

## Using the app

The app launches to a navigation based application containing a map view.

![map](/docs/images/map.png)

The navigation bar's title reflects the name of the web map and the navigation bar button items are as follows:

| Icon | Description |
|:----:| ----------- |
| ![Profile](/docs/images/profile-nav.png) | Show user profile and online/offline map context. |
| ![Zoom To Location](/docs/images/zoom-to-location.png) | Zoom to user's location. |
| ![Add Feature](/docs/images/add-feature.png) | Add a new spatial feature to map. |
| ![Extras](/docs/images/ellipsis.png) | Extras button to access Layers and Bookmarks. |

### Manage the app's context

Tapping the navigation bar's hamburger button reveals the app context drawer view.

![App Context Drawer View](/docs/images/profile.png)

#### Sign in and out of Portal

Upon first launch the user is not authenticated and the app does not prompt for authentication. To sign in, the user can tap the navigation bar's hamburger button to reveal the app context drawer view. Once revealed, the user can tap 'Sign in'. A modal login view presents, prompting for the user's portal username and password. If valid credentials are provided, an authenticated user is associated with the portal and their credentials are stored in the local credentials cache, for auto-sync to the device's keychain.

Upon successfully signing in, the button that previously read 'Sign in' now reads 'Sign out' and tapping the button now signs the user out and removes the user from the local credentials cache.

#### App work mode

The app supports a workflow for users in the field with the requirement to work both in connected (online) and disconnected (offline) environments.

**Online Work Mode**

At initial launch the app loads the configured portal's public web map. The map can identify features and make edits. Edits can be made to the web map including adding new, updating existing and deleting records.

> Because *Trees of Portland* is a public web map with public layers it does not require authentication for access.

**Offline Work Mode**

A user may need to collect data in a location where they are disconnected from the network. The app allows the user to take a web map offline.

> Because *Trees of Portland* uses a premium content basemap, a user must be authenticated to fully take the web map offline.

![Download Map Offline Extent](/docs/images/offline-extent.png)

When taking the web map offline, the app asks the user to specify the area of the web map they want to take offline for storage in the device's documents directory following the offline map creation [on-demand workflow](https://developers.arcgis.com/ios/latest/swift/guide/take-map-offline-on-demand.htm). After the generate offline map job finishes, the app enters offline work mode and loads the offline mobile map package.

> If you perform this behavior using *Trees of Portland* you should expect the download job to take 10 minutes or so to complete.

Edits made to the offline mobile map's geodatabase remain offline until the user returns to a network connected environment where then they can bi-directionally synchronize changes made to the offline geodatabase with those made to the online web map.

If a user elects to delete the offline map, the app deletes the offline mobile map package from the device's documents directory and switches to online work mode.

> A user can resume work online without deleting the offline map.

### View map extras

Selecting the map Extras button displays allows you to choose either "Layer" or "Bookmarks".

![Screenshot showing map extras on iPhone](/docs/images/extras.png)

### View map bookmarks

Web maps can include a list of bookmarks. Each bookmark consists of a map extent (visible area) and a name. Bookmarks can be authored in ArcGIS Pro and the ArcGIS Web Map Viewer.

You can select the Bookmark item in Extras to see a list of bookmarks in the map. Selecting a bookmark will show that bookmark's extent.

![Screenshot showing bookmarks on iPhone](/docs/images/bookmarks.png)

### View the map's layers

You can select the Layers item in Extras to view the symbology for each layer. You can "flip" the switch control to hide or show each layer. Selecting the "chevron" button to the left of the layer name will hide or show the symbology, if any, for each layer.

![Screenshot showing layers on iPhone](/docs/images/layers.png)

### Identify map features

Tapping the map performs an identify function on the map. One best result is chosen, a small pop-up view is revealed and the feature is selected on the map. If no results are found, the user is notified.

![Identified Map Feature](/docs/images/identify.png)

Tapping the small pop-up view presents modally a full pop-up view for deeper interrogation of the data.

If the selected pop-up's feature table contains a one-to-many relationship to another table, a plus button is be revealed. Tapping the plus button creates a new one-to-many related record and presents this pop-up in full pop-up view edit mode.

### Add map feature

If the map contains a spatial feature layer that adheres to the rules specified in the section entitled [_Add Feature Rules_](#add-feature-rules), the add feature button is enabled. Tapping this button begins the process of adding a new record to the map.

If there is more than one eligible feature layer, a modal action sheet is presented, prompting the user to select onto which layer they would like to add a new feature. If there is only one eligible feature layer, the app selects this layer.

![Add New Feature](/docs/images/new-feature.png)

An action banner appears and a pin drops to the center of the map view. The action banner contains a select and a cancel button. The pin remains fixed to the center of the map view as the map is panned and zoomed beneath it. If the user taps the select button, a new feature is created using the fixed map view's center point translated to a spatial coordinate.

### Rich pop-ups

The app supports pop-ups with related records (related tables) and attachments. This enriched pop-up workflow is encapsulated into a series of tools with the prefix 'RichPopup' including a concrete subclass of `AGSPopup` itself named `RichPopup`.

### View and edit data with pop-ups

After identifying a pop-up, tapping the small pop-up view modally presents that pop-up in a more detailed pop-up view.

#### View a pop-up

A full screen table-based view controller allows the user to interrogate the map view's selected pop-up in greater detail. The table-based view is broken down into a number of sub-components.

![View A Pop-up](/docs/images/pop-up.png)

The first section displays each attribute configured for display. Following the display attributes are each many-to-one related records. In the *Trees of Portland* web map the trees table has one many-to-one relationship, the species table.

Sections that follow represent every one-to-many related records with the header of that section the name of the related table and an add new button, if that table allows adding new features. In the *Trees of Portland* web map the trees table has one one-to-many relationship, the inspections table, which does allow adding new features.

Related record cells can be tapped and allows the user to interrogate the related record for more information.

If the feature's table is configured for attachments, a segmented control reveals the option to view a list of attachments. Individual attachments can be viewed in full screen and shared.

If the feature can be deleted from its containing table, a delete feature button is revealed at the bottom of the view.

To begin an editing session, the user can tap the 'Edit' button located in the navigation bar.

#### Edit a feature

The app edits features using the `AGSPopup`/`AGSPopupManager` API.

Starting an edit session enables the user to edit the pop-up's attributes, related records and attachments all at once.

The pop-up's attributes configured as editable can be edited and validated inline within the same pop-up view.

![Edit A Pop-up](/docs/images/pop-up-edit.png)

As values for fields are updated, the app informs the user of invalid changes and why it's invalid. The pop-up won't save if there are invalid fields.

Edits can be discarded by tapping 'Cancel' in the navigation bar. Saving the changes requires every field to pass validation and can be committed by tapping 'Done' in the navigation bar.

**Editing a Pop-up's Related Records**

For related records where the pop-up is the child in the related record relationship (a many-to-one related record) the app allows the user to update to which parent record is related. In the *Trees of Portland* web map this means a user can update the tree's species related record.

**Editing a Pop-up's Attachments**

New attachments can be added to a pop-up using the device's camera or from the device's image library. Before persisting new photo attachments, users have the option to specify an attachment name and preferred content size.

Existing attachments can be deleted from the pop-up.

## Using web maps

You can author your own web maps in [Portal/ArcGIS Online](https://enterprise.arcgis.com/en/portal/latest/use/what-is-web-map.htm) or [ArcGIS Desktop](https://desktop.arcgis.com/en/maps/) and share them in your app via your Portal; this is the central power of the Web GIS model built into ArcGIS. Building an app which uses a web map allows the cartography and map configuration to be completed in Portal rather than in code. This then allows the map to change over time, without any code changes or app updates. Learn more about the benefits of developing with web maps [here](https://developers.arcgis.com/web-map-specification/). Also, learn about authoring web maps in [Portal/ArcGIS Online](https://doc.arcgis.com/en/arcgis-online/create-maps/make-your-first-map.htm) and [ArcGIS Pro](https://pro.arcgis.com/en/pro-app/help/mapping/map-authoring/author-a-basemap.htm).

Loading web maps in code is easy; the app loads a web map from a Portal (which may require the user to login, see the [_identity model_](#identity-model) section) with the following code:

``` Swift
let portal = AGSPortal(url: URL(string: "https://<your portal url>")!, loginRequired: false)
let webMapItem = AGSPortalItem(portal: portal, itemID: "<your map id>")
mapView.map = AGSMap(item: webMapItem)
```

### Configure web map & feature services for data collection

The app's behavior is configuration driven and the following configuration principles should guide you in the configuration of your **own** web map.

> Always remember to save your web map after changes have been performed!

#### Map title

The web map's title becomes the title of the map in the map view's navigation bar.

> A succinct, descriptive title is recommended because some screen sizes are quite small.

#### Organizing feature layers

The [order](https://doc.arcgis.com/en/arcgis-online/create-maps/organize-layers.htm) of your web map's [feature layers](https://doc.arcgis.com/en/arcgis-online/reference/feature-layers.htm) matter. Layer precedence is assigned to the top-most layer (index 0) first with the next precedence assigned to the next layer beneath, and so on. This is important because only one feature can be identified at a time. When the app performs an identify operation, the layer whose index is nearest 0 and which returns results is the one whose features will be selected.

#### Feature layer visibility range

It is generally recommended to consider the [visibility range](https://doc.arcgis.com/en/arcgis-online/create-maps/set-visibility.htm) of your feature layers. Beyond this general consideration, only visible layers are returned when an identify operation is performed. You'll want to consider which layers to make visible at what scale.

#### Enable editing on feature layers and tables

You'll want to consider whether to enable or disable [editing](https://doc.arcgis.com/en/arcgis-online/manage-data/edit-features.htm) of your feature layers and tables. Specifically, a user is only able to edit features or records on layers whose backing table has editing enabled. This includes related records for features. For instance, if a feature whose backing table does permit editing has a related record backed by a table that does not have editing enabled, that related record layer cannot be edited by the app.

#### Enable pop-up on feature layers and tables

The app relies on pop-up configurations to identify, view, and edit features and records. You'll want to consider whether to enable or disable [pop-ups](https://doc.arcgis.com/en/arcgis-online/create-maps/configure-pop-ups.htm#ESRI_SECTION1_9E13E02AABA74D5DA2DF1A34F7FB3C63) of your feature layers and tables. Only feature layers and tables that are pop-up-enabled can be identified, displayed, or edited. Please note, you can have a scenario where you've enabled editing on a layer (as described above) but have disabled pop-ups for the same layer and thus a user is not be able to edit this layer.

#### Configure pop-up on feature layers and tables

For all layers with pop-ups enabled, you'll want to consider how that pop-up is [configured](https://doc.arcgis.com/en/arcgis-online/create-maps/configure-pop-ups.htm#ESRI_SECTION1_0505720B006E43C5B14837A353FFF9EC) for display and editing.

**Pop-up Title**

You can configure the pop-up title with a static string or formatted with attributes. The pop-up's title becomes the title of the pop-up containing view controller's navigation bar. A succinct, descriptive title is recommended because some screen sizes are quite small.

**Pop-up Display**

It is recommended to configure your pop-ups such that their content's [display property](https://doc.arcgis.com/en/arcgis-online/get-started/view-pop-ups.htm) is set to **a list of field attributes**. Using this configuration allows you to designate the display order of that table's attributes. This is important because various visual representations of pop-ups in the app are driven by the attributes display order.

> With the Configure Pop-up pane open, under Pop-up Contents the display property provides a drop down list of options, select **a list of field attributes**.

**Pop-up Attributes**

Precedence is assigned to top-most attributes first (index 0) with the next precedence assigned to the subsequent attributes. Individual attributes can be configured as display, edit, both, or neither.

> With the Configure Attributes window open, attributes can be re-ordered using the up and down arrows.

Within the app, a pop-up view can be in display mode or edit mode and attributes configured as such are made available for display or edit.

These attributes' values are accompanied by a title label, which is configured by the attribute's field alias. It is recommended to configure the field alias with a label that is easily understood to represent what is contained by that field.

#### Enable attachments on feature layers

You'll want to consider which feature layers should enable [attachments](https://doc.arcgis.com/en/arcgis-online/manage-data/manage-hosted-feature-layers.htm). Only feature layers with attachments will reveal attachments in the pop-up view.

## Identity model

The app leverages the ArcGIS [identity](https://developers.arcgis.com/authentication/) model to provide access to resources via the [named user](https://developers.arcgis.com/documentation/core-concepts/security-and-authentication/#named-user-login) login pattern. When accessing services that require a named user, the app prompts you for your organization’s portal credentials used to obtain a token. The ArcGIS Runtime SDKs provide a simple-to-use API for dealing with ArcGIS logins.

The process of accessing token secured services with a challenge handler is illustrated in the following diagram.

![ArcGIS Identity Model](/docs/images/identity.png)

1. A request is made to a secured resource.
2. The portal responds with an unauthorized access error.
3. A challenge handler associated with the identity manager is asked to provide a credential for the portal.
4. An authentication UI presents modally and the user is prompted to enter a user name and password.
5. If the user is successfully authenticated, a credential (token) is included in requests to the secured service.
6. The identity manager stores the credential for this portal and all requests for secured content includes the token in the request.

The `AGSOAuthConfiguration` class takes care of steps 1-6 in the diagram above. For an application to use this pattern, follow these [guides](https://developers.arcgis.com/authentication/signing-in-arcgis-online-users/) to register your app.

``` Swift
let oauthConfig = AGSOAuthConfiguration(portalURL: portal.url, clientID: clientId, redirectURL: oAuthRedirectURL)
AGSAuthenticationManager.shared().oAuthConfigurations.add(oauthConfig)
```

Any time a secured service issues an authentication challenge, the `AGSOAuthConfiguration` and the app's `UIApplicationDelegate` work together to broker the authentication transaction. The `oAuthRedirectURL` above tells iOS how to call back to the app to confirm authentication with the Runtime SDK.

iOS routes the redirect URL through the `UIApplicationDelegate` which the app passes directly to an ArcGIS Runtime SDK helper function to retrieve a token:

``` Swift
// UIApplicationDelegate function called when "data-collection://auth" is opened.
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

    // Pass the OAuth callback through to the ArcGIS Runtime helper function
    AGSApplicationDelegate.shared().application(app, open: url, options: options)

    // Let iOS know we handled the URL OK
    return true
}
```

To tell iOS to call back like this, the app configures a `URL Type` in the `Info.plist` file.

![OAuth URL Type](/docs/images/configure-url-type.png)

Note the value for URL Schemes. Combined with the text `auth` to make `data-collection://auth`, this is the [redirect URI](https://developers.arcgis.com/authentication/browser-based-user-logins/#configuring-a-redirect-uri) that you configured when you registered your app on your [developer dashboard](https://developers.arcgis.com/applications). For more details on the user authorization flow, see the [Authorize REST API](https://developers.arcgis.com/rest/users-groups-and-items/authorize.htm).

For more details on configuring the app for OAuth, see [the main README.md](/README.md).

### Public map, social login

A user does not need to authenticate in order to make edits to the *Trees of Portland* web map. However, authentication will allow the services to track who makes edits. In the event a user wants to perform an action that does require authentication, the SDK will prompt the user to sign in if they are not signed in already. Actions that require authentication in *Trees of Portland* include:

- Taking the web map offline, the base map is premium content.
- Reverse geocoding using the world geocoder service.

The app allows a user to authenticate against a portal as well as use social credentials. If a user chooses to authenticate with social credentials and an account is not associated to those credentials, [ArcGIS online](https://doc.arcgis.com/en/arcgis-online/reference/sign-in.htm) creates an account for you. Note that a map cannot be taken offline unless the user is authenticated with Portal credentials.

> There may be additional considerations to make if your portal's web map is configured differently.

## Using map definition & pop-up configurations to drive app behavior

The app operates on a set of rules driven by map definitions and pop-up configurations. To learn how to configure your web map, see the section entitled [_Configure Web Map & Feature Services for Data Collection_](#configure-web-map--feature-services-for-data-collection).

### Map identify rules

A tap gesture on the map view performs an identify function where only results for layers that adhere to certain rules are considered. These rules ask that the layer is visible, is of point type geometry and pop-ups are enabled.

These rules are wrapped conveniently into a static class named `AppRules`.

```swift
static func isLayerIdentifiable(_ layer: AGSFeatureLayer) -> Bool {
    guard
        layer.isVisible,
        let featureTable = layer.featureTable,
        featureTable.geometryType == .point,
        featureTable.isPopupActuallyEnabled else {
            return false
    }
    return true
}
```

> `isPopupActuallyEnabled` facilitates checking both that pop-up is enabled for the table and the pop-up definition is not nil.

### Small pop-up view rules

After the identify function returns a single successful result, the app selects the result on the map and populates a small pop-up view (contained by a `ShrinkingView`, see the section entitled [_Custom Views_](#custom-views)).

The small pop-up view prioritizes related record content over content derived from its own attributes.

![Small Pop-up View](/docs/images/anatomy-small-popup-view.png)

To understand how the small pop-up view populates it's content, divide the view in half leaving a left and right side, each with two UI elements.

The left side concerns itself with the selected pop-up's many-to-one related records whereas the right side concerns itself with the selected pop-up's one-to-many related records.

The left side chooses the top-most many-to-one related table, if there is one, and populates the view's upper label with the top-most attribute and bottom label with the next attribute, if possible. If not possible, content for either label is derived by the selected pop-up's top-most attribute successively.

The right side chooses the top-most one-to-many related table, if there is one, and populates the bottom label with (n) records for that table name. If not possible, content for this label is derived by the selected pop-up's attributes successively. The circular plus button emerges if the top-most one-to-many related table allows the adding of new features. Tapping this button creates a new related record.

### Add feature rules

A user can add new spatial features to the map given those feature layers adhere to certain rules. An `AGSFeatureLayer` can add an `AGSArcGISFeature` to a layer if:

* the layer is editable
* the layer can add a feature
* the layer is a spatial layer of geometry type: point
* the layer has enabled pop-ups

These rules are wrapped conveniently into a static class named `AppRules`.

```swift
static func isLayerAddable(_ layer: AGSFeatureLayer) -> Bool {
    guard
        let featureTable = layer.featureTable,
        featureTable.isEditable,
        featureTable.canAddFeature,
        featureTable.geometryType == .point,
        featureTable.isPopupActuallyEnabled else {
            return false
    }
    return true
}
```

If no feature layers adhere to these rules, the add feature button is disabled. If 2 or more feature layers adhere to these rules, the app prompts the user to select the desired layer. And, if only one layer adheres to these rules, that layer is selected automatically.

### Pop-up view rules

A `RichPopupViewController` was designed to view and edit a pop-up, its one-to-many and many-to-one related records, and its attachments. The view controller state can be either view mode or edit mode, each permitting certain user interaction. The `RichPopupViewController` is tightly coupled to its `RichPopup` and `RichPopupManager`. To learn more about the `RichPopupManager`, see the section entitled [_Editing Features_](#editing-features).

#### View mode

The title of the view controller reflects the title of the pop-up as configured in portal. The view controller is segmented in two. The first segment shows attribute and related record content and the second segment shows attachments.

![Pop-up View Anatomy Relationships](/docs/images/anatomy-popup-view-relationships.png)

**Pop-up Attributes**

The first section *(index 0)* is the attributes section. Every field determined by the manager's `displayFields` is represented by its own cell. Every attribute cell in the table eventually adheres to the `PopupAttributeCell` protocol and provides the cell the ability to popuplate a title and value for a pop-up field.

**Many-To-One Records**

Following the attributes, a `PopupRelatedRecordCell` represents each many-to-one related record associated with the pop-up. The order of the records is determined by the popup's feature's `relatedRecordsInfos`. The cell displays the first two display attributes of the related record.

A user can tap the related record cell (indicated by an accessory view). Doing so reveals a new `RichPopupViewController` containing the related record.

> The number of attributes displayed in a related record cell is configured in `RelatedRecordsConfiguration`.

**One-To-Many Records**

Every subsequent section *(index 1...n)* represents a collection of one-to-many related records, one section for every one-to-many related record type. The header label for that section reflects the table name of the related record's feature table. If the section's table permits adding new features, the first cell of this section allows the user to add a new related record of that section type. Every subsequent cell represents a single one-to-many record and displays the first three display attributes of the related record.

A user can tap the related record cell (indicated by an accessory view). Doing so reveals a new `RelatedRecordsPopupsViewController` containing the related record.

> Editing one-to-many related records (add/update/delete) is **only** permitted in view mode. This is because the app needs to close one editing session before beginning the next.

**Attachments**

A segmented control permits viewing pop-up attachments, only if the feature layer has enabled attachments. The attachments are presented in a [filtered and sorted](https://developers.arcgis.com/ios/latest/api-reference/interface_a_g_s_popup_attachment_manager.html#a688184f79b8819584de1d13bfb57d392) list. Tapping an attachment modally presents a view controller that offers the ability to inspect the attachment with closer detail and to share the attachment. Most attachment types are [supported](https://developers.arcgis.com/rest/services-reference/query-attachments-feature-service-layer-.htm).

> You can check if a feature layer has enabled attachments either from its item page, or by confirming its service has configured the property `"hasAttachments": true`.

**Delete Pop-up**

The toolbar contains a delete button. The toolbar and button are revealed only if the table permits deleting the feature.

#### Edit mode

Starting an editing session requires that the `PopupRelatedRecordsManager` allows editing, and that the editing session started properly. If started properly, the UI reflects the edit mode state.

**Pop-up Attributes**

Every field determined by the manager's `editableDisplayFields` is represented by its own cell. The app accommodates various geodatabase data types through conformance to the `PopupAttributeCell` protocol. Tapping on that cell's first responder triggers the presentation of a keyboard that is configured or customized by the cell's field type. These editable field cells include:

* `PopupAttributeTextFieldCell`: Int16, Int32, Float, Double, Strings (single line)
* `PopupAttributeTextViewCell`: Strings, multi line and rich text. (The only cell that uses a text view.)
* `PopupAttributeDomainCell`: Coded Value Domains, of any data type. _Overrides keyboard input view with picker view._
* `PopupAttributeDateCell`: Date. _Overrides keyboard input view with a date picker view._
* `PopupAttributeReadonlyCell`: GUID, OID, globalID, unknown.

> Some pop-up field types remain unsupported, they are: geometry, raster, XML, and blob. If an unsupported field type is used the app will encounter an [`assertionFailure`](https://developer.apple.com/documentation/swift/1539616-assertionfailure).

**Many-To-One Records**

Editing a many-to-one record is permitted and follows certain rules. To edit a many-to-one record, the user can tap the related record cell (indicated by an accessory view). The app runs a query for all on the relationship's table and presents the options in a `RelatedRecordsListViewController`. Selecting a new related record stages that record to be saved, should the user save their changes.

If the related record has not been selected and the many-to-one relationship is composite, the pop-up will not validate. Conversely, if the relationship is not composite, the related record can be kept empty. If the related record has been selected, the app does allow the user to change the related record to a different one. Note, the view controller does not allow a record to deselect a many-to-one related record once it has been selected.

> Editing many-to-one related records (add/update) is only permitted in edit mode. This is because the app considers many-to-one relationships similar to attributes, being the child of the many-to-one relationship.

**One-To-Many Records**

Editing a one-to-many record while in edit mode is not permitted. If a user attempts to do so, they are prompted to save changes to the pop-up first.

**Attachments**

A user may delete existing attachments or add new photo attachments. Adding a new photo attachment conditionally asks the user for access to the device's hardware and then offers the option to create an image attachment with the camera or from the image library.

## Consuming ArcGIS

The app demonstrates best practices for consuming the ArcGIS Runtime iOS SDK.

### Identifying map features

The app's `MapViewController` specifies itself as the maps view's `AGSGeoViewTouchDelegate` and thus the `MapViewController` can recieve touch delegate messages including the message sent when the user taps the `AGSMapView`. The app uses this opportunity to identify features contained in layers of the `geoView`.

```swift
func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
    // prepare for identify operation
    identifyOperation = geoView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10, returnPopupsOnly: true, maximumResultsPerLayer: 5) { [weak self] (result, error) in
        // process results of identify operation
    }
}
```

> The `identifyLayers` function returns an object that is `AGSCancelable` and thus a previous `identifyOperation` can be canceled before the next one begins, for instance if a user taps the map view in quick succession.

### Offline map jobs

The SDK facilitates taking a web map offline and synchronizing changes. The app only needs to prepare a few parameters before it is able to take a web map offline or synchronize changes between the offline map and the web map.

`OfflineMapJobConstruct` is an `enum` of two cases, one for each job performed in the app, each performing two major functions.

```swift
enum OfflineMapJobConstruct {

    case downloadMapOffline(AGSMap, URL, AGSEnvelope, Double)
    case syncOfflineMap(AGSMap)
    // ...
}
```

Each case knows how to generate a job based on the parameters supplied to it.

```swift
enum OfflineMapJobConstruct {
    // ...
    func generateJob() -> AGSJob
}
```

Each case also offers contextual information for display in `JobStatusViewController`.

```swift
enum OfflineMapJobConstruct {
    // ...
    var message: String { get }
    var successMessage: String { get }
    var errorMessage: String { get }
    var cancelMessage: String { get }
}
```

#### Download map offline

Before generating an offline map job, the app asks the user to establish the area of the web map that they wish to take offline. Once established, the app converts the view mask area to an `AGSPolygon`.

```swift
extension AGSMapView {

    func convertExtent(fromRect rect: CGRect) throws -> AGSGeometry {

        guard bounds.contains(rect) else {
            throw MapViewError.rectOutsideOfBounds
        }

        let nw = rect.origin
        let ne = CGPoint(x: rect.maxX, y: rect.minY)
        let se = CGPoint(x: rect.maxX, y: rect.maxY)
        let sw = CGPoint(x: rect.minX, y: rect.maxY)

        let agsNW = screen(toLocation: nw)
        let agsNE = screen(toLocation: ne)
        let agsSE = screen(toLocation: se)
        let agsSW = screen(toLocation: sw)

        return AGSPolygon(points: [agsNW, agsNE, agsSE, agsSW])
    }
}
```

The app gets the current `AGSMap`'s scale (`Double`) and retrieves a temporary file directory `URL`. With these parameters we can build a `AGSGenerateOfflineMapJob` object.

```swift
/**  
  Parameter map: AGSMap
  Parameter directory: URL
  Parameter extent: AGSEnvelope
  Parameter scale: Double

  Returns: AGSGenerateOfflineMapJob
 */

func generateJob() -> AGSJob {
  // ...
  case .downloadMapOffline(let map, let directory, let extent, let scale):
      let offlineMapTask = AGSOfflineMapTask(onlineMap: map)
      let offlineMapParameters = AGSGenerateOfflineMapParameters(areaOfInterest: extent, minScale: scale, maxScale: map.maxScale)
      let offlineMapJob = offlineMapTask.generateOfflineMapJob(with: offlineMapParameters, downloadDirectory: directory)
      return offlineMapJob
  // ...
}
```

Upon a successful download, the app finishes by moving the offline map from the temporary documents directory to a permanent one.

#### Synchronize offline map

Synchronizing a map is even more straightforward than downloading a map. The app builds an `AGSOfflineMapSyncJob` by constructing an offline map sync task using the offline map and specifying the offline sync parameters sync direction `.bidirectional`.

> A [bi-directional sync](https://developers.arcgis.com/ios/latest/swift/guide/sync-offline-edits.htm#GUID-364B63B9-BAE7-4BE7-A154-5CF3D1AB2996) synchronizes local changes with the web map and changes made to the web map are synchronized with the offline map. Synchronization conflicts are resolved following the rule "last-in wins".

```swift
/**  
  Parameter map: AGSMap

  Returns: AGSOfflineMapSyncJob
 */

func generateJob() -> AGSJob {
  // ...
  case .syncOfflineMap(let map):
      let offlineMapSyncTask = AGSOfflineMapSyncTask(map: map)
      let offlineMapSyncParameters = AGSOfflineMapSyncParameters()
      offlineMapSyncParameters.syncDirection = .bidirectional
      let offlineMapSyncJob = offlineMapSyncTask.offlineMapSyncJob(with: offlineMapSyncParameters)
      return offlineMapSyncJob
  // ...
}
```

#### Job status view controller

The `JobStatusViewController` conveniently works with each `OfflineMapJobConstruct` case. The job status view controller first generates the job.

```swift
mapJob = jobConstruct?.generateJob()
```

It then sets the progress view's `observedProgress` to the job's `progress` for updates to the UI.

```swift
jobStatusProgressView.observedProgress = mapJob.progress
```

And finally starts the asynchronous job, waiting for it to complete.

```swift
mapJob.start(statusHandler: nil) { (result, error) in
    // ...
}
```

#### Deleting offline map

Deleting an offline map is not handled by the ArcGIS SDK but rather by the `FileManager`. Simply deleting the contents on disk is enough to delete the offline map.

> Remember to remove references to the map in memory as well.

### Querying feature tables

There are number of things to note when performing a query on an ArcGIS feature table. There are two concrete subclasses of an ArcGIS feature table. An `AGSServiceFeatureTable` represents an ArcGIS online web map feature table. Alternatively, an `AGSGeodatabaseFeatureTable` represents an ArcGIS offline mobile map package's geodatabase feature table.

There is one key difference in how the app queries these differing table types for features. By default, an `AGSGeodatabaseFeatureTable` loads all attributes of the records it returns in the query result. Conversely, when using an `AGSServiceFeatureTable` the app must specify the `AGSQueryFeatureFields` parameter as `.loadAll` otherwise the server returns a feature without all of its attributes loaded.

The app contains `AGSArcGISFeatureTable` Swift extension helper functions that facilitate querying either service feature table or geodatabase feature table returning all fully loaded results and follow the familiar feature table query pattern.

#### Query for all features

The app queries for all records in a table under the circumstance where a user would like to relate a many-to-one related record. This is accomplished by specifying the `AGSQueryParameters` SQL-like `whereClause` to `"1 = 1"`. The app also offers additional support for ordering the results.

```swift
extension AGSArcGISFeatureTable {

    func queryAllFeatures(sorted: AGSOrderBy? = nil, completion: @escaping (AGSFeatureQueryResult?, Error?) -> Void) {

        // setting the SQL-like where clause to "1 = 1" fetches all results
        let queryParams = AGSQueryParameters()
        queryParams.whereClause = "1 = 1"

        if let sort = sorted {
            queryParams.orderByFields.append(sort)
        }

        // web map service feature table
        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            serviceFeatureTable.queryFeatures(with: queryParams, queryFeatureFields: .loadAll, completion: completion)
        }
        // offline map geodatabase feature table
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            geodatabaseFeatureTable.queryFeatures(with: queryParams, completion: completion)
        }
        // feature table is not an ArcGIS feature table
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
            return
        }
    }
}

```

#### Query for related features

There are a number of cases where the app queries a feature for its related records. The feature's containing feature table accomplishes this task by providing the feature in question and a relationship information that specifies which related record type to return.

```swift
extension AGSArcGISFeatureTable {

    func queryRelatedFeatures(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSRelatedFeatureQueryResult]?, Error?)->()) {

        let parameters = AGSRelatedQueryParameters(relationshipInfo: relationship)

        if let serviceFeatureTable = self as? AGSServiceFeatureTable {
            let fields = AGSQueryFeatureFields.loadAll
            serviceFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, queryFeatureFields: fields, completion: completion)
        }
        else if let geodatabaseFeatureTable = self as? AGSGeodatabaseFeatureTable {
            geodatabaseFeatureTable.queryRelatedFeatures(for: feature, parameters: parameters, completion: completion)
        }
        else {
            completion(nil, FeatureTableError.isNotArcGISFeatureTable)
            return
        }
    }
}
```

An additional layer of abstraction has been built that converts the results from the query to an array of pop-ups for later viewing and editing.

```swift
extension AGSArcGISFeatureTable {

    func queryRelatedFeaturesAsPopups(forFeature feature: AGSArcGISFeature, relationship: AGSRelationshipInfo, completion: @escaping ([AGSPopup]?, Error?)->()) {

        queryRelatedFeatures(forFeature: feature, relationship: relationship) { (results, error) in

            guard error == nil else {
                completion(nil, error!)
                return
            }

            guard let result = results?.first, let features = result.featureEnumerator().allObjects as? [AGSArcGISFeature] else {
                completion(nil, FeatureTableError.queryResultsMissingFeatures)
                return
            }

            guard let popups = features.asPopups else {
                completion(nil, FeatureTableError.isNotPopupEnabled)
                return
            }

            completion(popups, nil)
        }
    }
}
```

These feature table extensions offer the app a powerful and simple API for querying related records used in various areas of the app.

#### Spatial query

The *Trees of Portland* story contains custom behavior to perform a spatial query on the neighborhoods layer to obtain a neighborhood's metadata which is populated into a tree's attributes. This spatial query is specified by a `AGSQueryParameters` object. In our example, we query the neighborhoods table for a neighborhood where the new tree's point falls within the bounds of the neighborhood's polygon.

```swift
let query = AGSQueryParameters()
query.geometry = point
query.spatialRelationship = .within

neighborhoodFeatureTable.queryFeatures(with: query) { (result, error) in
    // ...
}
```

### Editing features

The app's base data model object, `AGSPopup`, can be broken down generally into two parts. The first is the pop-up's `geoElement` which in our case is always an instance of an `AGSArcGISFeature`. The second is the web map's configuration of that feature as an `AGSPopup`, defined by an `AGSPopupDefinition`.

Editing of an `AGSPopup` is facilitated by the [`AGSPopupManager`](https://developers.arcgis.com/ios/latest/api-reference/interface_a_g_s_popup_manager.html). The app works heavily with the related records API as well as the pop-up attachments manager and thus the app ships with a concrete subclass of `AGSPopupManager` named `RichPopupManager`.

#### Creating features

When we create a new feature, we must also take the next step and build a pop-up using the newly-created feature and its feature table's pop-up definition. The app ships with an extension to `AGSArcGISFeatureTable` that facilitates this process.

```swift
extension AGSArcGISFeatureTable {

    func createPopup() -> AGSPopup? {

        guard canAddFeature, let popupDefinition = popupDefinition, let feature = createFeature() as? AGSArcGISFeature else {
            return nil
        }

        return AGSPopup(geoElement: feature, popupDefinition: popupDefinition)
    }
}
```

#### Rich pop-up

After creating a new pop-up from the table, the app builds a `RichPopup`.

```swift
class RichPopup: AGSPopup {

    // MARK: Initializer

    init(popup: AGSPopup) {
        super.init(geoElement: popup.geoElement, popupDefinition: popup.popupDefinition)
    }

    // MARK: Relationships

    /// A data structure that contains related records of the feature.
    ///
    /// Because `Relationships` conforms to `AGSLoadable`, there is a choice whether to, or not to, load the feature's related records.
    ///
    lazy private(set) var relationships: Relationships? = { [unowned self] in
        return Relationships(popup: self)
    }()
}
```

A `RichPopup` augments `AGSPopup` by maintaining a instance of `Relationships`, which is `<AGSLoadable>`.

```swift
class Relationships: AGSLoadableBase {

    weak private(set) var popup: AGSPopup?

    init?(popup: AGSPopup) {

        guard
            let feature = popup.geoElement as? AGSArcGISFeature,
            let featureTable = feature.featureTable as? AGSArcGISFeatureTable,
            featureTable.layerInfo != nil else {
            return nil
        }

        self.popup = popup
    }

    private(set) var manyToOne = [ManyToOneRelationship]()

    private(set) var oneToMany = [OneToManyRelationship]()

    // ...
}
```

`Relationships` is responsible for maintaining lists of relationships of different types (one-to-many and many-to-one).

#### Editing features lifecycle

If editing is permitted, the `RichPopupManager` starts the edit session.

```swift
if recordsManager.shouldAllowEdit, recordsManager.startEditing() {
    // start editing
}
```

Updates are performed by passing a new value for a field of the pop-up. If the updated value is invalid, an error is thrown.

```swift
try? recordsManager.updateValue(value, field: field)
```

If the user decides to discard the changes to the feature, the `RichPopupManager` first cancels changes to each many-to-one record before cancelling the editing session (also deleting the copied attributes) and finally discarding any staged attachments.

```swift
override func cancelEditing() {

    if let relationships = richPopup.relationships, relationships.loadStatus == .loaded {

        // First, all staged many-to-one record changes are canceled.
        // Only many-to-one related records can be edited during an editing session.
        let manyToOne = relationships.manyToOne

        manyToOne.forEach { (manager) in
            manager.cancelChange()
        }
    }

    // Call corresponding super class method.
    super.cancelEditing()

    // Then, discard any staged attachments (resetting the attachments to the condition before the editing session started).
    richPopupAttachmentManager?.discardStagedAttachments()
}
```

And if the user decides to persist changes to the feature, the `RichPopupManager` performs a series of operations. First, it commits changes to each many-to-one related records. Then, it updates many-to-one parent managers then commits staged attachments. Finally, it calls its super class function.

```swift
override func finishEditing(completion: @escaping (Error?) -> Void) {

    var relatedRecordsErrors = [Error]()

    // First, all staged many-to-one record changes are committed and features are related.
    if let relationships = richPopup.relationships, relationships.loadStatus == .loaded {

        let managers = relationships.manyToOne

        for manager in managers {

            guard let info = manager.relationshipInfo else {

                manager.cancelChange()
                continue
            }

            if let feature = manager.popup?.geoElement as? AGSArcGISFeature,
                let relatedFeature = manager.relatedPopup?.geoElement as? AGSArcGISFeature {

                manager.commitChange()
                feature.relate(to: relatedFeature, relationshipInfo: info)
            }
            else {

                if info.isComposite {
                    relatedRecordsErrors.append(RichPopupManagerError.missingManyToOneRelationship(manager.name ?? "Unknown"))
                }

                manager.cancelChange()
            }
        }
    }

    // Then, update any parent one-to-many records.
    let relationships = parentOneToManyManagers.keyEnumerator().allObjects as! [Relationship]

    relationships.forEach { (relationship) in

        if let parentManager = parentOneToManyManagers.object(forKey: relationship) {
            do {

                guard let feature = popup.geoElement as? AGSArcGISFeature, let featureTable = feature.featureTable as? AGSArcGISFeatureTable else {
                    throw NSError.invalidOperation
                }

                if featureTable.canUpdate(feature) {
                    try parentManager.update(oneToMany: self.richPopup)
                }
                else if featureTable.canAddFeature {
                    try parentManager.add(oneToMany: self.richPopup)
                }
                else {
                    throw NSError.invalidOperation
                }
            }
            catch {
                relatedRecordsErrors.append(error)
            }
        }
    }

    // Then, commit all staged (add/delete) attachments.
    richPopupAttachmentManager?.commitStagedAttachments()

    // Finally, the manager finishes editing its attributes.
    super.finishEditing { (error) in

        if let error = error {
            relatedRecordsErrors.append(error)
        }

        if !relatedRecordsErrors.isEmpty {
            completion(RichPopupManagerError.invalidPopup(relatedRecordsErrors))
        }
        else {
            completion(nil)
        }
    }
}
```

#### Editing related records

The `RichPopupManager` handles a lot of the legwork in managing the editing of related records.

The app leverages the data structure to perform all adding, updating and deleting of related records. The editing functions supported by the data structure are:

```swift
// One-to-many
func add(oneToMany popup: AGSPopup) throws
func update(oneToMany popup: AGSPopup) throws
func delete(oneToMany popup: AGSPopup) throws

// Many-to-one
func update(manyToOne popup: AGSPopup) throws

// Delete
func deleteRichPopup() throws
```

The `RichPopupManager` also assists in providing context for formatting the `RichPopupDetailsViewController`.

These helper functions inform the `RichPopupDetailsViewController`'s table view with what kind of table cell exists at an index path.

```swift
func indexPathWithinAttributes(_ indexPath: IndexPath) -> Bool
func indexPathWithinManyToOne(_ indexPath: IndexPath) -> Bool
func indexPathWithinOneToMany(_ indexPath: IndexPath) -> Bool
func indexPathIsAddOneToMany(_ indexPath: IndexPath) -> Bool
```

They also help the `RichPopupDetailsViewController`'s table view retrieve pop-up attributes and relationships.

```swift
func attributeField(forIndexPath indexPath: IndexPath) -> AGSPopupField?
func relationship(forIndexPath indexPath: IndexPath) -> Relationship?
```

#### Editing attachments

The app uses a tool auxiliary to `AGSPopupAttachmentManager` named `RichPopupAttachmentsManager`. This tool allows the app to stage attachments before adding them to the `AGSPopupAttachmentManager` when the user decides to persist the editing session. Because the attachments are staged, the user can edit the attachment name and preferred content size (for image attachments).

```swift
internal func add(stagedAttachment: RichPopupStagedAttachment) -> Int
internal func deleteAttachment(at index: Int) -> Bool
internal func commitStagedAttachments()
internal func discardStagedAttachments()
```

### Reverse geocoding

The *Trees of Portland* story contains a custom behavior that reverse geocodes a point into an address which is populated into a tree's attributes. In order to support both an online and an offline work flow, the app ships with a custom class named `AddressLocator` that loads two `AGSLocatorTask` objects, one side-loaded from the app's bundle and the other connected to the [world geocoder web service](https://developers.arcgis.com/features/geocoding/).

When running a reverse geocode operation, the app selects which `AGSLocatorTask` to use considering the app context's work mode and if the app has a network connection.

```swift
class AddressLocator {
    // ...
    func reverseGeocodeAddress(for point: AGSPoint, completion: @escaping (_ result: Result<String, Error>) -> Void) {
        let locator = appContextAwareLocator
        locator.load { [weak self] (error) in
            // Ensure the loaded locator matches the app context aware locator.
            // The app context might have changed since the locator started loading.
            guard locator == self?.appContextAwareLocator else {
                completion(.failure(NSError.unknown))
                return
            }
            // If the locator load failed, end early.
            if let error = error {
                completion(.failure(error))
                return
            }
            // We need to set the geocode parameters for storage true because the results of this reverse geocode is persisted to a table.
            // Please familiarize yourself with the implications of this credits-consuming operation:
            // https://developers.arcgis.com/rest/geocode/api-reference/geocoding-free-vs-paid.htm
            let params: AGSReverseGeocodeParameters = {
                let params = AGSReverseGeocodeParameters()
                params.forStorage = true
                return params
            }()
            // Perform the reverse geocode task.
            locator.reverseGeocode(withLocation: point, parameters: params) { (results, error) in
                if let error = error {
                    completion(.failure(error))
                }
                else if
                    let attributes = results?.first?.attributes,
                    let address = (attributes[.address] ?? attributes[.matchAddress]) as? String {
                    completion(.success(address))
                }
                else {
                    assertionFailure("Locator task unsupporting of required attribute key (\"\(String.address)\" for online locator, \"\(String.matchAddress)\" for offline locator).")
                }
            }
        }
    }
    // ...
}
```

Because the *Trees of Portland* web map stores the results of a geocode operation, the reverse geocode parameters must have set `forStorage = true`. For more on the world geocoding service visit the [developers website](https://developers.arcgis.com/rest/geocode/api-reference/overview-world-geocoding-service.htm).

> The side-loaded geocoder was generated statically whereas the world geocoder service remains current. You might notice a difference in the results between geocoders.

## Architecture

The app is built with a number of core architectural principles.

1. ArcGIS SDK asynchronous design pattern
2. iOS model-view-controller
3. Cocoa Touch
4. `AppConfiguration` to manage the app's static configuration
5. `AppContext` to manage the app's current state
6. `RichPopup` with `Relationships: <AGSLoadable>` supported by `RichPopupManager` and `RichPopupAttachmentManger`

### App configuration

The `AppConfiguration` contains a series of static configuration resources. Modify these configurations to suit your needs. They include:

* web map portal ID
* portal domain and url
* geocode service url
* app local url scheme OAuth redirect url
* app keychain ID
* app license key
* app client ID

> `AppConfiguration` configures a single global build environment. You can easily modify the project for multiple build environments.

### App secrets

The project manages app secrets using a custom _build rule_ and _bash program_ named `masquerade`. This technique is employed to keep compiled app secrets out of source control.

#### Masquerade

The program parses an input file looking for unique bracket-enclosed key pattern matches substituting found keys with supplied secret values before writing the file to output.

The program looks for keys using a regex pattern `{{ *$KEY *}}`. The pattern can be chopped up into a number of sub-components.

- `{{`, two open-brackets specify the start of the pattern
- ` *`, a space-astrix permits 0-to-n space characters
- `$KEY`, a key variable specified in the secrets file
- ` *`, a space-astrix again permits 0-to-n space characters
- `}}`, two close-brackets specify the end of the pattern

Masquerade demands various parameters.

- `-i`, the input file containing bracket-enclosed keys.
- `-o`, the path to output the file.
- `-s`, the secrets file containing key/value pairs.
- `-f`, an (optional) flag to overwrite the output file.

For example, we could supply `masquerade` with these _input_ and _secret_ files.

**Input**

```swift
extension String {
    static let clientID = "{{ ARCGIS_CLIENT_ID }}"
    static let licenseKey = "{{ ARCGIS_LICENSE_KEY }}"
}
```

**Secret**

```txt
ARCGIS_CLIENT_ID=ABC123
ARCGIS_LICENSE_KEY=fake.license.key.ABC123
```

Which would produce an output.

**Output**

```swift
extension String {
    static let clientID = "ABC123"
    static let licenseKey = "fake.license.key.ABC123"
}
```

#### Build rule

The project implements a custom build rule, executing `masquerade` for all source files with names matching the pattern `*.masque`.

The build rule supplies `masquerade` with files that match the bracket-enclosed key pattern as well as a hidden secrets file that must live in the project's root directory.

`$(PROJECT_DIR)/.secrets`

The build rule outputs the file to the Derived Data directory supplied by Xcode, stripping the `.masque` file extension.

`$(DERIVED_FILE_DIR)/$(INPUT_FILE_BASE)`

##### Usage

The build rule is used to inject secrets into swift source code by including in-line bracket-enclosed keys and appending `.masque` to a swift file.

In effect the `AppSecrets.swift.masque` key-laden swift template becomes `AppSecrets.swift`, a swift source code file that is compiled and linked with the app at build time and is never introduced to version control.

### App context

The `AppContext` maintains and informs the app of its current state. It concerns itself with:

* Authentication and user lifecyle management
* Loading `AGSMap`s from an `AGSPortal` or an offline `AGSMobileMapPackage`
* Managing online and offline work modes

Changes made to the `AppContext` are broadcast to the rest of the app so it can respond accordingly.

#### App context change handler

Various components of the app needs to be aware of changes to the `AppContext`. These components leverage the `NotificationCenter` APIs to subscribe to these changes.

For types that support publishing notifications the first step is to build a notification.

```swift
extension Notification.Name {
    static let portalDidChange = Notification.Name("portalDidChange")
}

extension AppContext {
    var portalNotification: Notification {
        Notification(
            name: .portalDidChange,
            object: self,
            userInfo: nil
        )
    }
}
```

The next step is to post the notification.

```swift
NotificationCenter.default.post(self.portalNotification)
```

Objects that wish to observe a notification must add an observer. When a notification is posted, objects that are observing the notification will perform the method specified by the selector.

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(adjustForPortal),
    name: .portalDidChange,
    object: nil
)
```

### Model: Pop-up configuration driven

The operative data model driving the app is the `AGSPopup`. A `AGSPopup` is constructed around an `AGSArcGISFeature` object and its table's `AGSPopupDefinition`. This is important because layers and tables are only considered by the app if they have pop-ups enabled. To enable pop-ups, see the section entitled [_Enable Pop-up on Feature Layers and Tables_](#enable-pop-up-on-feature-layers-and-tables).

An `AGSPopup` provides the app with a context defining how to represent its containing feature. An `AGSPopup` is managed using an `AGSPopupManager` that guides the app's popup views construction as well as editing the `AGSPopup`'s `AGSArcGISFeature`. The app comes with a concrete subclass of `AGSPopup` named `RichPopup` that is a `<AGSLoadable>` data structure that supports related records. The app also comes with a concrete subclass of `AGSPopupManager` named `RichPopupManager`, a manager that offers additional support for editing related records as well as an auxiliary class to `AGSPopupAttachmentManager` named `RichPopupAttachmentsManager` that supports staging new attachments as well as `UITableView` based UI. To learn more about the `RichPopupManager` and the `RichPopupAttachmentsManager` see the section entitled [_Editing Features_](#editing-features).

### View: storyboards

All views are built using Interface Builder and storyboards. The root view controller of the main storyboard upon launch is an instance of `AppContainerViewController` which embeds and maintains the layout of the `MapViewController` and the `DrawerViewController`. Once loaded, the app container view controller delegates messages from these two embedded view controllers, handles layout of these two view controller's views and handles state of the navigation bar accordingly. The app also leverages storyboard segues to facilitate transitions between view controllers.

#### Custom views

The app ships with a number of custom views with UI that extend beyond what is provided by UIKit.

**Slide Notification View**

A `SlideNotificationView` view is a `UIView` subclass that animates in from the top of the map an ephemeral contextual message that does not interfere with the user's ability to interact with the map.

**Shrinking View**

A `ShrinkingView` is a `UIControl` subclass that shrinks its scale on touch down and returns to its original scale upon touch up or cancel. The app uses a `ShrinkingView` to show a pop-up identified after a tap interaction on the map.

**Pin Drop View**

A `PinDropView` is a custom `UIView` subclass that leverages Core Animation to animate the dropping of a pin in the center of the `AGSMapView`. This view guides the user in determining the geometry of a new `AGSArcGISFeature`.

**Activity Bar View**

An `ActivityBarView` is a custom `UIView` subclass that flickers its background color to indicate activity, specifically used in the app to indicate that the `AGSMap` is loading.

These custom views are built and their layouts are managed in a storyboard.

**Rich Popup Styled Views**

A `StyledFirstResponderLabel` is a custom `UILabel` subclass that converts the label into a first responder and styles the label upon user interaction. Similarly, `StyledTextView` and `StyledTextField` are subclasses that style (`UITextView` and `UITextField`, respectively)  to appear editable or not based on if user interaction is enabled.

### Controller: app context aware

Some view controllers are made aware of changes to the app context so they may update accordingly. Because all changes broadcasted by the `AppContextChangeHandler` are performed on the main thread, these view controllers can safely update UI. To learn more about the `AppContextChangeHandler` see above section entitled [_App Context Change Handler_](#app-context-change-handler).

### App location

If the user has granted the app permission, the app shows the user their location on an `AGSMap` and to allow a user to zoom to their location. The `AGSMapView` comes with support for asking the user for permission to access the device's location and displaying the user's location on a map, out of the box.

The app monitors for changes to the location authorization status manually. Using a `CLLocationManager`, the app broadcasts these changes to all app context aware view controllers. This status is monitored by a custom class named `AppLocation`.

### Network reachability manager

Working with a web map and accessing an `AGSPortal` require a network connection. The app uses [Alamofire](https://github.com/Alamofire/Foundation)'s [`NetworkReachabilityManager`](https://github.com/Alamofire/Alamofire/blob/master/Source/NetworkReachabilityManager.swift) to listen to changes in network reachability status. The app broadcasts these changes to all app context aware objects.

### Ephemeral cache

The utility `EphemeralCache` solves a simple problem that emerges when using storyboards with segues.

To perform a segue, a view controller calls `performSegue(withIdentifier, sender)` where we can expect the scope in which it is called, to end. Later, the overridden view controller life cycle function `prepare(for segue, sender)` is called and is the first access to the destination view controller made available to us.

A problem arises when the view controller needs to send non-member object reference from itself to the destination view controller. Enter `EphemeralCache`.

The `EphemeralCache` is a singleton, thread-safe caching system that allows you to set `AnyObject` that is retrieved and removed from the cache upon the first get of that object. Under the hood it accomplishes this using `NSCache` and a concurrent `DispatchQueue` (with a barrier flag). `EphemeralCache` is used with the following pattern:

```swift
// within a view controller responding to an event
	... {

	// Cache an object (for example, a new popup object)
	EphemeralCache.set(object: newPopup, forKey: "keys.newPopupKey")

	// trigger segue (for example, to a popup edit view controller)
	self.performSegue(withIdentifier: "mapViewToPopupEditView", sender: nil)
}

// before executing the segue, UIViewController calls:
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

	// unwrap segue's destination view controller (for example, a related records popups view controller)
	// unwrap the object from the cache (for example, the new popup object)
	if let destination = segue.destination as? RelatedRecordsPopupsViewController, let newPopup = EphmeralCache.get(objectForKey: "keys.newPopupKey") as? AGSPopup {

		// after getting an object from the EphemeralCache, that object no longer exist within the EphmeralCache
		// set the object to the destination view controller
		destination.popup = newPop
	}
}
```

### File manager

The app allows a user to store a web map offline using the Swift [`FileManager`](https://developer.apple.com/documentation/foundation/filemanager). While most of the file I/O leg work is handled by the SDK, it is the responsibility of the app to provide a directory at which the offline mobile map package will be stored.

The app accounts for errors that might arise while downloading the map offline such as the app exiting or crashing in the background while the download job executes. The app does so by providing a temporary document directory at which the offline mobile map package is downloaded and upon a successful download, moves the map to a permanent directory.

### App defaults

A number of settings are stored in the app's `UserDefaults` to help maintain state between app usage.

**Last Sync Mobile Map Package**

`LastSyncMobileMapPackage` is a concrete subclass of `AGSMobileMapPackage` augmenting the class with the ability to store the `Date` a web map is downloaded, or subsequently, the `Date` it is last synchronized with the web map. The utility stores the `Date` in `UserDefaults` and posts an `AppContextChange` upon change.

**Work Mode**

`WorkMode` is a raw representable `Int` enumeration stored in `UserDefaults` when the app context's work mode changes based on user interaction.

**Visible Area**

As the map view navigates, the current visible area `AGSViewpoint` is stored in `UserDefaults` as JSON. The persisted visible area is retrieved and set when switching online and offline maps and when starting a new app session.

**Pop-up Attachment Size**

Specifying a new staged image attachment's `preferredSize` persists the selection in `UserDefaults`. The next time the user adds an image attachment, the stored `preferredSize` is retrieved.

### App colors & fonts

Much of the app's colors and fonts are configured dynamically. The app offers a configuration for design assets by globalizing `AppColors` and `AppFonts`. You can change these configurations to affect the design of those dynamically-generated views.

### App errors

The app includes a simple and informative error system. `AppError` is a protocol specifying requirements for errors used in the app. Error categories are demarcated as unique `enums` with subcategories represented as individual `cases`. Each app error contains a unique code and localized description.

## Xcode project configuration

Certain measures are required in configuring the Xcode project when using the ArcGIS SDK.

### Privacy strings

Two privacy strings are included in the Xcode project in order for the SDK to interface with the user's device. These strings are configured in the `.plist`.

1. In order to publish the app to the iTunes App store, the ArcGIS SDK requires access to the device's photo library. The app does not leverage the device's photo library but this privacy string is required regardless.
2. The app requests access to the device's location when in use. This message is presented upon launch.
