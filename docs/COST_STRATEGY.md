# Cost Strategy

Cost minimization is a core Koremite product value. Users should receive useful minutes without sending every full transcript to an expensive model every time.

## Processing Modes
- `short`: small input, one fixed-schema request.
- `normal`: moderate input, one fixed-schema request with stricter output bounds.
- `long_chunked`: long input, chunk compression first, then final merge.

## Planned Thresholds
- Warn after 8,000 characters.
- Hard limit around 30,000 characters for MVP, enforced in iOS and backend.
- Backend environment controls exact values.

## Techniques
- Compute source hash on-device and backend.
- Reuse local archive results for matching source hash.
- Reuse backend cache for matching source hash during `CACHE_TTL_SECONDS`.
- Return share summary, detailed minutes, and full log in one response.
- Use fixed JSON schema to reduce parsing retries.
- Chunk long text before final generation using `CHUNK_CHAR_LIMIT`.
- Use fast/low-cost model for extraction and compression.
- Use quality model only when final synthesis requires it.
- Bound output tokens, timeout, and retry count.
- Avoid infinite retry loops.
- Keep model names configurable via backend environment variables.

## Product Copy
Cost language should be reassuring, not technical. Example: "長文のため、段階的に整理します。"

## Future
- Durable server-side cache or KV-backed cache keyed by normalized input hash.
- User-visible "already generated" reuse prompt.
- Optional paid tier only after MVP validation.
