# Security

## Hard Prohibitions
- No AI API key in iOS code, Info.plist, assets, or Git.
- No real audio, recording, microphone permission, Speech Recognition permission, audio upload, or audio file import in MVP.
- No logging pasted transcription text or generated minutes.
- No sending pasted text to analytics or crash logs.
- No automatic external sharing.

## Required Controls
- iOS calls only the Koremite backend.
- Backend calls the AI provider.
- Backend validates input size.
- Backend applies IP-based MVP rate limiting.
- Backend uses timeouts and bounded retries.
- Backend errors never include transcript text.
- Local archive has delete flow.

## Logging Policy
Allowed: request id, status code, processing mode, duration, character count range, cache hit boolean.

Forbidden: transcript body, generated summary/minutes/full log, names extracted from transcript, full prompt, AI raw response.

## Secrets
Use `.env.example` for names only. Real keys live in deployment secrets or local uncommitted environment files.
