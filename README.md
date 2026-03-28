# ReportSimpleMDM

ReportSimpleMDM is a native SwiftUI client for SimpleMDM that runs on macOS and iOS. Its primary purpose is to give admins a fast, operator-focused view of fleet state while also exposing a large amount of the SimpleMDM API surface through native workflows, an API catalog, and runnable endpoint presets.

The app works in two modes:

- `SimpleMDM API Only`
  - direct read and write access to SimpleMDM
  - no MunkiReport dependency
- `SimpleMDM + MunkiReport Module`
  - SimpleMDM remains the system of record for devices and actions
  - optional MunkiReport module data can enrich dashboards and device detail with supplemental context

## What The App Can Do Today

At a practical level, the current codebase already supports all of the following:

- connect directly to SimpleMDM with a saved API key
- browse and filter the live device fleet
- cache fleet data locally for fast relaunches
- inspect enrolled and non-enrolled devices
- load device subresources such as profiles, apps, users, and logs
- execute common and advanced device actions
- create and manage assignment groups
- create and manage app catalog entries
- create and manage custom configuration profiles
- create and manage custom declarations
- manage enrollments, DEP servers, push certificates, managed app configs, scripts, and script jobs
- browse a built-in SimpleMDM API catalog and run supported endpoints live
- tune cache freshness, inspect sync history, and review sync diagnostics

This is not just a dashboard demo. The app already contains real management surfaces, write flows, confirmation UX, permission-aware behavior, local persistence, and a wide range of operational tooling.

## Architecture

### Source Of Truth

SimpleMDM is the source of truth for:

- device inventory
- device detail and subresources
- device actions
- resource management
- catalog operations
- write mutations

MunkiReport support is additive. When configured, the app can read module-backed data to enrich:

- dashboard widgets
- connected-resource summaries
- supplemental fleet context
- source detection and enrichment-health visibility

If MunkiReport is not configured, the app still functions as a standalone SimpleMDM client.

### App Structure

The top-level app experience is organized into four main tabs:

- `Dashboard`
- `Devices`
- `Admin`
- `Settings`

On first launch, the app shows a setup flow that writes the SimpleMDM API key to the keychain and saves connection metadata in user defaults. Once configured, the main tab UI is unlocked.

### Connecting To The Optional MunkiReport Module

If you want supplemental MunkiReport enrichment, use `SimpleMDM + MunkiReport Module` in `Settings > Server & API`.

Step by step:

1. Open the app and go to `Settings > Server & API`.
2. Change `Backend Mode` to `SimpleMDM + MunkiReport Module`.
3. Enter your normal `SimpleMDM API Key`.
4. In `MunkiReport Base URL`, enter the MunkiReport site root.
   Example for rewrite-enabled routing: `https://munkireport.example.com`
   Example for non-rewrite routing: `https://munkireport.example.com/index.php?`
5. Leave `Module Path Prefix` set to `/module/simplemdm` unless your MunkiReport deployment is intentionally customized.
6. Choose one MunkiReport authentication method.
   Header-based auth:
   Set `Auth Header Name` and `Auth Header Value` to whatever your MunkiReport deployment expects.
   Cookie-based auth:
   Leave the auth-header fields blank and paste the full cookie value into `Cookie Header`.
7. Save the configuration.
8. Return to the dashboard or settings screens and let the app refresh.
9. Confirm the direct SimpleMDM connection still works first.
   Devices should load even if MunkiReport enrichment is unavailable.
10. Confirm module enrichment is working.
   `Settings > Supplemental Enrichment (A)` should begin showing detected-source status instead of the generic unavailable message.
   `Settings` should show `Module Data: Available` once module telemetry or supplemental status is loaded.
   Module-backed dashboard widgets such as compliance, sync health, supplemental overview, or AppleCare should start populating when the module responds successfully.

Quickest safe default:

- `MunkiReport Base URL`: your MunkiReport root
- `Module Path Prefix`: `/module/simplemdm`
- `Auth Header Name`: blank unless your MunkiReport deployment requires it
- `Auth Header Value`: blank unless your MunkiReport deployment requires it
- `Cookie Header`: blank unless you are authenticating with a MunkiReport session cookie

Use these fields as follows:

- `MunkiReport Base URL`
  - enter the MunkiReport site root
  - rewrite-enabled example:
    - `https://munkireport.example.com`
  - non-rewrite example:
    - `https://munkireport.example.com/index.php?`
- `Module Path Prefix`
  - leave this at the default unless your MunkiReport routing is customized
  - default:
    - `/module/simplemdm`
- `Auth Header Name`
  - optional
  - use this only if your MunkiReport deployment expects an auth header on module requests
- `Auth Header Value`
  - optional
  - if your deployment expects a header value, put it here
- `Cookie Header`
  - optional
  - use this when you want the app to send an authenticated MunkiReport session cookie

Practical examples:

- Header-authenticated deployment
  - `MunkiReport Base URL`: `https://munkireport.example.com`
  - `Module Path Prefix`: `/module/simplemdm`
  - `Auth Header Name`: whatever your MunkiReport deployment expects
  - `Auth Header Value`: the matching token or secret
  - `Cookie Header`: leave blank
- Cookie-authenticated deployment
  - `MunkiReport Base URL`: `https://munkireport.example.com`
  - `Module Path Prefix`: `/module/simplemdm`
  - `Auth Header Name`: leave blank unless your environment also requires one
  - `Auth Header Value`: leave blank
  - `Cookie Header`: full cookie header value such as `ci_session=...; other_cookie=...`
- Non-rewrite MunkiReport routing
  - `MunkiReport Base URL`: `https://munkireport.example.com/index.php?`
  - `Module Path Prefix`: `/module/simplemdm`

Important integration notes:

- the app expects the MunkiReport site root in `MunkiReport Base URL`, not the full endpoint URL
- the app builds module requests as:
  - `{MunkiReport Base URL}/{Module Path Prefix}/{route}`
- the app reads module enrichment routes; it does not use the module's admin-only device passthrough API for its core device management
- the app still talks directly to SimpleMDM for fleet data and write actions
- MunkiReport is only an enrichment layer in this app

What the app reads from the module today:

- dashboard and enrichment JSON routes for:
  - sync telemetry
  - command status
  - compliance
  - assignment-group stats
  - resource-type stats
  - OS-security stats
  - supplemental status
  - supplemental overview
  - AppleCare stats
- per-device module routes such as:
  - `get_device_resources/{serial}`

Compatibility note:

- this app expects a current `simplemdm` module build with the newer enrichment/data routes used by the app
- if module-backed widgets do not load but direct SimpleMDM data does, update the MunkiReport `simplemdm` module first

Auth note:

- the module's normal read routes are authenticated routes
- in practice, your header or cookie must be enough for your MunkiReport deployment to treat the request as authorized
- if your environment uses the default header name `X-SIMPLEMDM-API-KEY`, the app can reuse the SimpleMDM API key as the header value when the header-value field is left blank
- only rely on that fallback if your MunkiReport deployment is explicitly configured to accept it

How to verify the connection after saving:

- the app should still load devices even if MunkiReport is unavailable, because direct SimpleMDM remains primary
- module-backed dashboard widgets should begin populating when the module responds successfully
- `Settings > Supplemental Enrichment (A)` should stop showing the generic "not available" message and start showing detected source status
- `Settings` should report `Module Data: Available` once module telemetry or supplemental status is loaded

If it does not work:

- confirm the base URL is the MunkiReport root, not a specific module endpoint
- if your MunkiReport instance does not use rewritten routes, include `index.php?` in the base URL
- keep the module path prefix at `/module/simplemdm` unless you know it is different in your deployment
- confirm your auth header or cookie is valid for authenticated module GET requests
- confirm the MunkiReport `simplemdm` module is current enough to expose the enrichment routes this app reads
- if browser-based MunkiReport pages work but the app does not, compare the exact header or cookie requirements used by your MunkiReport deployment

### Persistence And Startup Strategy

The app is designed to be usable on larger fleets and slower networks. It uses:

- SwiftData-backed persistence for cached devices, launch snapshots, resource records, smart groups, and sync history
- keychain storage for SimpleMDM and optional MunkiReport secrets
- cache-first startup so a recent fleet snapshot can appear before a live refresh finishes
- incremental page persistence during device pagination
- deferred loading of secondary dashboard resources after the initial device snapshot appears
- sync summaries that track request counts, request category, duration, and errors

The current persistence model includes:

- `PersistentDevice`
- `PersistentLaunchSnapshot`
- `PersistentResourceRecord`
- `PersistentResourceFamilyMetadata`
- `SmartGroup`
- `SyncLog`

## Platform Support

The project is a shared SwiftUI app for macOS and iOS.

Current platform-specific behavior includes:

- iOS background refresh scheduling on physical devices
- compact iPhone layouts for dashboard and inventory screens
- macOS split-view device detail with a dedicated actions sidebar
- a common shared service layer and most shared management workflows across both platforms

## Detailed Capability Breakdown

### 1. Dashboard

The dashboard is already a substantial operational screen, not just a static overview. It currently supports:

- total device KPI
- enrolled vs unenrolled KPI
- enrollment status widget
- OS version breakdown
- recently seen devices
- device posture summary
  - DEP-enrolled
  - supervised
  - FileVault enabled
- live direct-resource cards
  - DEP servers
  - scripts
  - script jobs
  - assignment groups
  - apps
  - custom declarations
  - webhooks
  - push certificate

When optional module data is available, the dashboard can also surface:

- sync health
- compliance
- assignment group distribution
- resource type distribution
- supplemental overview
- AppleCare coverage

Interactive navigation is already wired into dashboard content. Examples:

- selecting `Unenrolled` can jump into a filtered device list
- selecting a specific OS version can open devices filtered to that version
- posture panels can drive inventory filtering
- live resource cards can open resource-specific list or management screens

Startup behavior is optimized for faster first paint:

- a cached device snapshot may render first
- the first page of live devices can publish quickly
- remaining pages continue in the background
- lower-priority dashboard resources are deferred until after the initial fleet view appears

The dashboard also exposes operational health rather than hiding it:

- refresh banners
- sync health
- freshness state
- collapsible or lower-priority diagnostic surfaces so primary fleet information stays prominent

### 2. Device Inventory

The device list supports both local filtering and live server-side querying.

Current supported search and filtering behavior includes:

- server-side SimpleMDM search
  - name
  - serial
  - UDID
  - IMEI
  - MAC address
  - phone number
- status filtering
- OS-family filtering
- exact OS version filtering
- posture filtering
  - DEP enrolled
  - supervised
  - FileVault enabled
- model family filtering
- passcode compliance filtering
- assignment group filtering
- device group filtering
- last-seen recency filtering
- `include awaiting enrollment`
- `include secret custom attributes`

The device list also supports local smart groups backed by SwiftData, so operators can save and reapply local filter bundles without going back to the server.

### 3. Device Detail

Device detail is one of the deepest parts of the app.

Current device detail behavior includes:

- a dedicated overview experience
- an inventory view
- device actions
- automatic live detail loading for enrolled devices
- graceful handling for non-enrolled devices, which remain visible but cannot use live enrolled-only detail endpoints

The overview and inventory flows already expose:

- battery data
- storage data
- hardware identity
- security posture
- connected resources
- assignment group and device group context
- synced subresource summaries
- custom attributes
- full inventory fields

Device detail also supports navigation from summary cards into deeper subresource sections.

### 4. Device Subresources

The app can load and display multiple per-device subresources:

- profiles
- installed apps
- users
- logs

Subresource UI includes:

- expand/collapse behavior
- summary counts
- section-based navigation from summary rows
- device log fetches using device-specific lookup
- log-detail fetches for individual log records

When MunkiReport enrichment is configured, device detail can also show connected-resource summaries and a connected-resources section for supplemental module-backed context.

### 5. Installed Apps

Installed apps are implemented as a real workflow, not a raw JSON dump.

Current installed-app features include:

- per-device installed-app lists
- installed-app detail screens
- grouping by management and catalog state
  - managed and in catalog
  - managed and not in catalog
  - unmanaged and in catalog
  - unmanaged and not in catalog
- catalog matching against live SimpleMDM app records
- assignment-group-derived app context
- managed-app-config signal visibility

Supported installed-app actions include:

- request management
- update
- uninstall

The service layer also keeps a cached per-device installed-app inventory state so the UI does not have to recompute joins and derived state on every render.

### 6. Device Actions

The app already supports a wide range of device actions. Current action coverage includes:

- lock
- wipe
- sync or refresh
- clear passcode
- restart
- shutdown
- push apps
- clear restrictions password
- unenroll

Lost Mode support includes:

- enable
- disable
- play sound
- update location

Advanced action coverage currently includes:

- clear firmware password
- rotate firmware password
- clear recovery lock password
- rotate recovery lock password
- rotate FileVault recovery key
- set admin password
- rotate admin password
- update OS
- enable remote desktop
- disable remote desktop
- disable bluetooth
- set time zone

Safeguards already in the UI include:

- explicit confirmation for destructive actions
- lock-specific payload handling
- wipe-specific confirmation flow
- lost-mode form validation
- separation of mutation errors from detail-loading errors so a failed action does not destroy the entire device screen

Action availability is permission-aware and state-aware. The app can disable actions after observing real permission failures and present the missing permission domain in a user-facing way.

### 7. Device Editing And Assignment

Native device management already includes:

- edit the SimpleMDM record name
- edit device-facing name where supported
- create device placeholders
- assign a device to assignment groups
- remove a device from assignment groups
- optionally remove other group assignments when moving a device

On macOS, device management is especially strong because the detail view can keep actions in a dedicated sidebar.

### 8. Assignment Groups

Assignment groups are a first-class management area.

Current assignment-group workflows include:

- list and search groups
- create groups
- edit groups
- delete groups
- inspect group metadata
- inspect membership summaries
- assign and unassign apps
- assign and unassign profiles
- assign and unassign devices
- push apps
- update apps
- sync profiles
- clone groups

The group detail screen already tracks local assignment state for:

- assigned app IDs
- assigned profile IDs
- assigned device IDs

This gives the UI fast feedback while still writing back through the service layer.

### 9. Apps And App Catalog

The app catalog is managed natively.

Current app-catalog coverage includes:

- list and search app records
- create App Store catalog entries
- edit catalog entries
- delete app records
- inspect app detail
- inspect device installs for a catalog app
- jump from a catalog app into assignment-group management
- jump from a catalog app into managed-app-config workflows

This is already enough to use the app as a day-two app-catalog admin tool rather than relying exclusively on the generic API explorer.

### 10. Profiles

Profile coverage is split between live profiles and custom configuration profiles.

Current profile workflows include:

- browse live profile records
- browse custom configuration profiles
- create custom configuration profiles
- edit custom configuration profiles
- delete custom configuration profiles
- download custom configuration profile contents
- inspect live or custom profile details
- deploy profiles to devices
- deploy profiles to device groups
- manage assignment-group relationships for profiles

The codebase makes a useful distinction here:

- `custom configuration profiles` are fully managed as native CRUD workflows
- the broader live `profiles` endpoint is still available as a browsable reference and deployment surface

### 11. Custom Declarations

Custom declarations are already a native feature area.

Current declaration workflows include:

- list declarations
- inspect declaration details
- download declaration payloads
- inspect payload content in-app
- create declarations
- edit declarations
- delete declarations
- assign declarations to devices
- unassign declarations from devices
- enter declaration management from device inventory

Declaration detail currently exposes fields such as:

- name
- profile identifier
- declaration type
- reinstall-after-OS-update flag
- user scope
- attribute support
- escape attributes
- activation predicate
- device count
- group count

### 12. Managed App Configs

Managed app configurations also have native coverage.

Current supported workflows include:

- list configs by app
- create config entries
- delete config entries
- push managed-config updates
- app-linked entry points from catalog-app detail
- value-type-aware entry forms

### 13. Enrollments

Enrollment management is implemented with dedicated views.

Current enrollment workflows include:

- list active enrollments
- inspect enrollment details
- send invitations by email or phone
- review enrollment URL and auth flags
- delete enrollments with confirmation

### 14. DEP Servers

DEP server management is already in place.

Current DEP workflows include:

- list registered DEP servers
- inspect summary metadata
- trigger `sync with Apple`
- load and inspect DEP devices for a server

### 15. Push Certificate Management

The app can currently:

- show the current APNs push certificate metadata
- fetch the signed CSR
- upload replacement certificate content

### 16. Scripts And Script Jobs

Scripts and jobs are part of the lower-tier admin tooling.

Current capabilities include:

- list scripts
- create scripts
- update scripts
- delete scripts
- list script jobs
- create script jobs
- cancel script jobs
- inspect job results

### 17. Admin Center

The `Admin` tab is more than a link list. It groups operations by operational value and frequency and acts as a central launch point for native tools and API-backed endpoint workflows.

It currently includes:

- `High Value` operations
  - device search and include flags
  - device-user deletion
  - firmware and recovery-lock operations
  - FileVault key rotation
  - admin-password operations
  - OS update
  - remote desktop and bluetooth controls
  - time-zone update
  - assignment-group device assignment and unassignment
- `Medium Value` operations
  - device creation and update
  - assignment-group CRUD
  - app CRUD
  - custom attribute operations
  - enrollment invitation and deletion
  - DEP sync
- `Lower Value` operations
  - legacy device groups
  - push certificate operations
  - custom config profiles
  - managed app configs
  - scripts
  - script jobs
  - webhook reference

The Admin Center also includes direct entry points into:

- App Catalog Manager
- Profile Manager
- Enrollment Manager
- DEP Server Manager
- Push Certificate Manager
- Managed App Config Manager
- Scripts & Jobs
- Assignment Group Manager
- Create Device
- Full API Explorer
- Custom Declarations

### 18. API Explorer

The generic API explorer is still present and remains important.

It currently provides:

- a built-in catalog based on `SimpleMDM API v1.55`
- searchable endpoint discovery
- endpoint detail pages
- parameter editors
- request-body editors
- form-encoded request helpers
- live resource pickers so operators can choose existing IDs by name
- runnable endpoints where the app has enough metadata to execute them
- documentation-only entries for endpoints that are cataloged but not directly runnable

It is especially useful as:

- a fallback for long-tail endpoints
- a validation tool for new API use cases
- a bridge while a dedicated native workflow is not yet implemented

## Settings, Diagnostics, And Operator Controls

The settings area is already fairly mature.

Current settings coverage includes:

- backend mode selection
- SimpleMDM API key entry
- optional MunkiReport base URL
- optional MunkiReport auth header name and value
- optional MunkiReport cookie
- configurable module path prefix
- configurable action names for lock, wipe, and sync
- dashboard-widget visibility control
- sync-capability visibility
- sync history visibility and clearing
- cache freshness reporting
- cache TTL overrides
  - device snapshot
  - primary dashboard resources
  - apps catalog
  - custom declarations
  - custom configuration profiles
- bundle version and build visibility
- debug logging toggle for full fleet sync pagination
- `Clear Saved Connection`

Two settings-adjacent informational screens also exist for hybrid deployments:

- `Supplemental Enrichment (A)`
  - live detection-oriented view for module-backed enrichment sources when available
- `Client Reporter Ingestion (B)`
  - explanatory and guidance-oriented screen for client-reporter concepts
  - currently includes mock example content rather than a live ingestion control plane

## API Permission Model

The app can still be useful with a mostly read-only API key, but many write flows require the matching SimpleMDM permission domain.

The code explicitly models these permission domains:

- `Devices: write`
- `Assignment Groups: write`
- `Installed Apps: write`
- `Profiles: write`
- `Apps: write`
- `Managed App Configs: write`

Current permission behavior includes:

- disabling actions after observed `401` or `403` failures
- surfacing missing permission requirements in the UI
- avoiding raw backend error dumps when the permission issue is already understood

## Performance Characteristics

The current codebase already includes several non-trivial performance and reliability optimizations:

- paginated fleet loading
- background continuation after the first page
- reuse of cached launch snapshots
- recovery from incomplete earlier pagination runs
- per-family resource TTLs
- deferred secondary resource loading
- per-device lazy detail hydration
- reduced repeated recomputation for installed-app joins
- request throttling through a concurrency limiter
- refresh banners rather than hard UI resets during live reloads
- sync-history retention capped to the most recent 100 syncs per host

The app also distinguishes between:

- `Full Fleet Snapshot`
  - a fully completed cached fleet snapshot
- `Incremental Snapshot Recovery`
  - a partial previously persisted snapshot that can still render immediately while background refresh continues

This is useful in large fleets because the user does not have to wait for a full cold sync every time the app launches.

## How Data Flows Through The App

This app has two distinct data paths:

- `Direct SimpleMDM`
  - the primary operational path
  - used for fleet inventory, device detail, resources, and write actions
- `Optional MunkiReport enrichment`
  - a secondary read-only enrichment path
  - used to add supplemental dashboard and device-context data when available

In normal operation, the app does not choose one or the other. It does both in parallel when hybrid mode is enabled:

- SimpleMDM provides the core truth
- MunkiReport adds extra context where the module has data

### Core Direct Data Path

The direct SimpleMDM path is responsible for:

- loading the device list
- loading resource catalogs such as:
  - device groups
  - assignment groups
  - profiles
  - custom configuration profiles
  - apps
  - custom attributes
  - custom declarations
  - scripts
  - enrollments
  - DEP servers
  - script jobs
  - webhooks
  - push certificate
- loading per-device detail
- loading per-device subresources
- executing all direct write operations

The app configures a shared `SimpleMDMService` instance at startup. That service owns:

- current live device state
- dashboard snapshot state
- cached resource catalogs
- per-device detail state
- per-device subresource state
- installed-app derived state
- dashboard/module enrichment state
- refresh banners
- sync and freshness reporting

### Optional Module Enrichment Path

When hybrid mode is configured, the same service also sends authenticated GET requests to the MunkiReport `simplemdm` module.

Those module requests are used for:

- sync telemetry
- command-status summaries
- compliance summaries
- assignment-group stats
- resource-type stats
- OS-security summaries
- supplemental status
- supplemental overview
- AppleCare summaries
- device connected-resource context

The key rule is:

- direct SimpleMDM data remains authoritative
- module data is layered on top only where the app has dedicated enrichment surfaces for it

## Startup, Sync, Cache, And Snapshot Lifecycle

### Launch Sequence

At a high level, the startup flow is:

1. The app creates the SwiftData container.
2. `Settings` loads saved configuration from user defaults and keychain.
3. `SimpleMDMService` is created and attached to the environment.
4. `ContentView` decides whether to show the setup screen or the main tab UI.
5. `MainTabView` calls `service.configure(...)` with the current settings.
6. The app waits briefly so the first frame can render cleanly.
7. `ensureInitialLoad()` begins the initial data process.
8. Deferred dashboard resources are scheduled after launch.

The launch path is intentionally split so the UI can render quickly before more expensive cache hydration and network work begins.

### What Happens During Initial Load

During initial load, the service tries to minimize time-to-first-usable-screen:

1. Check whether the current connection is configured.
2. Check whether a cached launch snapshot exists for the current configuration fingerprint.
3. If a fresh cached snapshot exists, publish it immediately.
4. Start or resume live SimpleMDM device loading.
5. Publish the first useful device page as soon as possible.
6. Continue remaining device pagination in the background.
7. Load primary dashboard resources.
8. Load optional module enrichment routes if hybrid mode is enabled.
9. Load deferred lower-priority dashboard resources shortly after launch.

This is why the user can sometimes see:

- cached data first
- then a refresh banner
- then more complete live data as background work finishes

### Device Sync Strategy

The app does not have an upstream incremental token from SimpleMDM, so the direct sync strategy is based on:

- full-resource fetch fallback
- paginated device retrieval
- selective cache reuse
- targeted revalidation using TTLs and cached timestamps

That produces three practical sync modes in the UI:

- `Full Fleet Snapshot`
  - the cached default fleet snapshot completed successfully
- `Incremental Snapshot Recovery`
  - cached data exists, but the last session ended before full pagination completed
- `Incremental Query Paging`
  - active server-filtered device queries are loading page by page

### Snapshots

The app uses launch snapshots so the dashboard and device list can become useful immediately after launch.

Snapshot behavior currently works like this:

1. A default-query device snapshot is persisted locally.
2. Snapshot freshness is evaluated using the configured TTL.
3. If the snapshot is still considered fresh, it can be shown immediately.
4. If it is stale or incomplete, it may still be reused as a recovery baseline while live pagination continues.
5. As fresh device pages arrive, the in-memory device set and dashboard snapshot are updated.

The snapshot model is not just a screenshot of the UI. It is a persisted fleet-data payload the app can decode back into live device models.

### Resource Cache Lifecycle

The app also caches non-device resource families separately.

Examples include:

- primary dashboard resources
- apps catalog
- custom declarations
- custom configuration profiles

Each family has:

- its own TTL
- its own cache timestamp
- its own freshness check

This lets the app avoid reloading every resource family on every launch while still allowing operators to tune cache aggressiveness in Settings.

### Deferred Resource Loading

Some resources are intentionally deferred until after the initial device/dashboard content appears.

That means:

- the first useful dashboard can render faster
- less critical resource catalogs can catch up shortly afterward
- the app avoids blocking first paint on lower-priority calls

### Sync Tracking And Finalization

The app tracks sync sessions in a dedicated sync tracker.

Tracked read activity is categorized into:

- device requests
- resource requests
- module requests
- other requests

When a sync session goes idle, it can be finalized into a summary that records:

- duration
- device count
- request count
- request category counts
- error count
- last error
- host
- source such as manual or background

Recent summaries are stored in `SyncLog` and surfaced in Settings and dashboard sync-health views.

## How MunkiReport Enrichment Is Merged

### What MunkiReport Does Not Replace

The optional MunkiReport module does not replace:

- the SimpleMDM device list
- SimpleMDM device detail
- SimpleMDM device actions
- app, profile, assignment-group, and declaration management

Those remain direct SimpleMDM flows in this app.

### What MunkiReport Adds

The module adds secondary context that is useful for:

- dashboard summaries
- operational telemetry
- compliance rollups
- source-detection status
- AppleCare/supplemental coverage views
- device connected-resource summaries

### Merge Model

The merge model is intentionally simple:

1. Load direct SimpleMDM data first or in parallel.
2. Load optional module JSON routes.
3. Decode module payloads into dedicated enrichment models.
4. Publish those models into `moduleDashboardData` or device-connected-resource state.
5. Show module widgets only when relevant data exists.
6. Fall back to direct-only views when module data is absent.

This means the app can stay fully usable when:

- MunkiReport is not configured
- the module is unavailable
- the module is authenticated differently than expected
- supplemental data exists only for some parts of the fleet

### Module Endpoint Pattern Used By The App

The app constructs module requests as:

- `{MunkiReport Base URL}/{Module Path Prefix}/{route}`

Examples:

- `https://munkireport.example.com/module/simplemdm/get_device_resources/SERIAL123`
- `https://munkireport.example.com/index.php?/module/simplemdm/get_sync_telemetry`

The app currently reads module routes for things such as:

- `get_sync_telemetry`
- `get_device_resources/{serial}`

And newer enrichment/data routes used by the app for dashboard payloads, including:

- compliance
- command status
- assignment groups
- resource types
- OS security
- supplemental status
- supplemental overview
- AppleCare

Because of that, the app expects a current version of the MunkiReport `simplemdm` module.

### How The UI Uses Module Data

Module data is not blindly merged into base device objects. Instead, it is displayed through dedicated UI surfaces such as:

- dashboard module widgets
- sync-health panels
- compliance panels
- supplemental-enrichment status views
- device connected-resource summaries

This is an important design choice because it prevents supplemental data from overriding core SimpleMDM truth while still making the enrichment visible where it is useful.

## Quickstart

If you want to get productive in `ReportSimpleMDM` as quickly as possible:

1. Launch the app.
2. Open `Settings > Server & API` if the setup screen is not already visible.
3. Enter a valid `SimpleMDM API Key`.
4. Save and confirm the dashboard loads direct fleet data.
5. Open `Devices` and confirm inventory is visible.
6. Open one enrolled device and confirm overview, inventory, and actions load.
7. If you use MunkiReport enrichment, switch to `SimpleMDM + MunkiReport Module`.
8. Enter the MunkiReport base URL and auth settings.
9. Save and confirm module-backed widgets begin to populate.
10. Review `Settings` for sync status, freshness, and cache behavior.

First things to verify after setup:

- dashboard KPI cards load
- device inventory loads
- one device detail page loads
- refresh works
- optional MunkiReport enrichment loads if configured

## Deployment Examples

These examples are for `ReportSimpleMDM` configuration patterns. They are representative deployment examples based on the app's supported configuration model, not copied secrets from a live environment.

### Example 1: Direct SimpleMDM Only

Use this when you do not want MunkiReport enrichment at all.

- `Backend Mode`: `SimpleMDM API Only`
- `SimpleMDM API Key`: your real SimpleMDM API key
- `MunkiReport Base URL`: blank
- `Module Path Prefix`: leave default or ignore
- `Auth Header Name`: blank
- `Auth Header Value`: blank
- `Cookie Header`: blank

Expected result:

- all core `ReportSimpleMDM` functionality should work
- no module-backed enrichment widgets will populate

### Example 2: MunkiReport With Header Auth

Use this when your MunkiReport deployment expects an auth header on module GET requests.

- `Backend Mode`: `SimpleMDM + MunkiReport Module`
- `SimpleMDM API Key`: your real SimpleMDM API key
- `MunkiReport Base URL`: `https://munkireport.example.com`
- `Module Path Prefix`: `/module/simplemdm`
- `Auth Header Name`: your MunkiReport-required header name
- `Auth Header Value`: your MunkiReport-required header value
- `Cookie Header`: blank

Expected result:

- direct SimpleMDM data loads first
- module-backed enrichment loads if the module accepts the header

### Example 3: MunkiReport With Session Cookie

Use this when module requests need to look like an authenticated MunkiReport browser session.

- `Backend Mode`: `SimpleMDM + MunkiReport Module`
- `SimpleMDM API Key`: your real SimpleMDM API key
- `MunkiReport Base URL`: `https://munkireport.example.com`
- `Module Path Prefix`: `/module/simplemdm`
- `Auth Header Name`: blank unless also required
- `Auth Header Value`: blank unless also required
- `Cookie Header`: full cookie header string such as `ci_session=...; other_cookie=...`

Expected result:

- direct SimpleMDM data loads first
- module enrichment loads only if the cookie is valid and accepted for module routes

### Example 4: Non-Rewrite MunkiReport Routing

Use this when the MunkiReport deployment requires `index.php?` in route construction.

- `Backend Mode`: `SimpleMDM + MunkiReport Module`
- `MunkiReport Base URL`: `https://munkireport.example.com/index.php?`
- `Module Path Prefix`: `/module/simplemdm`

Expected request shape:

- `https://munkireport.example.com/index.php?/module/simplemdm/get_sync_telemetry`

### Example 5: `X-SIMPLEMDM-API-KEY` Fallback Pattern

Use this only if your MunkiReport deployment is intentionally configured to accept the same SimpleMDM API key header on module reads.

- `Backend Mode`: `SimpleMDM + MunkiReport Module`
- `SimpleMDM API Key`: your real SimpleMDM API key
- `MunkiReport Base URL`: `https://munkireport.example.com`
- `Module Path Prefix`: `/module/simplemdm`
- `Auth Header Name`: `X-SIMPLEMDM-API-KEY`
- `Auth Header Value`: leave blank
- `Cookie Header`: blank

Expected behavior:

- `ReportSimpleMDM` can reuse the direct API key as the header value on module requests
- this should only be used when your MunkiReport deployment explicitly supports that pattern

## Feature To Data Source Mapping

The table below summarizes where major app features get their data.

### Direct SimpleMDM-Backed

- Dashboard KPI counts
  - derived from the live or cached device set
- Device list
  - SimpleMDM devices endpoint
- Device detail
  - SimpleMDM device detail endpoint
- Device subresources
  - SimpleMDM subresource endpoints for profiles, installed apps, users, and logs
- Assignment groups
  - SimpleMDM assignment-group endpoints
- Apps catalog
  - SimpleMDM apps endpoints
- Profiles
  - SimpleMDM profiles and custom configuration profile endpoints
- Custom declarations
  - SimpleMDM custom declaration endpoints
- Managed app configs
  - SimpleMDM managed-app-config endpoints
- Enrollments
  - SimpleMDM enrollment endpoints
- DEP servers
  - SimpleMDM DEP endpoints
- Push certificate
  - SimpleMDM push-certificate endpoints
- Scripts and script jobs
  - SimpleMDM scripts and script-jobs endpoints
- Device actions
  - direct SimpleMDM action endpoints

### Locally Derived Or Cached

- Fleet launch snapshot
  - persisted `PersistentLaunchSnapshot`
- Cached device rows
  - persisted `PersistentDevice`
- Cached resource records
  - persisted `PersistentResourceRecord`
- Smart groups
  - persisted `SmartGroup`
- Sync history
  - persisted `SyncLog`
- Installed-app grouping and assignment-derived state
  - derived in service memory and cached per device
- Freshness and TTL state
  - user defaults plus persisted metadata and timestamps

### MunkiReport-Enriched

- Sync health widget
  - module sync telemetry and command-status payloads
- Compliance widget
  - module compliance payload and supplemental status
- Assignment-group and resource-type rollups
  - module stats when available, otherwise some direct fallback data may still exist
- Supplemental overview
  - module supplemental overview payload
- AppleCare widget
  - module AppleCare stats payload
- Supplemental Enrichment settings screen
  - module supplemental-status payload
- Device connected resources
  - module `get_device_resources/{serial}` route

## Capability Matrix

This matrix is about what `ReportSimpleMDM` itself can still do depending on which data source is available.

### Works With Direct SimpleMDM Only

- app launch and configuration
- fleet dashboard KPI cards
- device inventory
- device filtering and search
- device detail
- device subresources from SimpleMDM
- device actions
- assignment-group management
- app-catalog management
- profile management
- custom declaration management
- managed-app-config management
- enrollments
- DEP servers
- push certificate management
- scripts and script jobs
- API explorer
- cache reuse, launch snapshots, sync history, and freshness reporting

### Improved By MunkiReport But Not Dependent On It

- sync health presentation
- compliance summary panels
- assignment-group distribution widgets
- resource-type distribution widgets
- supplemental overview
- AppleCare coverage widgets
- device connected-resource summaries
- supplemental-enrichment visibility in settings

### Local-Only Or Locally Derived

- cached launch snapshots
- cached resource families
- local smart groups
- sync history
- freshness calculations
- installed-app derived grouping state
- cached assignment-derived app state

### What Happens If MunkiReport Is Unavailable

If the optional MunkiReport module is unavailable, `ReportSimpleMDM` should still:

- load devices directly from SimpleMDM
- show dashboard KPI and direct-resource content
- open device detail and run direct actions
- manage apps, profiles, declarations, assignment groups, and other direct resources

What you lose is enrichment, not core functionality.

## Permission Matrix

This matrix is specifically about `ReportSimpleMDM` write workflows and the SimpleMDM permission domains they depend on.

### `Devices: write`

Required for:

- lock
- wipe
- sync or refresh
- clear passcode
- restart
- shutdown
- push apps
- clear restrictions password
- lost-mode actions
- unenroll
- advanced device actions
- editing device records
- creating device placeholders
- deleting device users

### `Assignment Groups: write`

Required for:

- creating assignment groups
- editing assignment groups
- deleting assignment groups
- assigning or unassigning devices to groups
- assigning or unassigning apps to groups
- assigning or unassigning profiles to groups
- pushing apps from groups
- updating apps from groups
- syncing profiles from groups
- cloning assignment groups

### `Installed Apps: write`

Required for:

- request management on installed apps
- updating installed apps
- uninstalling installed apps

### `Profiles: write`

Required for:

- deploying profiles to devices
- deploying profiles to groups
- changing profile assignment relationships
- removing profiles from devices when that workflow is used

### `Apps: write`

Required for:

- creating app-catalog entries
- editing app-catalog entries
- deleting app-catalog entries

### `Managed App Configs: write`

Required for:

- creating managed app config entries
- deleting managed app config entries
- pushing managed app config updates

### Practical Permission Guidance

- a read-only or mostly read-only API key is still useful for inventory and reporting
- the more write workflows you expect to use, the broader the required permission set
- `ReportSimpleMDM` can learn from real `401/403` failures and disable unsupported actions after that evidence is observed
- direct SimpleMDM read access remains the baseline requirement for the app to be useful

## Endpoint Appendix

This appendix is specifically about `ReportSimpleMDM` feature wiring: feature area, primary `SimpleMDMService` method, and the exact upstream route or route pattern used by the app.

### Direct SimpleMDM Feature Wiring

| Feature | Service method | Upstream route |
|---|---|---|
| Initial/default device fleet load | `getDevices(query:)` | `GET /api/v1/devices` |
| Direct device detail | `getDeviceDetails(id:)` | `GET /api/v1/devices/{id}` |
| Device profiles subresource | `getDeviceDetails(id:)` | `GET /api/v1/devices/{id}/profiles` |
| Device installed apps subresource | `getDeviceDetails(id:)` | `GET /api/v1/devices/{id}/installed_apps` |
| Device users subresource | `getDeviceDetails(id:)` | `GET /api/v1/devices/{id}/users` |
| Device logs by serial | device-detail log load path in service | `GET /api/v1/logs?serial_number={serial}` |
| Individual log detail | log-detail load path in service | `GET /api/v1/logs/{id}` |
| Device groups catalog | deferred/primary resource load | `GET /api/v1/device_groups` |
| Assignment groups catalog | deferred/primary resource load | `GET /api/v1/assignment_groups` |
| Profiles catalog | deferred resource load | `GET /api/v1/profiles` |
| Custom configuration profiles catalog | deferred resource load | `GET /api/v1/custom_configuration_profiles` |
| Apps catalog | deferred resource load | `GET /api/v1/apps?include_shared=true` |
| Custom attributes catalog | deferred resource load | `GET /api/v1/custom_attributes` |
| Custom declarations catalog | deferred resource load | `GET /api/v1/custom_declarations` |
| Scripts catalog | deferred resource load | `GET /api/v1/scripts` |
| Enrollments catalog | deferred resource load | `GET /api/v1/enrollments` |
| DEP servers catalog | deferred resource load | `GET /api/v1/dep_servers` |
| Script jobs catalog | deferred resource load | `GET /api/v1/script_jobs` |
| Push certificate summary | deferred/primary resource load | `GET /api/v1/push_certificate` |

### Direct Mutation Wiring

| Feature | Service method | Upstream route |
|---|---|---|
| Download custom declaration | `downloadCustomDeclaration(id:)` | `GET /api/v1/custom_declarations/{id}/download` |
| Create custom declaration | `createCustomDeclaration(input:)` | `POST /api/v1/custom_declarations` |
| Update custom declaration | `updateCustomDeclaration(id:input:)` | `PATCH /api/v1/custom_declarations/{id}` |
| Delete custom declaration | `deleteCustomDeclaration(id:)` | `DELETE /api/v1/custom_declarations/{id}` |
| Create device | `createDevice(input:)` | `POST /api/v1/devices` |
| Update device | `updateDevice(id:input:)` | `PATCH /api/v1/devices/{id}` |
| Set device assignment-group membership | `setAssignmentGroupMembership(...)` | `POST` or `DELETE /api/v1/assignment_groups/{groupID}/devices/{deviceID}` |
| Delete device user | `deleteDeviceUser(deviceID:userID:)` | `DELETE /api/v1/devices/{deviceID}/users/{userID}` |
| Create assignment group | `createAssignmentGroup(...)` | `POST /api/v1/assignment_groups` |
| Update assignment group | `updateAssignmentGroup(...)` | `PATCH /api/v1/assignment_groups/{id}` |
| Delete assignment group | `deleteAssignmentGroup(id:)` | `DELETE /api/v1/assignment_groups/{id}` |
| Set assignment-group app link | `setAssignmentGroupAppLink(...)` | `POST` or `DELETE /api/v1/assignment_groups/{groupID}/apps/{appID}` |
| Set assignment-group profile link | `setAssignmentGroupProfileLink(...)` | `POST` or `DELETE /api/v1/assignment_groups/{groupID}/profiles/{profileID}` |
| Group action: push/update/sync/clone | group action path in service | `POST /api/v1/assignment_groups/{id}/{action}` |
| Create catalog app | `createCatalogApp(input:)` | `POST /api/v1/apps` |
| Update catalog app | `updateCatalogApp(id:input:)` | `PATCH /api/v1/apps/{id}` |
| Delete catalog app | `deleteCatalogApp(id:)` | `DELETE /api/v1/apps/{id}` |
| Create custom config profile | `createCustomConfigurationProfile(input:)` | `POST /api/v1/custom_configuration_profiles` |
| Update custom config profile | `updateCustomConfigurationProfile(id:input:)` | `PATCH /api/v1/custom_configuration_profiles/{id}` |
| Delete custom config profile | `deleteCustomConfigurationProfile(id:)` | `DELETE /api/v1/custom_configuration_profiles/{id}` |
| Download custom config profile | `downloadCustomConfigurationProfile(id:)` | `GET /api/v1/custom_configuration_profiles/{id}/download` |
| Send enrollment invitation | `sendEnrollmentInvitation(id:contact:)` | `POST /api/v1/enrollments/{id}/invitations` |
| Delete enrollment | `deleteEnrollment(id:)` | `DELETE /api/v1/enrollments/{id}` |
| Sync DEP server | `syncDEPServer(id:)` | `POST /api/v1/dep_servers/{id}/sync` |
| Load DEP devices | `fetchDEPDevices(serverID:)` | `GET /api/v1/dep_servers/{serverID}/dep_devices` |
| Load one DEP device | DEP detail helper | `GET /api/v1/dep_servers/{serverID}/dep_devices/{deviceID}` |
| Download push CSR | push certificate helper | `GET /api/v1/push_certificate/scsr` |
| Update push certificate | `updatePushCertificate(...)` | `PUT /api/v1/push_certificate` |
| Load managed configs | managed config list helper | `GET /api/v1/apps/{appID}/managed_configs` |
| Create managed config | `createManagedConfig(appID:input:)` | `POST /api/v1/apps/{appID}/managed_configs` |
| Delete managed config | `deleteManagedConfig(appID:configID:)` | `DELETE /api/v1/apps/{appID}/managed_configs/{configID}` |
| Push managed configs | managed config push helper | `POST /api/v1/apps/{appID}/managed_configs/push` |
| Load one script | script detail helper | `GET /api/v1/scripts/{id}` |
| Create script | `createScript(input:)` | `POST /api/v1/scripts` |
| Update script | `updateScript(id:input:)` | `PATCH /api/v1/scripts/{id}` |
| Delete script | `deleteScript(id:)` | `DELETE /api/v1/scripts/{id}` |
| Load one script job | script job detail helper | `GET /api/v1/script_jobs/{id}` |
| Create script job | `createScriptJob(input:)` | `POST /api/v1/script_jobs` |
| Cancel script job | `cancelScriptJob(id:)` | `DELETE /api/v1/script_jobs/{id}` |
| Assign declaration to device | declaration-device link helper | `POST /api/v1/custom_declarations/{id}/devices/{deviceID}` |
| Unassign declaration from device | declaration-device link helper | `DELETE /api/v1/custom_declarations/{id}/devices/{deviceID}` |

### Device Action Wiring

| Feature | Service method | Upstream route |
|---|---|---|
| Lock device | device action request builder | `POST /api/v1/devices/{id}/{lockActionName}` |
| Wipe device | device action request builder | `POST /api/v1/devices/{id}/{wipeActionName}` |
| Sync device | device action request builder | `POST /api/v1/devices/{id}/{syncActionName}` |
| Clear passcode | installed device action path | `POST /api/v1/devices/{id}/clear_passcode` |
| Restart | installed device action path | `POST /api/v1/devices/{id}/restart` |
| Shutdown | installed device action path | `POST /api/v1/devices/{id}/shutdown` |
| Request installed-app management | installed app action path | `POST /api/v1/installed_apps/{id}/request_management` |
| Update installed app | installed app action path | `POST /api/v1/installed_apps/{id}/update` |
| Uninstall installed app | installed app action path | `DELETE /api/v1/installed_apps/{id}` |
| Enable lost mode | lost-mode action path | `POST /api/v1/devices/{id}/lost_mode` |
| Disable lost mode | lost-mode action path | `DELETE /api/v1/devices/{id}/lost_mode` |
| Play lost-mode sound | lost-mode action path | `POST /api/v1/devices/{id}/lost_mode/play_sound` |
| Update lost-mode location | lost-mode action path | `POST /api/v1/devices/{id}/lost_mode/update_location` |

### MunkiReport Enrichment Wiring

| Feature | Service method | Module route |
|---|---|---|
| Sync telemetry | module dashboard load path | `{base}/{prefix}/inventory/data/sync_health` |
| Compliance summary | module dashboard load path | `{base}/{prefix}/simplemdm/data/compliance_stats` |
| Command status summary | module dashboard load path | `{base}/{prefix}/simplemdm/data/command_status_stats` |
| Assignment-group stats | module dashboard load path | `{base}/{prefix}/simplemdm/data/assignment_group_stats` |
| Resource-type stats | module dashboard load path | `{base}/{prefix}/simplemdm/data/resource_type_stats` |
| OS-security stats | module dashboard load path | `{base}/{prefix}/simplemdm/data/os_security_stats` |
| Supplemental status | module dashboard load path | `{base}/{prefix}/simplemdm/data/supplemental_status` |
| Supplemental overview | module dashboard load path | `{base}/{prefix}/simplemdm/data/supplemental_overview` |
| AppleCare stats | module dashboard load path | `{base}/{prefix}/simplemdm/data/apple_care_stats` |
| Device connected resources | device connections load path | `{base}/{prefix}/get_device_resources/{serial}` |

## Failure Modes And Fallback Behavior

This section describes `ReportSimpleMDM` behavior when something goes wrong.

### Missing Or Invalid SimpleMDM API Key

Expected behavior:

- the app cannot load direct fleet data
- setup or settings remain the place to correct the key
- dashboard and device inventory will not become operational because direct SimpleMDM is the primary source of truth

### MunkiReport Auth Failure

Expected behavior:

- direct SimpleMDM functionality should still work
- module-backed dashboard panels may remain empty
- `Supplemental Enrichment (A)` may continue showing unavailable or undetected-source messaging
- `Module Data: Available` may never appear in Settings

### MunkiReport Module Missing Or Outdated

Expected behavior:

- direct SimpleMDM remains usable
- enrichment routes may fail to decode or return no data
- module-backed widgets may not populate
- device connected-resource summaries from the module may remain empty

This app expects a current `simplemdm` module revision that exposes the enrichment routes it reads.

### Partial Snapshot Recovery

Expected behavior:

- the app may show recovered cached fleet data first
- refresh continues in the background
- the UI should converge toward current live data as pagination completes
- sync strategy screens can reflect that the cached snapshot was incomplete

### Stale Cache

Expected behavior:

- stale cache may still help first paint
- the app should trigger background refresh/revalidation based on TTL rules
- the user may briefly see cached content and then updated live content

### Write Permission Denied

Expected behavior:

- the app can still remain useful in read-heavy workflows
- write actions may fail initially and then become disabled after real permission evidence is observed
- the UI should surface permission requirements instead of only raw backend failures

### Device Action Failure

Expected behavior:

- action errors should remain scoped to action status
- the whole device detail screen should not be replaced by an action failure
- the user should still be able to inspect the device

### Non-Enrolled Device Detail

Expected behavior:

- the device record can still appear in inventory
- direct enrolled-only detail endpoints may not be available
- the UI should keep inventory context visible while explaining the limitation

## Known Limitations

These are current boundaries of `ReportSimpleMDM`, not generic limitations of SimpleMDM or MunkiReport.

- direct SimpleMDM remains the primary source of truth, so the app is not useful without a valid SimpleMDM API key
- optional MunkiReport enrichment improves visibility but does not replace direct SimpleMDM connectivity
- some long-tail SimpleMDM operations still rely on the API explorer or endpoint presets rather than a highly custom native form
- hybrid-mode enrichment depends on a current `simplemdm` MunkiReport module revision that exposes the routes this app reads
- non-enrolled devices do not have the same live detail coverage as enrolled devices
- automated validation in this repo is currently limited by scheme/build-environment issues described below
- cache and snapshot reuse improves responsiveness, but the app can still briefly show recovered or stale content before live revalidation converges
- permission discovery is partly evidence-based, so some unsupported write actions may only disable after an initial real permission failure

## Known Bugs

The repository does not currently maintain a formal in-repo bug tracker or release-tagged bug list for `ReportSimpleMDM`. No separate confirmed bug inventory was found in the repo.

Current known problem areas worth documenting are:

- hybrid-mode enrichment can fail silently from the user's perspective if the MunkiReport module is present but does not expose the newer routes `ReportSimpleMDM` expects
- permission-aware action disabling is evidence-driven, so an unsupported write action may remain visible until the app sees a real denial
- cached or recovered snapshots can briefly present older data until live revalidation completes
- non-enrolled devices intentionally have reduced live-detail coverage, which can sometimes be mistaken for a broken detail flow

These are documented here because they are realistic operator pain points, even if the repo does not currently track them as formal numbered bugs.

## Security And Secrets

This section is specifically about `ReportSimpleMDM`.

### Secrets Stored By The App

`ReportSimpleMDM` stores these sensitive values in the keychain:

- SimpleMDM API key
- optional MunkiReport auth-header value
- optional MunkiReport cookie

### Non-Secret Configuration Stored By The App

The app stores non-secret operator preferences and connection metadata in user defaults, such as:

- backend mode
- MunkiReport base URL
- module path prefix
- action-name overrides
- dashboard widget visibility
- TTL overrides
- debug toggles

### Cached Operational Data Stored By The App

The app stores local cached operational data through SwiftData, including:

- cached devices
- cached launch snapshots
- cached resource records
- smart groups
- sync history

### Important Security Boundaries

- `ReportSimpleMDM` talks directly to the SimpleMDM API for its primary operational data and mutations
- the optional MunkiReport module is used only as an enrichment source in this app
- the app does not depend on the module's admin passthrough API for its main device-management behavior
- clearing saved connection data removes stored secrets without wiping every other preference

### Practical Security Implications

- if you give the app a write-capable SimpleMDM API key, the app can execute real production mutations
- if you configure a MunkiReport cookie, the app will send that cookie on module requests
- if you configure a MunkiReport auth header, the app will send that header on module requests
- if you leave the header value empty and the header name is `X-SIMPLEMDM-API-KEY`, the app can fall back to using the direct SimpleMDM API key as that header value

That last behavior is convenient, but it should only be used if your MunkiReport deployment is intentionally designed to accept it.

## Architecture Diagram

This is the high-level runtime model for `ReportSimpleMDM`:

```text
                        +----------------------+
                        |  SimpleMDM API       |
                        |  Primary truth       |
                        +----------+-----------+
                                   ^
                                   |
                        direct read/write requests
                                   |
+--------------------+   +---------+----------+   +----------------------+
| SwiftUI App        |<->| SimpleMDMService   |<->| MunkiReport          |
| Dashboard          |   | State + sync       |   | simplemdm module     |
| Devices            |   | cache + enrichment |   | Optional enrichment  |
| Admin              |   +---------+----------+   +----------------------+
| Settings           |             ^
+---------+----------+             |
          |                        |
          v                        v
  +-------+--------+      +--------+--------+
  | SwiftData       |      | Keychain        |
  | snapshots/cache |      | secrets         |
  +-----------------+      +-----------------+
```

Interpretation:

- the SwiftUI app talks through `SimpleMDMService`
- `SimpleMDMService` talks directly to SimpleMDM for primary operations
- `SimpleMDMService` optionally talks to the MunkiReport module for enrichment
- SwiftData stores cached operational state
- Keychain stores secrets

## Troubleshooting Recipes

These are app-focused recipes for `ReportSimpleMDM`.

### If direct fleet data does not load

Check:

- that the SimpleMDM API key is saved
- that the app is in the expected backend mode
- that the dashboard or device list is not showing a direct API error message
- that the key has enough read access for inventory workflows

### If direct fleet data loads but module widgets stay empty

Check:

- that `Backend Mode` is `SimpleMDM + MunkiReport Module`
- that `MunkiReport Base URL` points at the site root, not a specific endpoint
- that `Module Path Prefix` is `/module/simplemdm` unless intentionally customized
- that your auth header or cookie is valid for authenticated module GET requests
- that the MunkiReport `simplemdm` module is current enough for the routes this app reads

### If MunkiReport works in the browser but not in the app

Check:

- whether the browser is relying on a session cookie you have not copied into `Cookie Header`
- whether the MunkiReport deployment expects a specific auth header
- whether the site needs non-rewrite routing with `index.php?` in the base URL

### If a write action appears but fails

Check:

- whether the API key really has the required write permission domain
- whether the failure was a one-time denial that the app has not yet converted into disabled state
- whether the device is enrolled and supports that action

### If device detail is incomplete for one device

Check:

- whether the device is non-enrolled
- whether subresource loading is still in progress
- whether the missing area is direct SimpleMDM detail or optional module enrichment

### If relaunch shows old data first

Check:

- whether the app is intentionally reusing a snapshot for fast first paint
- whether a refresh banner appears shortly afterward
- whether freshness and sync history in `Settings` indicate background convergence is still happening

### If module connection worked before but stopped

Check:

- whether the MunkiReport cookie expired
- whether the auth header changed
- whether the MunkiReport module was updated or downgraded
- whether the deployment routing changed from rewrite to non-rewrite or vice versa

## Glossary

This glossary is specific to the language used in `ReportSimpleMDM`.

### Snapshot

A locally persisted fleet-data payload that the app can restore quickly at launch to reduce time-to-first-usable-screen.

### Full Fleet Snapshot

A cached default fleet snapshot where the previous device pagination completed successfully.

### Incremental Snapshot Recovery

A startup mode where the app reuses a partial earlier snapshot immediately and continues live pagination in the background.

### Deferred Resources

Lower-priority resource loads scheduled shortly after the first useful dashboard/device content appears.

### Freshness

The app's decision about whether cached data is still acceptable to reuse before revalidation.

### TTL

Time to live. The freshness window used to decide whether a cached resource family or snapshot should be treated as fresh or stale.

### Resource Family

A cacheable grouping of related API-backed records such as apps, custom declarations, or custom configuration profiles.

### Sync Telemetry

Operational metadata about module or app sync behavior, such as last status, timing, or cursor/delta information when available.

### Supplemental Status

Module-backed visibility into which optional enrichment sources are detected, enabled, and currently have data.

### Supplemental Overview

A higher-level summary payload derived from supplemental module data, used for fleet overview widgets.

### Connected Resources

Module-backed per-device related-resource context shown in device detail when MunkiReport enrichment is available.

### Direct SimpleMDM

The primary operational data path where `ReportSimpleMDM` talks straight to the SimpleMDM API.

### Hybrid Mode

The app mode where direct SimpleMDM remains primary and MunkiReport module reads are layered in for optional enrichment.

### Configuration Fingerprint

A hash-like identity derived from connection settings and, for some caches, the active query, used to prevent cache reuse across different tenants or modes.

## Contributor Architecture Notes

This section is for contributors who need to know which files own which responsibilities inside `ReportSimpleMDM`.

### App Bootstrap And Global Environment

- `ReportSimpleMDM/ReportSimpleMDMApp.swift`
  - app entry point
  - SwiftData container creation
  - environment object wiring
  - iOS background refresh registration
- `ReportSimpleMDM/ContentView.swift`
  - decides between setup flow and main app shell
  - owns tab layout and initial service configuration trigger

### Configuration And Persistence

- `ReportSimpleMDM/Settings.swift`
  - operator configuration model
  - backend mode, module URL, action names, TTLs, widget visibility
- `ReportSimpleMDM/KeychainStore.swift`
  - keychain save/load helpers for sensitive values
- `ReportSimpleMDM/PersistenceModels.swift`
  - SwiftData models for device cache, snapshots, resources, smart groups, and sync logs

### Core Service Layer

- `ReportSimpleMDM/SimpleMDMService.swift`
  - primary app data orchestrator
  - direct SimpleMDM reads and writes
  - module enrichment reads
  - cache hydration and snapshot persistence
  - refresh state, banners, and error handling
  - per-device derived inventory state
- `ReportSimpleMDM/SyncSessionTracker.swift`
  - sync session accounting and request categorization

### Main App Surfaces

- `ReportSimpleMDM/DashboardView.swift`
  - dashboard composition
  - KPI, direct panels, and module-backed panels
- `ReportSimpleMDM/DeviceListView.swift`
  - device inventory, filters, smart groups, and navigation into device detail
- `ReportSimpleMDM/Device/Detail/DeviceDetailView.swift`
  - device overview, inventory, and actions shell
- `ReportSimpleMDM/AdminCenterView.swift`
  - admin launcher, value-tier grouping, and endpoint workflow entry points
- `ReportSimpleMDM/Settings/MainSettingsView.swift`
  - operator settings index, sync/freshness visibility, and navigation to configuration subsections
- `ReportSimpleMDM/Settings/ServerSettingsView.swift`
  - direct SimpleMDM and optional MunkiReport connection setup

### Resource-Specific Management Screens

- `ReportSimpleMDM/AppListView.swift`
  - app catalog management
- `ReportSimpleMDM/ProfileManagementView.swift`
  - live profiles and custom configuration profiles
- `ReportSimpleMDM/AssignmentGroupManagementView.swift`
  - assignment-group CRUD and membership workflows
- `ReportSimpleMDM/CustomDeclarationsView.swift`
  - custom declaration management
- `ReportSimpleMDM/LowerTierManagementViews.swift`
  - enrollments, DEP servers, push certificates, managed app configs, scripts, and jobs
- `ReportSimpleMDM/APIExplorerView.swift`
  - generic API catalog and runnable endpoint UI

### Styling And Supporting Models

- `ReportSimpleMDM/Models.swift`
  - decoded API and module payload models plus view-supporting data structures
- `ReportSimpleMDM/Styles/*`
  - shared visual styling primitives
- `ReportSimpleMDM/AppNavigationState.swift`
  - cross-screen navigation state for dashboard-to-device-list drill-ins

### Tests

- `ReportSimpleMDMTests/SettingsTests.swift`
  - settings revision behavior
- `ReportSimpleMDMTests/PersistenceModelsTests.swift`
  - cache-key and snapshot persistence behavior
- `ReportSimpleMDMTests/SyncSessionTrackerTests.swift`
  - sync-request categorization and summary behavior

## Changelog And Release History

The repo does not currently maintain a formal versioned changelog with tagged releases in this README. To avoid inventing history, this section summarizes the currently documented product-era milestones visible in the codebase.

### Current Documented Milestone Areas

- transition from a simple direct dashboard into a broader native admin client
- introduction of cache-first startup and launch-snapshot reuse
- expansion of device detail into deeper inventory and action flows
- native CRUD and management screens for apps, profiles, declarations, assignment groups, and lower-tier admin resources
- permission-aware write handling
- optional MunkiReport enrichment layering for dashboard and device-connected-resource context
- sync history, freshness reporting, TTL overrides, and richer operator diagnostics

### Recommended Future Changelog Practice

If you want this section to become a true release history later, the repo should start recording:

- version or build number
- release date
- user-facing feature additions
- breaking behavior changes
- bug fixes
- migration or configuration notes

## Validation Checklist

If you want to confirm that `ReportSimpleMDM` is behaving correctly, these are the highest-value checks.

### Direct SimpleMDM Validation

1. Save a valid SimpleMDM API key.
2. Confirm the dashboard loads total/enrolled/unenrolled data.
3. Open the device list and verify fleet records appear.
4. Open a device detail screen and verify overview/inventory content loads.
5. Open one direct admin surface such as apps, profiles, or assignment groups and confirm data loads.

### Snapshot And Cache Validation

1. Launch the app and allow a full load to complete.
2. Quit and relaunch the app.
3. Confirm cached content appears quickly on relaunch.
4. Confirm a refresh banner or later live updates appear as the app revalidates data.
5. Review `Settings` for sync history and freshness state.

### Hybrid MunkiReport Validation

1. Configure `SimpleMDM + MunkiReport Module`.
2. Save the MunkiReport base URL and auth settings.
3. Confirm direct SimpleMDM data still works first.
4. Confirm `Supplemental Enrichment (A)` begins showing detected-source data.
5. Confirm module-backed dashboard widgets start populating.
6. Open a device detail screen and look for module-backed connected-resource context where available.

### Permission Validation

1. Use an API key with limited write permissions.
2. Attempt a protected write action.
3. Confirm the app surfaces the failure cleanly.
4. Confirm the app remains usable for read flows afterward.
5. Confirm disabled actions describe the missing permission domain when that evidence has been learned.

## Contributor Notes

These notes are still about `ReportSimpleMDM`, but from a repo-maintainer perspective.

### Current Test Coverage In Repo

Automated test files currently cover:

- settings revision behavior
- persistence model behavior
- sync-session tracking behavior

### Validation Limits Seen In This Environment

In this workspace session:

- the `ReportSimpleMDM` scheme was not configured for the `test` action
- a no-signing build attempt also hit environment-related Xcode/CoreSimulator and disk-I/O problems in the sandbox

That means README accuracy was validated primarily by:

- code inspection
- route and state-path review
- repository diff review

Rather than by a clean end-to-end build or test pass in this environment.

## Important Operational Details

### Refresh Behavior

Manual refresh does not always mean "throw away everything and blank the UI first."

Current behavior is more operator-friendly:

- existing cached/live content can remain visible
- a refresh banner communicates progress
- background pagination can continue after the first results are already visible
- action failures and detail failures are separated so a mutation problem does not collapse the whole screen

### Configuration Fingerprints

Cache reuse is tied to connection fingerprints that include values such as:

- backend mode
- API key
- MunkiReport URL
- module path prefix
- current device query for query-scoped caches

This prevents the app from accidentally reusing cached data from the wrong tenant or mode.

### TTL Defaults

The default TTLs described elsewhere in this README are operationally important because they control whether data is:

- reused quietly
- shown immediately and refreshed in the background
- considered stale enough to force revalidation

### Background Refresh

On iOS physical devices, the app also schedules background refresh work. That is intended to keep data warmer between launches, but the app still relies on the same cache/snapshot logic when opened interactively.

## Security And Storage

Current security-relevant behavior includes:

- SimpleMDM API keys stored in the keychain
- optional MunkiReport auth secrets stored in the keychain
- non-secret connection metadata stored in user defaults
- cached app data stored via SwiftData
- the ability to clear saved credentials without wiping every other app setting

## Current Boundaries And Caveats

The app is already broad, but a few boundaries matter:

- SimpleMDM remains the operational source of truth; MunkiReport data is enrichment only
- some long-tail API operations are exposed through endpoint presets or the API explorer instead of deeply custom forms
- some settings screens are informational, not full administrative control planes
- device live-detail fetches are limited for non-enrolled records because the upstream API has different behavior there
- write capability depends on the API key actually granted by the SimpleMDM tenant

## Tests In The Repository

The current test target includes coverage for:

- settings revision behavior
- persistence model cache keys and snapshot round-tripping
- sync-session tracking and request categorization

Test files currently present:

- `ReportSimpleMDMTests/SettingsTests.swift`
- `ReportSimpleMDMTests/PersistenceModelsTests.swift`
- `ReportSimpleMDMTests/SyncSessionTrackerTests.swift`

## Build Notes

Local development currently expects:

- Xcode
- a valid target/simulator selection
- signing setup when building normally for devices

For source-validity checks, the project can also be built without signing:

```bash
xcodebuild -project ReportSimpleMDM.xcodeproj -scheme ReportSimpleMDM -derivedDataPath BuildDerivedData CODE_SIGNING_ALLOWED=NO build
```

## Bottom Line

If the question is "what is possible in this app right now?", the answer is:

- it already works as a standalone SimpleMDM operations client
- it already supports real fleet browsing and a large set of native management workflows
- it already exposes much of the remaining API surface through a catalog and runnable endpoint presets
- it already has a local persistence, sync, and diagnostics model designed for ongoing operational use

The repo is well beyond a proof of concept. It is a real admin-facing SimpleMDM client with optional MunkiReport enrichment, strong device-centric workflows, and broad administrative coverage.

## Connect With Me

- [GitHub](https://github.com/hov172)
- [PowerShell Gallery](https://www.powershellgallery.com/profiles/hov172)
- Slack: `@Hov172`
- Discord: `Jay172_`
- [LinkedIn](https://www.linkedin.com/in/jesus-a-785bb616?trk=people-guest_people_search-card)
- [Twitter / X](https://twitter.com/AyalaSolutions)
- [Bluesky](https://bsky.app/profile/ayalasolutions.bsky.social)
