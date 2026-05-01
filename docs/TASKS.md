# Tasks

## Current Status
- Repository started from an empty directory.
- Initial docs, SwiftUI app skeleton, SwiftData archive, and backend AI foundation are in place.
- `swiftc -parse` passes for current Swift sources.
- `xcodebuild` cannot run in this environment because `xcode-select` points to `/Library/Developer/CommandLineTools`, not Xcode.app.
- MVP premise: text-only Koremite, no audio handling.
- Cloudflare Workers staging is deployed at `https://koremite-api-staging.koremite.workers.dev`.

## Done
- Reference HTML design analyzed for colors, cards, chips, segments, spacing, and iOS-like tone.
- Product, architecture, API, prompt, cost, security, privacy, App Store, and decision docs drafted.
- `Koremite.xcodeproj` added.
- DesignSystem added with warm background, card, moss accent, chips, and primary button.
- Input screen mock added with paste area, character count, long-text hint, speakers, category, focus points, and server-processing notice.
- Loading and result screens added with 共有版 / 議事録 / 全量ログ tabs.
- Archive screen mock added with search and delete.
- `AIClient`, `MockAIClient`, and `RemoteAIClient` added.
- SwiftData archive added through `ArchivedMinutesRecord`.
- XCTest target and initial tests added.
- Cloudflare Workers backend now has `/v1/minutes`, Gemini API calls, fixed schema validation, timeout, bounded retries, cache, rate limit, and long-text chunking foundation.
- Backend tests pass: 7 tests.
- Backend typecheck passes with `npm run typecheck`.
- Gemini API staging check passed with HTTP 200.
- Repeating the same `sourceHash` returned `costInfo.cacheHit: true`.
- Vercel test page and `/api/minutes-test` proxy added. Vercel only needs `KOREMITE_API_BASE_URL`; Gemini keys stay in Cloudflare.

## Next
- Open in Xcode and run an iOS Simulator build.
- Run iOS XCTest after switching `xcode-select` to Xcode.app.
- Add SwiftData integration tests once Xcode test execution is available.
- Exercise real AI provider in staging Worker with a test secret.
- Wire iOS `RemoteAIClient` to the staging URL behind a build/config switch.
- Confirm Vercel Preview deployment can call Cloudflare staging from the browser test page.
- Replace in-memory Worker cache/rate-limit fallback with KV/Durable Object if production traffic requires cross-isolate consistency.

## Backlog
- Broader XCTest coverage.
- Server-side durable cache/rate limit implementation.
- Share Extension after MVP.

## Local Verification Notes
`xcodebuild -list -project Koremite.xcodeproj` currently fails with:

```text
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
```

Later verification:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -list -project Koremite.xcodeproj
xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'
```
