import { buildFullLog, GenerateRequest, MinutesResponse, modeFor, normalizeMinutesResponse, ProcessingMode, safeFallbackResponse, validateMinutesResponse } from "./schema";

export type Env = {
  GEMINI_API_KEY?: string;
  GEMINI_BASE_URL?: string;
  AI_MODEL_FAST?: string;
  AI_MODEL_QUALITY?: string;
  MAX_INPUT_CHARS?: string;
  AI_TIMEOUT_MS?: string;
  AI_MAX_RETRIES?: string;
  CHUNK_CHAR_LIMIT?: string;
  CACHE_TTL_SECONDS?: string;
  RATE_LIMIT_MAX_REQUESTS?: string;
  RATE_LIMIT_WINDOW_SECONDS?: string;
};

export async function generateMinutesWithAI(request: GenerateRequest, env: Env): Promise<MinutesResponse> {
  if (!geminiApiKey(env)) {
    throw new Error("GEMINI_API_KEY is not configured");
  }

  const processingMode = modeFor(request.transcript.length);
  const chunkLimit = Number(env.CHUNK_CHAR_LIMIT ?? "6000");

  if (processingMode === "long_chunked") {
    const chunks = chunkText(request.transcript, chunkLimit);
    const chunkNotes: string[] = [];

    for (const [index, chunk] of chunks.entries()) {
      const note = await callGeminiText(
        env,
        env.AI_MODEL_FAST ?? "gemini-2.5-flash-lite",
        `${chunkSystemPrompt()}\n\nチャンク ${index + 1}/${chunks.length}\n\n${chunk}`
      );
      chunkNotes.push(note);
    }

    return generateFinal(request, env, processingMode, chunkNotes.join("\n\n---\n\n"));
  }

  return generateFinal(request, env, processingMode, request.transcript);
}

async function generateFinal(request: GenerateRequest, env: Env, processingMode: ProcessingMode, sourceForAI: string): Promise<MinutesResponse> {
  const content = await callGeminiText(
    env,
    env.AI_MODEL_QUALITY ?? env.AI_MODEL_FAST ?? "gemini-2.5-flash",
    `${systemPrompt()}\n\n${userPrompt(request, sourceForAI, processingMode)}`,
    minutesJsonSchema()
  );

  const parsed = parseJsonObject(content);
  const validated = validateMinutesResponse(parsed);
  if (!validated) {
    return safeFallbackResponse(request, processingMode, "AI出力のJSON形式を検証できませんでした。");
  }

  const normalized = normalizeMinutesResponse(validated, request.transcript.length, processingMode, false);
  if (normalized.fullLog.length === 0) {
    normalized.fullLog = buildFullLog(request.transcript, request.speakers);
  }
  return normalized;
}

async function callGeminiText(env: Env, model: string, prompt: string, responseJsonSchema?: Record<string, unknown>): Promise<string> {
  const apiKey = geminiApiKey(env);
  if (!apiKey) throw new Error("GEMINI_API_KEY is not configured");

  const baseURL = env.GEMINI_BASE_URL ?? "https://generativelanguage.googleapis.com";
  const timeoutMs = Number(env.AI_TIMEOUT_MS ?? "45000");
  const maxRetries = Number(env.AI_MAX_RETRIES ?? "2");
  const url = `${baseURL.replace(/\/$/, "")}/v1beta/models/${encodeURIComponent(model)}:generateContent`;

  for (let attempt = 0; attempt <= maxRetries; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "x-goog-api-key": apiKey,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: 0.2,
            responseMimeType: "application/json",
            ...(responseJsonSchema ? { responseJsonSchema } : {})
          }
        }),
        signal: controller.signal
      });

      clearTimeout(timeout);

      if ((response.status === 429 || response.status >= 500) && attempt < maxRetries) {
        await sleep(250 * (attempt + 1));
        continue;
      }

      if (!response.ok) {
        throw new Error(`AI provider failed with status ${response.status}`);
      }

      const json = await response.json() as { candidates?: { content?: { parts?: { text?: string }[] } }[] };
      const content = json.candidates?.[0]?.content?.parts?.map((part) => part.text ?? "").join("");
      if (!content) throw new Error("AI provider returned empty content");
      return content;
    } catch (error) {
      clearTimeout(timeout);
      if (attempt >= maxRetries) throw error;
      await sleep(250 * (attempt + 1));
    }
  }

  throw new Error("AI provider retry budget exhausted");
}

function geminiApiKey(env: Env): string | undefined {
  return env.GEMINI_API_KEY;
}

export function chunkText(text: string, chunkCharLimit: number): string[] {
  const normalized = text.trim();
  if (normalized.length <= chunkCharLimit) return [normalized];

  const chunks: string[] = [];
  let cursor = 0;

  while (cursor < normalized.length) {
    const end = Math.min(cursor + chunkCharLimit, normalized.length);
    let sliceEnd = end;
    const newline = normalized.lastIndexOf("\n", end);
    if (newline > cursor + Math.floor(chunkCharLimit * 0.6)) {
      sliceEnd = newline;
    }
    chunks.push(normalized.slice(cursor, sliceEnd).trim());
    cursor = sliceEnd;
  }

  return chunks.filter(Boolean);
}

function parseJsonObject(content: string): unknown {
  try {
    return JSON.parse(content);
  } catch {
    const match = content.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

function systemPrompt(): string {
  return [
    "あなたはKoremiteの日本語議事録生成APIです。",
    "入力は音声ではなく、ユーザーが貼り付けた文字起こしテキストです。",
    "入力にない事実を追加しない。不明点は確認事項または未決事項に入れる。",
    "決定事項と推測を混ぜない。話者が不確実なら仮ラベルを使う。",
    "短い共有版、しっかりめの議事録、全量ログを固定JSONだけで返す。",
    "Markdownや説明文を付けず、JSONオブジェクトのみを返す。"
  ].join("\n");
}

function userPrompt(request: GenerateRequest, sourceForAI: string, processingMode: ProcessingMode): string {
  return `カテゴリ: ${request.category}
話者候補: ${request.speakers.join(", ") || "不明"}
重視ポイント: ${request.focusPoints.join(", ") || "指定なし"}
処理モード: ${processingMode}

次のJSONスキーマで返してください。
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

文字起こし:
${sourceForAI}`;
}

function chunkSystemPrompt(): string {
  return [
    "あなたは長い文字起こしのチャンクを低コストで圧縮する補助APIです。",
    "入力にない事実を追加せず、決定事項、TODO、金額、日付、懸念点、重要発言、確認事項を箇条書きJSONで残してください。",
    "JSONのみを返してください。"
  ].join("\n");
}

function minutesJsonSchema(): Record<string, unknown> {
  const nullableString = { type: ["string", "null"] };
  const todo = {
    type: "object",
    properties: {
      owner: nullableString,
      task: { type: "string" },
      due: nullableString
    },
    required: ["owner", "task", "due"]
  };

  return {
    type: "object",
    properties: {
      title: { type: "string" },
      shareSummary: {
        type: "object",
        properties: {
          text: { type: "string" },
          decisions: { type: "array", items: { type: "string" } },
          todos: { type: "array", items: todo },
          confirmationPoints: { type: "array", items: { type: "string" } }
        },
        required: ["text", "decisions", "todos", "confirmationPoints"]
      },
      detailedMinutes: {
        type: "object",
        properties: {
          overview: { type: "string" },
          topics: { type: "array", items: { type: "string" } },
          decisions: { type: "array", items: { type: "string" } },
          openIssues: { type: "array", items: { type: "string" } },
          todos: { type: "array", items: todo },
          importantRemarks: { type: "array", items: { type: "string" } },
          nextMeetingNotes: { type: "array", items: { type: "string" } }
        },
        required: ["overview", "topics", "decisions", "openIssues", "todos", "importantRemarks", "nextMeetingNotes"]
      },
      fullLog: {
        type: "array",
        items: {
          type: "object",
          properties: {
            speaker: { type: "string" },
            text: { type: "string" }
          },
          required: ["speaker", "text"]
        }
      },
      category: { type: "string", enum: ["住宅", "仕事", "家庭", "その他"] },
      confidenceWarnings: { type: "array", items: { type: "string" } },
      costInfo: {
        type: "object",
        properties: {
          inputLength: { type: "integer" },
          processingMode: { type: "string", enum: ["short", "normal", "long_chunked"] },
          cacheHit: { type: "boolean" }
        },
        required: ["inputLength", "processingMode", "cacheHit"]
      }
    },
    required: ["title", "shareSummary", "detailedMinutes", "fullLog", "category", "confidenceWarnings", "costInfo"]
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
