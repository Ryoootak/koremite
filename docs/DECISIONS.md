# Decisions

## 2026-05-01: Native SwiftUI, Not WebView
Koremite will be implemented as a native SwiftUI app. The provided HTML is a visual reference only. This keeps the app App Store-friendly, accessible, and aligned with iOS conventions.

## 2026-05-01: Text-Only MVP
MVP handles pasted transcription text only. Audio recording, microphone permission, Speech Recognition, audio file import, audio upload, and speaker diarization are explicitly out of scope.

## 2026-05-01: iOS 17+ And SwiftData
iOS 17+ is acceptable, so SwiftData is the first-choice local archive store. This reduces persistence boilerplate for the MVP.

## 2026-05-01: Backend Is Required
iOS will never call AI providers directly. The app calls the Koremite backend, which owns provider credentials, model selection, rate limits, input limits, timeouts, and retries.

## 2026-05-01: Cloudflare Workers For MVP Backend
Cloudflare Workers is selected over Supabase Edge Functions and Vercel Functions for the MVP because it is simple for a small stateless API, low-cost at small scale, easy to deploy, and supports environment secrets. Supabase remains a future option if auth/database features become central. Vercel remains a future option if a Next.js web surface becomes central.

## 2026-05-01: Cost-Aware Processing Modes
Koremite will expose `short`, `normal`, and `long_chunked` processing modes. The UI describes long-text handling gently, while backend implementation keeps model and token limits configurable.

## 2026-05-01: Reference HTML Design Adaptation
Keep the warm off-white background, white cards, moss-green accent, pill chips, segmented controls, calm spacing, and iOS-like restraint. Remove or avoid audio-centric UI such as waveform, record button, and audio import affordances.

## 2026-05-01: SwiftData Archive Wrapper
The archive moved from in-memory state to SwiftData via `ArchivedMinutesRecord`, while keeping `ArchiveStore` as a small UI-facing wrapper. This limits View churn and keeps the persistence boundary easy to test.

## 2026-05-01: Gemini Backend Adapter
The Worker calls the Gemini API `generateContent` endpoint configured by `GEMINI_BASE_URL`. The AI key is stored as the Cloudflare secret `GEMINI_API_KEY`, and iOS still only talks to the Koremite backend.
