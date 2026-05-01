# CLAUDE.md

## Working Style
1. Explore first: inspect related files before changing code.
2. Plan next: for large changes, write a short plan and keep it current.
3. Implement last: prefer real files, tests, and verification over long explanations.

## Verification
- iOS: build with Xcode or `xcodebuild -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- iOS tests: `xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'`.
- Backend: `cd Backend && npm install && npm run dev`; tests with `npm test`; typecheck with `npm run typecheck`.
- After implementation, self-review for build errors, privacy leaks, API-key exposure, cost regressions, and accidental audio scope.

## Hard Rules
- Koremite MVP handles pasted transcription text only.
- Do not add recording, microphone permission, Speech Recognition permission, audio upload, or audio file import.
- iOS never calls an AI provider directly.
- AI API keys live only in backend environment variables.
- Never log pasted transcription text, generated text, full API payloads, or user personal data.
- Do not include conversation text in crash, analytics, or error messages.
- External sharing must require explicit user action.

## Cost Rules
- Include cost minimization in design decisions.
- Use input length, chunking, local cache, fixed JSON schemas, bounded retries, timeouts, and model-switchable backend configuration.
- Keep SwiftData archive behavior covered by XCTest as it grows.
- Update `docs/COST_STRATEGY.md` if the processing pipeline changes.

## Context Management
If context grows, summarize current progress in `docs/TASKS.md` and record decisions in `docs/DECISIONS.md`. Future agents should continue from those files.

## Reporting
After work, report changed files, commands run, verification result, remaining issues, and the next recommended task.
