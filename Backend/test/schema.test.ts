import { describe, expect, it } from "vitest";
import { chunkText } from "../src/ai";
import { modeFor, validateGenerateRequest, validateMinutesResponse } from "../src/schema";

describe("schema", () => {
  it("validates generate requests without leaking body text in errors", () => {
    const result = validateGenerateRequest({ transcript: "   " }, 30000);
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.message).toBe("文字起こしテキストを貼り付けてください。");
    }
  });

  it("normalizes category and bounded metadata", () => {
    const result = validateGenerateRequest({
      transcript: "打ち合わせ本文",
      category: "不明",
      speakers: ["自分", "相手"],
      focusPoints: ["決定事項"],
      clientRequestId: "req-1",
      sourceHash: "hash-1"
    }, 30000);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.request.category).toBe("その他");
      expect(result.request.sourceHash).toBe("hash-1");
    }
  });

  it("rejects invalid minutes response shape", () => {
    expect(validateMinutesResponse({ title: "bad" })).toBeNull();
  });

  it("selects processing modes and chunks long text", () => {
    expect(modeFor(100)).toBe("short");
    expect(modeFor(3000)).toBe("normal");
    expect(modeFor(9000)).toBe("long_chunked");
    expect(chunkText("a".repeat(13), 5)).toHaveLength(3);
  });
});
