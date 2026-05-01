# Koremite

Koremite is an iPhone app for turning pasted transcription text into minutes that are easy to share and easy to revisit.

The MVP workflow is simple: copy text transcribed by Voice Memos or another app, paste it into Koremite, choose the meeting purpose and focus points, generate minutes, then copy/share/save the result.

## What It Does
- Accepts pasted transcription text.
- Generates a short shareable summary for LINE/messages.
- Generates detailed meeting minutes.
- Keeps a full text log for later fact checking.
- Saves generated minutes locally.
- Searches and deletes saved archives.

## What It Does Not Do
- No recording.
- No audio file import.
- No microphone permission.
- No Speech Recognition permission.
- No audio upload.
- No login, billing, iCloud sync, or Share Extension in MVP.

## MVP Scope
SwiftUI input, result, and archive screens; `MockAIClient`; backend-facing `RemoteAIClient`; local archive; copy/share; errors and retry; privacy/security docs; cost-aware AI processing design.

## Technology
- iOS 17+, SwiftUI, Swift Concurrency, SwiftData
- MVVM/light Clean Architecture
- Backend: Cloudflare Workers + TypeScript
- AI route: iOS -> Koremite backend -> AI API
- Archive: SwiftData on device

## Run iOS
Open `Koremite.xcodeproj` in Xcode and run the `Koremite` scheme on an iOS 17+ simulator.

CLI build:

```sh
xcodebuild -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Run Backend
```sh
cd Backend
npm install
npm run dev
```

## Environment
Copy `Backend/.env.example` to your local environment provider. Never commit real secrets.

Required backend variables:
- `AI_API_KEY`
- `AI_BASE_URL`
- `AI_MODEL_FAST`
- `AI_MODEL_QUALITY`
- `MAX_INPUT_CHARS`
- `AI_TIMEOUT_MS`
- `AI_MAX_RETRIES`
- `CHUNK_CHAR_LIMIT`
- `CACHE_TTL_SECONDS`
- `RATE_LIMIT_MAX_REQUESTS`
- `RATE_LIMIT_WINDOW_SECONDS`

## Tests
- iOS: `xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'`.
- Backend: `cd Backend && npm test`.
- Backend typecheck: `cd Backend && npm run typecheck`.

Current local limitation: `xcodebuild` cannot run while `xcode-select -p` points to `/Library/Developer/CommandLineTools`. Later verification:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -list -project Koremite.xcodeproj
xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Directory
- `Koremite/`: iOS app
- `Backend/`: API worker
- `docs/`: product and engineering docs

## Development Notes
Do not place AI API keys in iOS code. Do not log pasted text. Keep the MVP text-only. Cost minimization is part of the product: reuse cached results, bound inputs/retries, and use staged processing for long text.

## App Store Notes
Before submission, complete `docs/APP_STORE_CHECKLIST.md`, publish a privacy policy, confirm Privacy Nutrition Labels, and verify no microphone or Speech Recognition usage descriptions are present unless future scope explicitly adds them.
