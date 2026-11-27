# Privacy Policy

**ReportSimpleMDM** (iOS, iPadOS, macOS, visionOS)
Last updated: 2026-11-24

## Summary

ReportSimpleMDM does not collect, store, or transmit any personal data to the developer or to any third party for analytics, advertising, or tracking. There are no developer accounts, no telemetry, and no ad or tracking SDKs.

## What the app stores on your device

- **Credentials and API keys** — SimpleMDM API keys, optional MunkiReport credentials, and optional cloud AI provider API keys/tokens (Anthropic, OpenRouter, GitHub Models, OpenAI). These are stored exclusively in the system data-protection keychain (`kSecUseDataProtectionKeychain`) on your device. Deleting a saved account removes its keychain items. They are never written to preferences, logs, or files on disk, and are sent only to the services you configure.
- **Cached fleet data** — devices, groups, profiles, apps, declarations, scripts, and logs downloaded from your own SimpleMDM tenant, kept in a local SwiftData database so the app opens quickly and supports offline audits and assistant queries. Device secrets fetched with `show_secrets` are held in memory only and never cached.
- **Operational files under Application Support** — account-scoped saved reports and templates (HTML, PDF, Markdown, CSV, DOCX, XLSX), Fleet Digest configurations/baselines/history, OS Update Rollout cohorts, and Device Action History command receipts.
- **Assistant chat history and write audit trail** — the text of your assistant conversations and a record of every assistant action you approved or cancelled (tool, summary, request paths, time, outcome; never the request contents), kept per account under Application Support and removed with the account.
- **Preferences** — backend mode, dashboard layout, cache lifetimes, assistant engine selection, and Ollama server URL (if configured).

Settings > Server & API > **Reset App** erases all of the above (saved keys and accounts, SwiftData cache, saved reports, digests, rollouts, action receipts, and preferences).

## Where the app sends data

The app communicates only with:

- **`a.simplemdm.com`** — the SimpleMDM API, using your API key over HTTPS.
- **Your own MunkiReport host** — only if you configure hybrid module enrichment, over HTTPS. The app refuses to send these requests over plain HTTP, except to the device itself (`localhost`).
- **`sofafeed.macadmins.io`** — public macOS and iOS release feeds fetched over HTTPS to evaluate OS currency and end-of-life status in Fleet Audit, Reports, and Fleet Digest. No fleet or device data is sent in these requests.
- **`itunes.apple.com`** — App Store version lookup containing only the app's bundle identifier, only when you explicitly invoke the assistant's `check_for_update` tool.
- **Your own Ollama server** — only if you choose the optional Ollama assistant engine and configure a local or LAN server URL (default `http://localhost:11434`). Requests go directly to that server and nowhere else.
- **Optional cloud AI providers** — only if you choose one of the cloud assistant engines and supply your own API key or token:
  - **`api.anthropic.com`** — Claude (Anthropic)
  - **`openrouter.ai`** — OpenRouter (which forwards requests to the model provider you choose)
  - **`models.github.ai`** — GitHub Copilot Models (using your GitHub personal access token)
  - **`api.openai.com`** — OpenAI / Codex

When a cloud AI engine is selected, each chat message you send carries your question, a summary of your fleet (device counts, OS versions, audit totals, group names), and any tool results the assistant looks up for that answer (which can include serial numbers and device names). Before the content of a profile, declaration, or script, or a managed app configuration, is sent to a cloud engine, the app replaces passwords, tokens, keys, and certificate data in it with `[redacted]`; this is a name-based filter, so a secret stored under an unrelated key name can still be sent. If you enable the optional Fleet Digest AI narrative and tap **Explain** on a digest while a cloud engine is selected, that digest's persisted event list is sent to the selected provider. This happens only on explicit user action, never in the background, after a one-time disclosure sheet (`CloudPrivacySheet`), and is governed by the provider's own usage policy. The on-device engines (Apple Intelligence and the bundled llama.cpp / Qwen3 model) send nothing off-device.

Nothing is sent to the developer. The app contains no analytics, advertising, or tracking SDKs.

## Sample data mode

"Try with sample data" runs the app against fixtures bundled inside the app. In this mode no SimpleMDM network requests leave the device and write actions are rejected locally.

## Apple privacy manifest

The app ships a `PrivacyInfo.xcprivacy` declaring no tracking, no collected data types, and a single required-reason API use (UserDefaults, reason CA92.1, for the app's own preferences).

## Children

The app is a device-management tool for IT administrators and is not directed at children.

## Changes

Changes to this policy are published in this file with an updated date.

## Contact

Open an issue at https://github.com/hov172/Report-SimpleMDM/issues.
