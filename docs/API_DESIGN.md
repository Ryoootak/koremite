# API Design

## Endpoint
`POST /v1/minutes`

## Request
```json
{
  "transcript": "string",
  "category": "住宅 | 仕事 | 家庭 | その他",
  "speakers": ["string"],
  "focusPoints": ["決定事項", "やること", "金額", "スケジュール", "懸念点", "感情"],
  "clientRequestId": "string",
  "sourceHash": "string"
}
```

## Response
```json
{
  "title": "string",
  "shareSummary": {
    "text": "string",
    "decisions": ["string"],
    "todos": [{"owner": "string | null", "task": "string", "due": "string | null"}],
    "confirmationPoints": ["string"]
  },
  "detailedMinutes": {
    "overview": "string",
    "topics": ["string"],
    "decisions": ["string"],
    "openIssues": ["string"],
    "todos": [{"owner": "string | null", "task": "string", "due": "string | null"}],
    "importantRemarks": ["string"],
    "nextMeetingNotes": ["string"]
  },
  "fullLog": [{"speaker": "string", "text": "string"}],
  "category": "住宅 | 仕事 | 家庭 | その他",
  "confidenceWarnings": ["string"],
  "costInfo": {"inputLength": 0, "processingMode": "short | normal | long_chunked", "cacheHit": false}
}
```

## Errors
Return safe Japanese messages to the app. Do not include the transcript in errors.

- `400`: input missing or too long
- `429`: rate limited
- `502`: AI provider failed
- `504`: timeout

## Backend Responsibilities
- Validate input size.
- Rate limit by IP for MVP, with a future device-token strategy if needed.
- Select processing mode by length.
- Use fixed JSON schema.
- Bound retries and timeout.
- Keep AI API key in environment variables only.
- Cache successful results by `sourceHash` for `CACHE_TTL_SECONDS`.
- For `long_chunked`, compress chunks with the fast model before final synthesis.
