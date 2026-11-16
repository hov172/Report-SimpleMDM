# Privacy Policy

**ReportSimpleMDM** (iOS, iPadOS, macOS, visionOS)
Last updated: 2026-11-16

## Summary

ReportSimpleMDM does not collect, store, or transmit any personal data to the developer or to any third party. There are no analytics, no advertising, no tracking, and no accounts with the developer.

## What the app stores on your device

- **SimpleMDM API key** and, optionally, MunkiReport credentials. These are stored only in the system keychain on your device. They are never written to preferences, logs, or any file, and they are never sent anywhere except to the services you configure.
- **Cached fleet data** (devices, groups, profiles, apps, logs) downloaded from your own SimpleMDM tenant, kept in a local database so the app opens quickly. Device secrets fetched with `show_secrets` are held in memory only and never cached.
- **Preferences** such as backend mode, dashboard layout, and cache lifetimes.

Settings > Server & API > **Reset App** erases all of the above.

## Where the app sends data

The app communicates only with:

- `a.simplemdm.com`, the SimpleMDM API, using your API key over HTTPS.
- Your own MunkiReport host, only if you configure one, over HTTPS.

Nothing is sent to the developer. The app contains no third-party SDKs.

## Sample data mode

"Try with sample data" runs the app against fixtures bundled inside the app. In this mode no network requests are made at all.

## Apple privacy manifest

The app ships a `PrivacyInfo.xcprivacy` declaring no tracking, no collected data types, and a single required-reason API use (UserDefaults, reason CA92.1, for the app's own preferences).

## Children

The app is a device-management tool for IT administrators and is not directed at children.

## Changes

Changes to this policy are published in this file with an updated date.

## Contact

Open an issue at https://github.com/hov172/Report-SimpleMDM/issues.
