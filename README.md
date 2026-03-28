# ReportSimpleMDM

ReportSimpleMDM is a native SwiftUI app for macOS and iOS that uses the SimpleMDM API as its primary data source. It can also layer in optional MunkiReport `simplemdm` module enrichment when you want the same supplemental context used by the MunkiReport widgets.

## Architecture

The app supports two connection modes:

- `SimpleMDM API Only`
  - standalone mode
  - connects directly to SimpleMDM with your API key
  - no MunkiReport dependency

- `SimpleMDM + MunkiReport Module`
  - still uses SimpleMDM as the source of truth for devices and actions
  - optionally reads MunkiReport `simplemdm` module data for enrichment widgets and supplemental context

The app does not require MunkiReport to function. MunkiReport is optional enhancement, not a hard dependency.

## Current Feature Set

### Dashboard

The dashboard currently supports:

- total device, enrolled, and unenrolled KPI cards
- enrollment status chart
- OS version breakdown
- recently seen devices
- device posture summary
  - DEP enrolled
  - supervised
  - FileVault enabled
- optional module-backed panels when enrichment data is available
  - sync health
  - compliance
  - assignment groups
  - resource types
  - supplemental overview
  - AppleCare coverage
- live API resource cards
  - DEP servers
  - scripts and script jobs
  - assignment groups
  - app management
  - custom declarations
  - push certificate
  - webhooks

Dashboard rows are interactive:

- tapping `Unenrolled` opens the device list filtered to non-enrolled devices
- tapping an OS version opens the device list filtered to that exact OS version
- tapping a device posture row opens the device list filtered to the matching posture state
- live API resource card rows open filtered resource lists backed by the current SimpleMDM connection

The live resource card area is responsive:

- macOS and wider layouts use a multi-column card grid
- compact iPhone portrait layouts collapse to a single-column card stack so labels and values remain readable
- compact iPhone layouts also use a shorter dashboard header, thinner sync banner, stacked KPI cards, and tighter live-card typography to avoid truncation and tab-bar crowding

Dashboard startup now prioritizes faster first paint:

- a recent cached device snapshot can be shown immediately while a live refresh continues
- the first SimpleMDM device page is published quickly, with remaining pages continuing in the background
- secondary dashboard resources are deferred until shortly after launch so the primary fleet summary appears first

Operational diagnostics are intentionally lower in the dashboard hierarchy:

- `Sync Health` and `Data Freshness` live near the bottom of the dashboard rather than above the primary KPI and fleet summary content
- `Data Freshness` is collapsible on the dashboard and opens as a compact status summary until you expand it
- `Sync Health` shows the latest sync summary plus recent per-sync status markers for the current host
- the detailed freshness and sync-strategy views are also available in Settings for operators who want the full cache/sync picture without crowding the main dashboard

### Dashboard Widget Visibility

The `Settings > Dashboard Widgets` screen lets you choose which dashboard panels are shown.

Widget status is source-aware:

- `Direct`
  - backed by direct SimpleMDM data
- `Available`
  - module-backed widget with data currently available
- `Module Needed`
  - wired, but requires MunkiReport enrichment data that is not currently available

### Device Inventory

The device list supports:

- server-side search through the SimpleMDM devices endpoint
  - device name
  - serial
  - UDID
  - IMEI
  - MAC address
  - phone number
- status filter
- OS family filter
- advanced filters
  - exact OS version
  - model family
  - supervised / not supervised
  - DEP enrolled / not DEP
  - FileVault on / off
  - passcode compliant / noncompliant
  - assignment group
  - device group
  - last seen recency

The live device query also supports:

- include awaiting-enrollment devices
- include secret custom attributes when the API key permits them

### Device Detail

Each device includes:

- `Overview`
  - battery
  - storage
  - security posture
  - hardware details
- `Inventory`
  - connected resources
  - synced device subresources
  - custom declarations management
  - custom attributes
  - full inventory fields
- `Actions`
  - iOS: shown as a tab
  - macOS: shown in a split-view sidebar

The Overview tab includes a hardware card with expand/collapse behavior for longer detail lists.

Battery behavior is model-aware:

- battery-backed devices show percentage when available
- desktop hardware such as Mac mini shows `No Battery`
- missing battery telemetry on battery-backed devices shows `Unavailable`

### Device Subresources

Inventory subresource sections support expand/collapse and include:

- profiles
- installed apps
- users
- logs

The `Synced Device Subresources` summary rows scroll and expand to the matching section.

The device inventory screen also includes:

- recent device-scoped logs from `GET /logs?serial_number=...`
- log detail view for `GET /logs/{LOG_ID}`
- device-scoped custom declaration management
- collapsible app inventory summary (now a single glassmorphic panel that expands each management bucket inline)
- installed app grouping by management and catalog state
- contextual installed app actions
  - open installed-app detail
  - jump to matched app catalog record
  - jump to managed app configs
  - jump to assignment groups
  - request management
  - update
  - uninstall
- contextual profile actions
  - remove from current device
  - open deployment manager for direct device and group assignment
- compact iPhone layouts switch inventory fields and custom attributes to stacked label/value rows for better readability on narrow widths

### Installed Apps

Installed apps are handled as a first-class device inventory flow:

- per-device installed app list
- app inventory grouping
  - managed and in catalog
  - managed and not in catalog
  - unmanaged and in catalog
  - unmanaged and not in catalog
- installed app detail view
- app metadata
  - identifier
  - version
  - short version
  - bundle size
  - dynamic size
  - discovered date
  - last seen date
- actions
  - request management
  - update
  - uninstall

Installed app rows can now surface multiple independent signals:

- `Managed`
  - from the installed app record returned by SimpleMDM
- `In Catalog`
  - matched against the live SimpleMDM app catalog
- `Assigned`
  - inferred from assignment groups related to the current device
- Each installed-app row also shows the assignment-group catalog names that created the derived “Managed” flag so it’s obvious which catalog app(s) triggered the assignment.
- `Managed Config`
  - shown when the matched catalog app has managed app config entries

Installed app rendering is now backed by a cached per-device inventory state in the service layer so the UI does not recompute catalog joins and assignment-group matching during every SwiftUI render pass.

### Custom Declarations

Custom declarations are now supported as a native app feature, not just a raw API endpoint:

- live custom declarations card on the dashboard
- custom declarations list view
- custom declaration detail view
- declaration payload download and in-app inspection
- create declaration flow
- edit declaration flow
- delete declaration
- assign to device
- unassign from device
- device inventory entry point for managing declarations against a specific device

Declaration detail currently surfaces:

- name
- profile identifier
- declaration type when available
- reinstall-after-OS-update flag
- user scope
- attribute support
- escape attributes
- activation predicate when available
- device count
- group count

Creating declarations in the UI:

- `Name`
  - internal label shown in the app
  - example: `Force macOS 26.3.1 by March 18`
- `Declaration Type`
  - the Apple declaration type string
  - example: `com.apple.configuration.softwareupdate.enforcement.specific`
- `Activation Predicate`
  - optional conditional targeting logic
  - leave blank unless the declaration should only apply when a specific condition is true
- `User Scope`
  - use for declarations intended to apply per user instead of per device
  - usually left off for software update enforcement declarations
- `Attribute Support`
  - use when the JSON payload contains attributes/placeholders that should be substituted dynamically
  - leave off for static JSON payloads
- `Escape Attributes`
  - use only when attribute substitution is enabled and inserted values need escaping
  - usually left off

Important field mapping:

- the top-level `Declaration Type` form field is not the same as the JSON `Identifier`
- the unique declaration instance identifier belongs inside the JSON payload
- the large `Payload JSON` editor is lower in the create/edit sheet, below the templates section

Example software update enforcement declaration:

- form field `Name`: `Force macOS 26.3.1`
- form field `Declaration Type`: `com.apple.configuration.softwareupdate.enforcement.specific`
- form field `Activation Predicate`: blank
- form option `User Scope`: off
- form option `Attribute Support`: off
- form option `Escape Attributes`: off

Payload JSON:

```json
{
  "Type": "com.apple.configuration.softwareupdate.enforcement.specific",
  "Identifier": "com.example.softwareupdate.enforcement.specific",
  "Payload": {
    "TargetOSVersion": "26.3.1",
    "TargetBuildVersion": "25D771280a",
    "TargetLocalDateTime": "2026-03-18T18:00"
  }
}
```

Tip: DDM Software Update Enforcement for Apple Background Security Improvements (BSI)

- make sure devices are already on a macOS or iOS minor version where the BSI is available
- in this app, put `com.apple.configuration.softwareupdate.enforcement.specific` in the `Declaration Type` field
- in the JSON payload, keep a unique `Identifier` value for your declaration instance
- edit `TargetLocalDateTime` as needed for your enforcement deadline

Example form values:

- `Name`: `BSI Enforcement`
- `Declaration Type`: `com.apple.configuration.softwareupdate.enforcement.specific`
- `Activation Predicate`: blank
- `User Scope`: off
- `Attribute Support`: off
- `Escape Attributes`: off

Payload for macOS devices that are not MacBook Neo:

```json
{
  "Type": "com.apple.configuration.softwareupdate.enforcement.specific",
  "Identifier": "com.example.bsi-enforcement.macos",
  "Payload": {
    "TargetOSVersion": "26.3.1",
    "TargetBuildVersion": "25D771280a",
    "TargetLocalDateTime": "2026-03-18T18:00"
  }
}
```

Payload for iOS devices:

```json
{
  "Type": "com.apple.configuration.softwareupdate.enforcement.specific",
  "Identifier": "com.example.bsi-enforcement.ios",
  "Payload": {
    "TargetOSVersion": "26.3.1",
    "TargetBuildVersion": "23D771330a",
    "TargetLocalDateTime": "2026-03-18T18:00"
  }
}
```

Payload for MacBook Neo:

```json
{
  "Type": "com.apple.configuration.softwareupdate.enforcement.specific",
  "Identifier": "com.example.bsi-enforcement.neo",
  "Payload": {
    "TargetOSVersion": "26.3.2",
    "TargetBuildVersion": "25D771400a",
    "TargetLocalDateTime": "2026-03-18T18:00"
  }
}
```

### Device Actions

The app currently supports these SimpleMDM device actions:

- lock
- wipe
- sync / refresh
- clear passcode
- restart
- shutdown
- push apps
- clear restrictions password
- lost mode
  - enable with message / phone number / optional footnote
  - disable
  - play sound
  - update location
- unenroll
- advanced device actions
  - clear firmware password
  - rotate firmware password
  - clear recovery lock password
  - rotate recovery lock password
  - rotate FileVault recovery key
  - set admin password
  - rotate admin password
  - update OS
  - enable / disable remote desktop
  - enable / disable bluetooth
  - set time zone

Safeguards:

- `Lock` uses a dedicated payload form and enforces macOS PIN requirements
- `Wipe` uses a dedicated destructive confirmation flow and supports device PIN entry where required
- `Unenroll` uses destructive confirmation
- advanced security and platform-control actions use explicit confirmations before submission

Action availability is modeled explicitly and shown per device state and platform.

Lost mode uses a dedicated form flow because SimpleMDM requires a message or phone number when enabling it.

Device action behavior is now permission-aware:

- actions that require `Devices: write` are disabled when the app has evidence the current API key cannot perform them
- assignment-group management is disabled when the app has evidence the current API key lacks `Assignment Groups: write`
- permission failures render as user-facing status cards rather than raw backend text
- action failures no longer take over the entire device detail screen

### Device Sidebar

The macOS device sidebar now includes native management flows for:

- advanced action console
- edit device record
- manage assignment groups
- primary device actions
- advanced device actions
- lost mode actions

Sidebar management sheets are sized explicitly for macOS so forms render correctly instead of collapsing to toolbar-only panels.

### Device Editing and Assignment Groups

Native device management now includes:

- edit SimpleMDM record name
- edit on-device `device_name` where supported
- create devices with static-group selection
- assign or remove a device from assignment groups
- optional `remove_others` behavior when assigning to a new assignment group

### Profiles

Profiles are now a native management surface, not just a read-only list:

- live profiles list
- custom configuration profiles list
- custom configuration profile create / update / delete
- custom configuration profile download
- profile detail views
- assignment-group management from profile detail
- direct deployment manager for devices and legacy device groups

### Apps and App Catalog

The app catalog now supports native management workflows:

- list and search apps
- create App Store catalog entries
- update app metadata
- delete apps
- app detail view
- assignment-group management from app detail
- managed app config shortcut from app detail
- `Installed On Devices` view for catalog apps

### Assignment Groups

Assignment groups are now managed natively:

- list and search assignment groups
- create / update / delete assignment groups
- assign / unassign apps
- assign / unassign profiles
- assign / unassign devices
- push apps
- update apps
- sync profiles
- clone assignment groups

### Managed App Configs

Managed app configs now include native workflows for:

- list configs by app
- create config entries
- delete config entries
- push managed config updates
- value-type aware entry forms

### Enrollments, DEP, Push Certificates, Scripts, and Jobs

Lower-frequency admin surfaces now also have native views:

- enrollments
  - list
  - send invitation
  - delete enrollment
- DEP servers
  - list
  - sync with Apple
  - inspect DEP devices
- push certificate
  - view certificate details
  - fetch signed CSR
  - upload replacement certificate content
- scripts
  - list
  - create
  - update
  - delete
- script jobs
  - list
  - create
  - cancel
  - inspect results

### Admin Center

The app now includes an `Admin` tab that groups operational areas by value and frequency.

It serves as:

- a control center for cross-resource admin workflows
- a fallback for less frequently used workflows
- a complement to the contextual actions available directly from devices, apps, profiles, and assignment groups
- a glassmorphic “Tools” card that lists every tool, lets you expand a tool to read its description, and tap through to its workflow so the Admin view mirrors the rest of the app’s UI polish

### API Explorer

The app still includes a generic API explorer for documented endpoints that do not yet have a dedicated native workflow.

It can be used to:

- inspect the built-in endpoint catalog
- prefill documented method/path/body combinations
- manually run supported requests against the current SimpleMDM connection
- pick live resources by name instead of manually typing many IDs
  - devices
  - apps
  - assignment groups
  - profiles
  - device groups
  - scripts
  - enrollments
  - DEP servers
  - logs
  - installed apps
- use form-style editors for documented form-encoded endpoints instead of raw JSON where applicable

It is no longer the primary surface for:

- custom declarations
- installed apps
- device logs
- live dashboard resource visibility
- assignment group administration
- profile deployment
- app catalog management
- lower-tier admin workflows such as scripts and enrollments

## Settings

The settings flow includes:

- connection mode selection
- SimpleMDM API key
- optional MunkiReport enrichment URL and auth
- dashboard widget visibility
- sync strategy visibility
- cache freshness visibility
- cache TTL overrides
  - device snapshot
  - primary dashboard resources
  - apps catalog
  - custom declarations
  - custom configuration profiles
- sync history management
  - clear sync history for the current host
  - automatic retention of the most recent 100 syncs per host
- advanced action endpoint names
- app version and build pulled directly from Xcode bundle metadata
- client reporter / supplemental information screens
- `Clear Saved Connection`
  - removes the saved SimpleMDM API key
  - removes optional MunkiReport auth secrets
  - does not wipe the rest of the app configuration

## API Key Permissions

The app can function in read-only mode, but many native workflows require write permissions on the matching SimpleMDM resource domains.

Most important for the device-side experience:

- `Devices: write`
  - required for device actions and device editing
- `Assignment Groups: write`
  - required for device assignment-group management
- `Installed Apps: write`
  - required for installed-app mutation actions
- `Profiles: write`
  - required for direct profile deployment and profile assignment changes
- `Apps: write`
  - required for app catalog mutation workflows
- `Managed App Configs: write`
  - required for managed app config changes

The app now surfaces permission-sensitive behavior more clearly:

- unsupported write actions are disabled after real `401/403` failures are observed
- disabled actions show the missing requirement in the UI
- permission failures render as status cards instead of raw backend payload text

## Performance

The app includes several large-fleet improvements:

- paginated device loading
- progressive updates while pages load, including background continuation after the first device page
- cached device snapshot reuse for faster relaunches when the snapshot is still fresh
- cached partial fleet snapshots can also be reused for faster relaunch while background pagination finishes converging the fleet
- incremental device-page persistence during pagination so quitting and reopening the app does not require starting the fleet load from scratch
- lazy detail loading for device subresources
- off-main decode and request parsing for heavier API responses
- background revalidation of primary dashboard resources and optional module-backed summary data after cache-first startup
- deferred loading of secondary dashboard resources shortly after launch
- cached dashboard data can remain visible with a refresh banner while live device sync continues
- reduced dashboard card density on compact layouts
- batched managed-config count caching to reduce repeated UI publishes during device inventory rendering
- cached per-device installed-app inventory classification to reduce view-layer recomputation on iOS and macOS device detail screens
- deferred action submission from confirmation dialogs and sheets to avoid SwiftUI publish-during-update warnings
- action errors separated from detail-load errors so a failed mutation does not replace the entire device screen

The on-disk device cache is stored under the app's Application Support container rather than the transient caches directory.

The service distinguishes between two startup device-sync modes:

- `Full Fleet Snapshot`
  - the last cached device snapshot completed full pagination and can be reused as a complete fleet picture
- `Incremental Snapshot Recovery`
  - the app found a persisted snapshot from an earlier session, but that session did not finish full pagination before the app quit
  - the app can still reuse the saved pages immediately, then continue device refresh and pagination in the background

Dashboard and Settings both surface this status so operators can tell whether they are looking at a complete fleet snapshot or a recovered partial snapshot that is still being refreshed.

Freshness defaults are operator-tunable in Settings:

- device snapshot: 5 minutes
- primary dashboard resources: 10 minutes
- apps catalog: 30 minutes
- custom declarations: 15 minutes
- custom configuration profiles: 15 minutes

These TTLs are used to decide whether cached data remains fresh enough to reuse quietly or should trigger background revalidation.

## Debug Logging

High-volume debug logging is off by default.

Optional environment flags:

- `REPORTSIMPLEMDM_LOG_NETWORK_METRICS=1`
  - logs request timing metrics for SimpleMDM network calls
- `REPORTSIMPLEMDM_LOG_ASSIGNMENT_GROUP_DEBUG=1`
  - enables compact assignment-group resolution debugging

These are intended for short-lived troubleshooting sessions and should normally remain disabled.

## Build Notes

The project is a universal SwiftUI app and is intended to run on both macOS and iOS.

Local build requirements:

- Xcode
- valid signing configuration for your selected target

For source-validity checks in local development, a no-signing build is also supported:

```bash
xcodebuild -project ReportSimpleMDM.xcodeproj -scheme ReportSimpleMDM -derivedDataPath BuildDerivedData CODE_SIGNING_ALLOWED=NO build
```

If you build for macOS and hit signing failures, that is separate from Swift source validity. Recent work has been kept in shared SwiftUI code paths unless a change was intentionally iPhone-layout-specific or macOS-layout-specific.

Recent dashboard and device-inventory changes are intended to preserve the same core information architecture across platforms while adapting the layout for compact iOS widths.

## Source of Truth

For app behavior:

- direct device data and actions come from SimpleMDM
- MunkiReport enrichment is additive when configured

For the MunkiReport reference model:

- the local MunkiReport `simplemdm` module was used as a reference for supplemental widgets and enrichment behavior
- no code in `munkireport-php` or its local module is modified by this app
