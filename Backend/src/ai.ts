import { buildFullLog, GenerateRequest, MinutesResponse, modeFor, normalizeMinutesResponse, ProcessingMode, safeFallbackResponse, validateMinutesResponse } from "./schema";

export type Env = {
  AI_API_KEY: string;
  AI_BASE_URL?: string;
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

type ChatMessage = {
  role: "system" | "user";
  content: string;
};

export async function generateMinutesWithAI(request: GenerateRequest, env: Env): Promise<MinutesResponse> {
  if (!env.AI_API_KEY) {
    throw new Error("AI_API_KEY is not configured");
  }

  const processingMode = modeFor(request.transcript.length);
  const chunkLimit = Number(env.CHUNK_CHAR_LIMIT ?? "6000");

  if (processingMode === "long_chunked") {
    const chunks = chunkText(request.transcript, chunkLimit);
    const chunkNotes: string[] = [];

    for (const [index, chunk] of chunks.entries()) {
      const note = await callChatText(env, env.AI_MODEL_FAST ?? "gpt-4o-mini", [
        { role: "system", content: chunkSystemPrompt() },
        { role: "user", content: `チャンク ${index + 1}/${chunks.length}\n\n${chunk}` }
      ]);
      chunkNotes.push(note);
    }

    return generateFinal(request, env, processingMode, chunkNotes.join("\n\n---\n\n"));
  }

  return generateFinal(request, env, processingMode, request.transcript);
}

async function generateFinal(request: GenerateRequest, env: Env, processingMode: ProcessingMode, sourceForAI: string): Promise<MinutesResponse> {
  const content = await callChatText(env, env.AI_MODEL_QUALITY ?? env.AI_MODEL_FAST ?? "gpt-4o-mini", [
    { role: "system", content: systemPrompt() },
    { role: "user", content: userPrompt(request, sourceForAI, processingMode) }
  ]);

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

async function callChatText(env: Env, model: string, messages: ChatMessage[]): Promise<string> {
  const baseURL = env.AI_BASE_URL ?? "https://api.openai.com";
  const timeoutMs = Number(env.AI_TIMEOUT_MS ?? "45000");
  const maxRetries = Number(env.AI_MAX_RETRIES ?? "2");
  const url = `${baseURL.replace(/\/$/, "")}/v1/chat/completions`;

  for (let attempt = 0; attempt <= maxRetries; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${env.AI_API_KEY}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          model,
          messages,
          temperature: 0.2,
          response_format: { type: "json_object" }
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

      const json = await response.json() as { choices?: { message?: { content?: string } }[] };
      const content = json.choices?.[0]?.message?.content;
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

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
