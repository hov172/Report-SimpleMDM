# Report-SimpleMDM

ReportSimpleMDM is a native SwiftUI client for SimpleMDM, available on macOS, iOS, and Android. It is designed to give administrators a fast, operator-focused view of fleet state while exposing a broad range of the SimpleMDM API surface through native workflows, an API catalog, and runnable endpoint presets.

The app is purpose-built as a standalone SimpleMDM operations client. Optional MunkiReport enrichment is supported as an additive capability rather than a core dependency.

If you would like to be added to the iOS or Android early access mailing list, please reach out directly.

Some features are still under active development. Feedback on any issues or bugs is always welcome and appreciated.

[1.6.1] — Build 6 — 2026-06-06
Custom Configuration Profile API parity

Full create/update parameter parity — the custom configuration profile editor now sends every parameter the SimpleMDM API supports, closing the gap left in 1.6.0. New fields: auto_renew_scep_based_certificates, allowed_platforms[] (macOS / iOS / iPadOS / tvOS), minimum_macos_version, maximum_macos_version, and allowed_macos_architecture (any / Intel x86 / Apple Silicon arm). Existing fields (user_scope, attribute_support, escape_attributes, reinstall_after_os_update, declarative) are unchanged. Applies to both POST /custom_configuration_profiles and PATCH /custom_configuration_profiles/{id}.
New "Platform Restrictions" editor card — per-platform toggles, minimum/maximum macOS version fields, and an architecture picker. Edit mode pre-fills all values from the existing profile.
Validation matching the API contract — auto-renew SCEP is rejected (and auto-disabled in the UI) when Declarative is enabled, macOS versions must be dotted-numeric, and the maximum version must be ≥ the minimum (compared numerically, so 14.10 > 14.4).
Tests

Added CustomConfigurationProfileInputTests (14 cases) covering wire-order stability, each new field's encoding, the array/version encoding, and every validation rule.
Notes

allowed_platforms is omitted from the request when no platform is selected, which the API treats as "all platforms." On an update, an omitted value may be read as "leave unchanged" rather than "reset to all," so widening a previously platform-restricted profile back to all platforms by unchecking everything is not guaranteed via PATCH.
[1.6.0] — Build 5 — 2026-06-05
New device actions (SimpleMDM API parity through v1.55)

Send Message — new per-device action with a message sheet, plus a bulk variant that sends one message to all selected devices. Gated to supervised iOS-family devices. POST /devices/{id}/send_message.
Disable Activation Lock — new per-device action (confirmation dialog) and bulk variant. Gated to enrolled, supervised devices that currently have Activation Lock enabled (the MDM command requires an escrowed bypass code). POST /devices/{id}/disable_activation_lock.
Activation Lock status — device detail now shows an "Activation Lock" row (Enabled / Disabled / Unknown) read from the device's is_activation_lock_enabled attribute.
Refresh Cellular Plans — new per-device action with a sheet that collects the carrier's required eSIM server URL (https-validated). Gated to enrolled, cellular-capable iOS devices. POST /devices/{id}/refresh_cellular_plans with esim_server_url.
Wipe → Preserve Managed Apps — the wipe sheet gained a "Preserve Managed Apps" toggle (preserve_managed_apps), enabled only when Return to Service is on (iOS 26+ / visionOS 26+ with DEP + bootstrap token).
Supporting changes

Bulk actions carry form fields — performBulkDeviceAction now forwards optional form fields, enabling bulk Send Message.
New availability rules — supervisedIOSFamily, activationLockManageable, and cellularCapable gate the new actions, with distinct messaging for not-supervised, lock-not-enabled, unknown-status, and not-yet-loaded states.
Scrollable bulk action bar — the multi-select bulk bar is now horizontally scrollable so the added actions don't overflow on narrow widths.
Tests — added DeviceActionKindTests, DeviceActionPayloadTests, DeviceActionAvailabilityRuleTests, and expanded DeviceWipePayloadTests for preserve_managed_apps.
Performance

Fixed a ~26-second main-thread stall at launch on large fleets. DateHelper.date(from:) allocated a fresh ISO8601DateFormatter on every call, and the dashboard re-parsed and re-sorted every device by last-seen date on each render (parsing inside the sort comparator, recomputed twice per body). On a 449-device account this produced hundreds of thousands of formatter allocations and saturated the main thread for ~26s during startup revalidation. Confirmed instrumentation localised it to the SwiftUI render path (not the data/SwiftData layer). The formatters are now cached and reused, and the Recently Seen list and stale-device count parse each date once per render. Added DateHelperTests (parsing correctness + a parse-throughput guard).
Note: The exact request body field name for Send Message (message) and the empty-body contract for Disable Activation Lock are based on the SimpleMDM v1.55 release notes; verify against your tenant on a supervised test device before broad rollout (these endpoints are not yet in the public API reference).

v1.5.6 Build 4

Changelog And Release History

1.5.6 (Build 4)

SwiftData reliability

Schema migration infrastructure — Added AppSchemaV1 (VersionedSchema) and AppMigrationPlan (SchemaMigrationPlan). Future model changes now migrate cleanly without destroying cached data on app update.
Unique device cache key — PersistentDevice.cacheKey is now @Attribute(.unique), matching the uniqueness enforcement already in place on all other cache-keyed models. Duplicate rows from any upsert edge case are no longer possible.
Sync log pruning — pruneSyncLogsIfNeeded now calls modelContext.save() after deleting old entries so pruning is durable across app launches.
Concurrency correctness

Cancellation-safe request limiter — RequestLimiter.acquire() now uses withTaskCancellationHandler and a UUID-keyed waiter dictionary. Cancelled tasks cleanly remove themselves from the queue and resume with CancellationError instead of leaking a hung continuation.
Script job watcher — watchScriptJobForCompletion now propagates CancellationError from Task.sleep so the poll loop exits immediately on cancellation rather than ignoring it.
Modern CPU offloading — sortedDevices and buildDashboardSnapshot are now @concurrent nonisolated async functions. All four Task.detached { }.value sort/snapshot sites are replaced with direct await calls, expressing off-actor intent at the declaration rather than every call site.
Background decoding — decodeInBackground is now @concurrent, removing the nested Task.detached wrapper.
Removed redundant main-actor hops — Eliminated two unnecessary await MainActor.run {} calls in DeviceDetailView that were no-ops (already on the main actor inside a Task {} from a @MainActor view).
SwiftUI modernisation

@Observable navigation state — AppNavigationState migrated from ObservableObject/@Published/@StateObject/@EnvironmentObject to @Observable @MainActor. Views now receive per-property change notifications instead of full-view invalidation on any state change. AppTab and DevicePostureFilter moved to dedicated files.
foregroundStyle everywhere — Replaced all deprecated .foregroundColor() calls with .foregroundStyle() across 38 view files.
clipShape everywhere — Replaced all deprecated .cornerRadius() calls with .clipShape(.rect(cornerRadius:)) in DashboardView, DeviceListView, and GlassTextField.
scrollIndicators modernised — Replaced deprecated showsIndicators: initializer parameter with .scrollIndicators() modifier in DeviceListView and MunkiPkginfoView.
Account switcher accessibility — onTapGesture in AccountSwitcherView replaced with Button, making account rows accessible to VoiceOver and Voice Control.
Automatic task cancellation — Task {} inside DeviceListView.onAppear for device hydration replaced with .task {} modifier so the work is automatically cancelled if the view disappears before it completes.
Startup diagnostics

Accurate totalMs in deferred hydration log — The original startup timestamp is now threaded through the full deferred-hydration call chain so the "first publish" log line reflects true wall-clock time from app launch rather than always showing 0ms.
Named publish sources — Every device-list publish now carries a descriptive source label in the startup timing log (sync_page, query_page, load_more, startup_page, bg_sync_page, bg_sync_complete) instead of unspecified.
Performance — @Observable migration for SimpleMDMService

Eliminated 24-second startup revalidation delay — SimpleMDMService migrated from ObservableObject/@Published (46 properties) to the modern @Observable macro. With ObservableObject, every property change fires objectWillChange across all 30 subscriber views, causing full body re-evaluations of large views (DashboardView is 2598 lines). During startup revalidation, this kept the main actor occupied for up to 24 seconds, blocking the revalidation Task from starting. With @Observable, only views that read a specific property re-render when it changes. The startCachedLaunchRevalidation Task now starts within 1ms of being queued rather than waiting up to 24 seconds. Startup revalidation on a warm launch dropped from 24.6 seconds to 167ms.
Inline device hydration — Deferred device list hydration now runs inline before revalidation starts, guaranteeing devices are available to the list view immediately at ~160ms alongside the dashboard snapshot rather than waiting for the main actor to become free.

Thanks