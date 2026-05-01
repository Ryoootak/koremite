import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../src/index";

const validAIResponse = {
  choices: [{
    message: {
      content: JSON.stringify({
        title: "住宅の打ち合わせ",
        shareSummary: {
          text: "共有用の短い要約です。",
          decisions: ["次回確認する"],
          todos: [{ owner: null, task: "資料を確認する", due: null }],
          confirmationPoints: ["金額"]
        },
        detailedMinutes: {
          overview: "概要です。",
          topics: ["論点"],
          decisions: ["決定"],
          openIssues: ["未決"],
          todos: [{ owner: "自分", task: "確認する", due: "次回" }],
          importantRemarks: ["重要発言"],
          nextMeetingNotes: ["次回メモ"]
        },
        fullLog: [{ speaker: "自分", text: "本文" }],
        category: "住宅",
        confidenceWarnings: [],
        costInfo: { inputLength: 0, processingMode: "short", cacheHit: false }
      })
    }
  }]
};

describe("worker", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("returns generated minutes through AI provider", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => Response.json(validAIResponse)));

    const response = await worker.fetch(new Request("https://api.example.com/v1/minutes", {
      method: "POST",
      headers: { "Content-Type": "application/json", "CF-Connecting-IP": "203.0.113.10" },
      body: JSON.stringify({
        transcript: "今日は住宅ローンについて話した。",
        category: "住宅",
        speakers: ["自分", "担当者"],
        focusPoints: ["金額"],
        clientRequestId: "req-1",
        sourceHash: "hash-test-1"
      })
    }), testEnv());

    expect(response.status).toBe(200);
    const json = await response.json() as { title: string; costInfo: { inputLength: number; cacheHit: boolean } };
    expect(json.title).toBe("住宅の打ち合わせ");
    expect(json.costInfo.inputLength).toBeGreaterThan(0);
    expect(json.costInfo.cacheHit).toBe(false);
  });

  it("rate limits repeated requests", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => Response.json(validAIResponse)));

    const env = testEnv({ RATE_LIMIT_MAX_REQUESTS: "1", RATE_LIMIT_WINDOW_SECONDS: "60" });
    const request = () => new Request("https://api.example.com/v1/minutes", {
      method: "POST",
      headers: { "Content-Type": "application/json", "CF-Connecting-IP": "203.0.113.11" },
      body: JSON.stringify({
        transcript: "本文",
        category: "仕事",
        speakers: [],
        focusPoints: [],
        clientRequestId: crypto.randomUUID(),
        sourceHash: crypto.randomUUID()
      })
    });

    expect((await worker.fetch(request(), env)).status).toBe(200);
    expect((await worker.fetch(request(), env)).status).toBe(429);
  });

  it("does not call AI for invalid input", async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);

    const response = await worker.fetch(new Request("https://api.example.com/v1/minutes", {
      method: "POST",
      body: JSON.stringify({ transcript: "" })
    }), testEnv());

    expect(response.status).toBe(400);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

function testEnv(overrides: Record<string, string> = {}) {
  return {
    AI_API_KEY: "test-key",
    AI_BASE_URL: "https://ai.example.com",
    AI_MODEL_FAST: "fast",
    AI_MODEL_QUALITY: "quality",
    MAX_INPUT_CHARS: "30000",
    CACHE_TTL_SECONDS: "1",
    RATE_LIMIT_MAX_REQUESTS: "20",
    RATE_LIMIT_WINDOW_SECONDS: "3600",
    ...overrides
  };
}
