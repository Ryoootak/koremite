# Product Spec

## Name
Koremite

## One-Line Value
Paste transcription text and turn it into a short shareable message and detailed minutes.

## MVP Premise
Koremite does not handle real audio. Users copy transcription text from iPhone Voice Memos or another app and paste it into Koremite. The app sends that text to the Koremite backend for AI processing.

## Core Users
- People sharing housing consultation notes with family.
- People turning sales calls, consultations, or meetings into concise records.
- People reducing "said / did not say" confusion by keeping searchable local records.

## Primary Flow
1. Copy transcription text in another app.
2. Open Koremite.
3. Paste text.
4. Select speakers, category, and focus points.
5. Generate minutes.
6. Review share summary and detailed minutes.
7. Copy, share with iOS share sheet, or save to archive.

## MVP Includes
- Pasted text input
- Character count, input limit, long text warning
- Speaker candidates
- Category: 住宅, 仕事, 家庭, その他
- Focus points: 決定事項, やること, 金額, スケジュール, 懸念点, 感情
- AI generation through backend
- Loading, error, retry
- Result tabs: 共有版, 議事録
- Copy minutes, copy/share summary, save
- Local archive, search, delete
- Privacy and App Store preparation docs

## MVP Excludes
Recording, audio import, microphone permission, Speech Recognition, audio upload, direct Voice Memos audio import, speaker diarization, login, billing, iCloud sync, Share Extension.

## Design Reference Notes
The reference HTML uses a warm off-white/beige background, white cards, moss-green accent, pill chips, segmented controls, rounded iOS-like surfaces, generous spacing, and calm Japanese copy. Koremite keeps that mood but replaces audio-looking UI with pasted-text-first screens.
