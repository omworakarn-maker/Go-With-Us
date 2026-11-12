# Gemini primary / Groq fallback

The existing authenticated POST /api/ai/chat endpoint remains unchanged.
Only the backend needs deployment. No database migration or native build is
required for this change.

Set GEMINI_API_KEY (existing), GROQ_API_KEY, and optionally GROQ_MODEL
(default: openai/gpt-oss-20b) on the backend host. Keep keys out of clients.

- Gemini remains primary.
- Gemini HTTP 429, HTTP 5xx, network errors and timeouts can fall back to Groq.
- Gemini HTTP 400/401/403 errors do not trigger fallback.
- Gemini rate limits/server outages enter a 60-second cooldown. During it,
  eligible requests go directly to Groq.
- Groq has its own cooldown; it cannot disable a healthy Gemini provider.
- When a Groq key is configured, Gemini gets 12 seconds and Groq gets 15 seconds
  so the two provider waits fit within the existing web client's 30-second
  deadline (network transit can still affect total elapsed time).
- Without a Groq key, the existing 90-second Gemini timeout is preserved.
- Both attempts share the same concurrency and per-user request slot.
- Text history is mapped from user/model roles to user/assistant.
- JSON requests use Groq JSON mode and reject invalid JSON or truncated output.
- Responses are wrapped in the Gemini candidates/content/parts format expected
  by both web and iOS.
- If both providers fail, only the AI request returns a recoverable 503.

Tests: node backend-api/tests/aiTimeout.test.cjs and
node backend-api/tests/aiFallback.test.cjs.
These use simulated providers and do not consume API credits. Real Thai trip
quality and the configured account/model still require a deployment smoke test.

Groq fallback applies to chat and generation through this endpoint, not Gemini
embeddings. Embeddings already have an independent optional-failure path.
