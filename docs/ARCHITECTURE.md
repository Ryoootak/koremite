# Architecture

## Overview
Koremite uses a native SwiftUI iOS app and a small backend API. The iOS app never calls AI providers directly.

```text
iOS SwiftUI app -> Koremite backend -> AI provider
                 -> local SwiftData archive
```

## iOS Layers
- Views: SwiftUI screens and reusable components.
- ViewModels: state, validation, loading, retry, save/copy/share orchestration.
- Models: fixed request/response schema.
- Services: `AIClient`, `MockAIClient`, `RemoteAIClient`, archive storage.
- DesignSystem: colors, spacing, typography, cards, chips, buttons.

## Data Flow
1. User pastes transcription text.
2. ViewModel validates length and displays processing mode.
3. `AIClient.generateMinutes` is called.
4. Mock client returns deterministic local data in development.
5. Remote client posts to backend `/v1/minutes`.
6. Result is decoded as JSON; malformed data falls back to a user-facing Japanese error.
7. User copies/shares/saves.

## Storage
SwiftData stores generated minutes on device through `ArchivedMinutesRecord`. The app stores generated output, category, created date, source hash, and search metadata. It does not store backend secrets.

## Backend Choice
Cloudflare Workers is selected for MVP because it is low-cost for small APIs, easy to deploy, supports environment variables, has good edge latency, and avoids maintaining a server. See `docs/DECISIONS.md`.

## Security Boundary
The iOS app only knows the Koremite backend endpoint. The backend owns AI provider credentials, input limits, rate limit policy, retry bounds, timeouts, cache TTL, chunking, schema validation, and model selection.
