# Cloud assistant privacy notes

Applies to all optional cloud assistant engines (Claude, OpenRouter, GitHub Copilot Models, and OpenAI / Codex) and to the optional Fleet Digest AI narrative when a cloud engine is selected.

## What leaves the device

Only when the user explicitly selects a cloud assistant engine and either sends a chat message or taps **Explain** on a saved Fleet Digest:

### In Assistant chat
- The user's question.
- The fleet brief: device counts by platform and OS major, stale, unsupervised, and no-FileVault totals, audit finding counts, the top three recommended fixes, push certificate expiry, and assignment group names with device counts.
- Tool results the model requests during that turn. These can include serial numbers, device names, OS versions, last-seen times, installed app names, profile names, audit findings, rollout status, and device action receipts.
- Profile, declaration, script, and managed app configuration content is sent with passwords, tokens, keys, and certificate data replaced by `[redacted]`. The filter matches secret-looking key names and well-known token shapes (private key blocks, JWTs, Bearer credentials, common provider token prefixes), so a secret with neither can still be included. Script output, log messages, and webhook URLs are redacted as free text.
- The compacted summary of earlier turns in the same conversation.

### In Fleet Digest AI narrative
- Only the persisted event list of the digest the user tapped **Explain** on (including device names and serial numbers where present on those events). Narratives are off by default and never run in the background.

Nothing is sent in the background. The on-device engines (**Apple Intelligence** and the **Bundled model** via llama.cpp / Qwen3) send nothing off-device. **Ollama** talks only to the user's configured Ollama server URL (localhost or local LAN).

## Where it goes

Requests go directly to the user-selected provider under the user's own API key or token, subject to that provider's usage policy and data retention:

| Engine | Endpoint | Credential storage |
|--------|----------|--------------------|
| Claude (Anthropic) | `https://api.anthropic.com/v1/messages` | Keychain (`com.reportsimplemdm.assistant.cloud-api-key`), sent in `x-api-key` |
| OpenRouter | `https://openrouter.ai/api/v1` | Keychain (per-engine service), sent as Bearer token |
| GitHub Copilot Models | `https://models.github.ai/inference` and `/catalog/models` | Keychain (per-engine service), sent as Bearer token |
| OpenAI / Codex | `https://api.openai.com/v1` | Keychain (per-engine service), sent as Bearer token |
| Ollama (self-hosted) | User-configured URL (default `http://localhost:11434`) | No key required; URL stored in UserDefaults |

The app's developer never receives, proxies, or logs any assistant prompts, keys, or responses.

## Privacy manifest and App Store answers

- `PrivacyInfo.xcprivacy` declares no tracking and no developer-collected data types: there are no analytics or tracking SDKs and the developer collects nothing.
- App Store "Data Not Collected" remains accurate because all traffic is user-initiated to the user's own configured endpoints using their own credentials.
- The App Store description and `PRIVACY.md` carry this disclosure:

> Optional cloud AI assistant engines (Anthropic Claude, OpenRouter, GitHub Copilot Models, OpenAI) send your questions, a summary of your fleet, and any device details the assistant looks up—or the event list of a digest you ask it to explain—to the provider you choose using an API key or token you supply. This happens only when you send a message or tap Explain with a cloud engine selected, never in the background. On-device engines (Apple Intelligence and the bundled model) send nothing off-device, and Ollama communicates only with the server you configure. The developer of ReportSimpleMDM does not receive this data.

## In-app disclosure

- One-time sheet before a cloud engine is first used in chat or Fleet Digest (`CloudPrivacySheet`), accepted state persisted in `settings.assistant.cloud-privacy-accepted`.
- Every cloud chat answer is labelled `"Sent to <Provider>"` (Anthropic, OpenRouter, GitHub, or OpenAI) with input, output, and cached token counts for that turn.
- Saved Fleet Digest narratives record the engine name used to generate them.
