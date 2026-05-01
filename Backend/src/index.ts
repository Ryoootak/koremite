import { generateMinutesWithAI, Env } from "./ai";
import { readCached, writeCached } from "./cache";
import { checkRateLimit } from "./rateLimit";
import { normalizeMinutesResponse, validateGenerateRequest } from "./schema";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/v1/minutes") {
      return json({ message: "Not found" }, 404);
    }

    const rateKey = request.headers.get("CF-Connecting-IP") ?? request.headers.get("X-Forwarded-For") ?? "local";
    const rateLimit = checkRateLimit(
      rateKey,
      Number(env.RATE_LIMIT_MAX_REQUESTS ?? "20"),
      Number(env.RATE_LIMIT_WINDOW_SECONDS ?? "3600")
    );
    if (!rateLimit.allowed) {
      return json(
        { message: "短時間の生成回数が上限に達しました。少し時間をおいてお試しください。" },
        429,
        { "Retry-After": String(rateLimit.retryAfterSeconds) }
      );
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return json({ message: "リクエストを読み取れませんでした。" }, 400);
    }

    const maxInputChars = Number(env.MAX_INPUT_CHARS ?? "30000");
    const validated = validateGenerateRequest(body, maxInputChars);
    if (!validated.ok) {
      return json({ message: validated.message }, 400);
    }

    const cacheTtlSeconds = Number(env.CACHE_TTL_SECONDS ?? "86400");
    const cached = await readCached(validated.request.sourceHash, cacheTtlSeconds);
    if (cached) {
      return json(cached);
    }

    try {
      const result = await generateMinutesWithAI(validated.request, env);
      const normalized = normalizeMinutesResponse(
        result,
        validated.request.transcript.length,
        result.costInfo.processingMode,
        false
      );
      await writeCached(validated.request.sourceHash, normalized, cacheTtlSeconds);
      return json(normalized);
    } catch {
      return json({ message: "議事録を生成できませんでした。時間をおいてもう一度お試しください。" }, 502);
    }
  }
};

function json(value: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      ...CORS_HEADERS,
      ...headers,
      "Content-Type": "application/json; charset=utf-8"
    }
  });
}
