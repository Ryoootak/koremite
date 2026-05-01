# App Store Checklist

## Scope
- Confirm no microphone permission usage string.
- Confirm no Speech Recognition usage string.
- Confirm no audio import wording in UI.
- Confirm all visible app naming says "Koremite".

## Privacy
- Publish privacy policy.
- Confirm Privacy Nutrition Labels match actual behavior.
- Verify user notice before generation says text is sent to server for AI processing.
- Confirm delete flow for local archives.

## Security
- Verify no AI API key in iOS bundle.
- Verify no transcript body logging.
- Verify backend secrets are environment variables.

## UX
- Test paste flow.
- Test long text warning.
- Test generation loading, error, retry.
- Test copy, share sheet, save, search, delete.

## Backend
- Input size limit.
- Rate limit policy.
- Timeout.
- Bounded retries.
- Safe error messages.
