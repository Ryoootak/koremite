# AGENTS.md

## Project
Koremite is an iOS 17+ SwiftUI app that turns pasted transcription text into a short shareable summary, detailed minutes, and a full text log. MVP handles text only. It must not record audio, import audio files, request microphone permission, request Speech Recognition permission, or upload audio.

## Goal
Ship an App Store-ready MVP for "copy transcription text -> generate minutes -> copy/share/save" with low AI API cost as a core product value.

## Stack
- iOS: SwiftUI, Swift Concurrency, SwiftData, MVVM/light Clean Architecture
- Backend: Cloudflare Workers, TypeScript
- AI access: iOS -> Koremite backend -> AI API only
- Local development AI: `MockAIClient`

## Structure
- `Koremite/`: SwiftUI app source
- `Koremite/DesignSystem/`: colors, spacing, typography, reusable styles
- `Koremite/Models/`: domain and API models
- `Koremite/Services/`: API, storage, clipboard/share helpers
- `Koremite/ViewModels/`: screen state and orchestration
- `Koremite/Views/`: SwiftUI screens/components
- `Backend/`: Cloudflare Worker API
- `docs/`: product, architecture, security, cost, tasks, decisions

## Build And Test
- Open `Koremite.xcodeproj` in Xcode and run the Koremite scheme on an iOS 17+ simulator.
- CLI build when project files exist: `xcodebuild -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15' build`
- CLI tests: `xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'`
- Backend local run after installing dependencies: `cd Backend && npm install && npm run dev`
- Backend tests: `cd Backend && npm test`
- Backend typecheck: `cd Backend && npm run typecheck`

## Coding Rules
- Explore first, then plan, then implement.
- Before editing, read related files and update the plan for non-trivial work.
- Keep Views small; move constants to `DesignSystem`, behavior to ViewModels, network work to Services.
- Prefer structured JSON parsing over string parsing.
- Use Japanese UI copy unless a system/API identifier requires English.
- Do not introduce audio features into MVP.
- Do not log pasted transcription text, generated minutes, API payloads, or personal data.
- Do not put AI API keys in iOS code, plist files, assets, or Git.

## Cost Rules
- Treat cost minimization as product behavior, not an afterthought.
- Use input length based processing modes: `short`, `normal`, `long_chunked`.
- Reuse saved local results for the same input hash when possible.
- Request all required outputs in one fixed JSON schema.
- Limit input size, output size, timeout, and retry count.
- Backend uses cache TTL, rate limiting, timeout, bounded retries, and long-text chunk compression.

## Done
- Buildable or clearly documented if blocked.
- Relevant tests or manual verification completed.
- `docs/TASKS.md` updated with current state.
- `docs/DECISIONS.md` updated for architecture/product decisions.
- Self-review completed for security, privacy, cost, and MVP scope.
- Final report includes changed files, verification commands, completed work, unfinished work, and next steps.

## Handoff
When handing off between Codex and Claude Code, read this file, `CLAUDE.md`, `docs/TASKS.md`, and `docs/DECISIONS.md` first. Summarize any in-progress work in `docs/TASKS.md` before stopping.
