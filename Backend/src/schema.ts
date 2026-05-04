export type Category = "住宅" | "仕事" | "家庭" | "その他";
export type ProcessingMode = "short" | "normal" | "long_chunked";

export type GenerateRequest = {
  transcript: string;
  category: Category;
  speakers: string[];
  focusPoints: string[];
  clientRequestId: string;
  sourceHash: string;
};

export type MinutesResponse = {
  title: string;
  shareSummary: {
    text: string;
    decisions: string[];
    todos: TodoItem[];
    confirmationPoints: string[];
  };
  detailedMinutes: {
    overview: string;
    topics: string[];
    decisions: string[];
    openIssues: string[];
    todos: TodoItem[];
    importantRemarks: string[];
    nextMeetingNotes: string[];
  };
  fullLog: { speaker: string; text: string }[];
  category: Category;
  confidenceWarnings: string[];
  costInfo: {
    inputLength: number;
    processingMode: ProcessingMode;
    cacheHit: boolean;
  };
};

type TodoItem = {
  owner: string | null;
  task: string;
  due: string | null;
};

const categories = new Set(["住宅", "仕事", "家庭", "その他"]);
const modes = new Set(["short", "normal", "long_chunked"]);

export function modeFor(length: number): ProcessingMode {
  if (length < 2000) return "short";
  if (length < 8000) return "normal";
  return "long_chunked";
}

export function validateGenerateRequest(value: unknown, maxInputChars: number): { ok: true; request: GenerateRequest } | { ok: false; message: string } {
  if (!isRecord(value)) return { ok: false, message: "リクエストを読み取れませんでした。" };

  const transcript = typeof value.transcript === "string" ? value.transcript.trim() : "";
  if (!transcript) return { ok: false, message: "文字起こしテキストを貼り付けてください。" };
  if (transcript.length > maxInputChars) return { ok: false, message: `${maxInputChars}文字以内に調整してください。` };

  const category = categories.has(String(value.category)) ? (value.category as Category) : "その他";
  const speakers = Array.isArray(value.speakers) ? value.speakers.filter(isNonEmptyString).slice(0, 8) : [];
  const focusPoints = Array.isArray(value.focusPoints) ? value.focusPoints.filter(isNonEmptyString).slice(0, 12) : [];
  const clientRequestId = isNonEmptyString(value.clientRequestId) ? value.clientRequestId : crypto.randomUUID();
  const sourceHash = isNonEmptyString(value.sourceHash) ? value.sourceHash : clientRequestId;

  return {
    ok: true,
    request: { transcript, category, speakers, focusPoints, clientRequestId, sourceHash }
  };
}

export function validateMinutesResponse(value: unknown): MinutesResponse | null {
  if (!isRecord(value)) return null;
  if (!isNonEmptyString(value.title)) return null;
  if (!isRecord(value.shareSummary) || !isRecord(value.detailedMinutes)) return null;
  if (!Array.isArray(value.fullLog)) return null;
  if (!categories.has(String(value.category))) return null;
  if (!Array.isArray(value.confidenceWarnings)) return null;
  if (!isRecord(value.costInfo)) return null;
  if (typeof value.costInfo.inputLength !== "number") return null;
  if (!modes.has(String(value.costInfo.processingMode))) return null;
  if (typeof value.costInfo.cacheHit !== "boolean") return null;

  const share = value.shareSummary;
  const detailed = value.detailedMinutes;

  if (!isNonEmptyString(share.text)) return null;
  if (!isStringArray(share.decisions) || !isTodoArray(share.todos) || !isStringArray(share.confirmationPoints)) return null;

  if (!isNonEmptyString(detailed.overview)) return null;
  if (!isStringArray(detailed.topics)) return null;
  if (!isStringArray(detailed.decisions)) return null;
  if (!isStringArray(detailed.openIssues)) return null;
  if (!isTodoArray(detailed.todos)) return null;
  if (!isStringArray(detailed.importantRemarks)) return null;
  if (!isStringArray(detailed.nextMeetingNotes)) return null;

  if (!value.fullLog.every((entry) => isRecord(entry) && isNonEmptyString(entry.speaker) && isNonEmptyString(entry.text))) return null;
  if (!isStringArray(value.confidenceWarnings)) return null;

  return value as MinutesResponse;
}

export function normalizeMinutesResponse(value: MinutesResponse, inputLength: number, processingMode: ProcessingMode, cacheHit: boolean): MinutesResponse {
  return {
    ...value,
    costInfo: { inputLength, processingMode, cacheHit },
    fullLog: value.fullLog.slice(0, 500)
  };
}

export function safeFallbackResponse(request: GenerateRequest, processingMode: ProcessingMode, warning: string): MinutesResponse {
  return {
    title: `${request.category}の打ち合わせメモ`,
    shareSummary: {
      text: "自動整形で一部を確認できませんでした。元の記録を見ながら、内容を確認してください。",
      decisions: [],
      todos: [],
      confirmationPoints: []
    },
    detailedMinutes: {
      overview: "入力された文字起こしは受け付けましたが、AI出力の形式検証に失敗しました。安全のため、入力にない内容を補わず、元の記録を確認できる状態で返しています。",
      topics: [],
      decisions: [],
      openIssues: ["AI出力の形式を確認できなかったため、元の記録を見返す必要があります。"],
      todos: [],
      importantRemarks: [],
      nextMeetingNotes: []
    },
    fullLog: buildFullLog(request.transcript, request.speakers),
    category: request.category,
    confidenceWarnings: [warning],
    costInfo: {
      inputLength: request.transcript.length,
      processingMode,
      cacheHit: false
    }
  };
}

export function buildFullLog(transcript: string, speakers: string[]): { speaker: string; text: string }[] {
  const speaker = speakers[0] || "話者A";
  const paragraphs = transcript
    .split(/\n{2,}|\r\n{2,}/)
    .map((text) => text.trim())
    .filter(Boolean);

  const source = paragraphs.length > 0 ? paragraphs : [transcript.trim()];
  return source.slice(0, 500).map((text) => ({ speaker, text }));
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every((item) => typeof item === "string");
}

function isTodoArray(value: unknown): value is TodoItem[] {
  return Array.isArray(value) && value.every((item) => {
    if (!isRecord(item)) return false;
    return (typeof item.owner === "string" || item.owner === null)
      && isNonEmptyString(item.task)
      && (typeof item.due === "string" || item.due === null);
  });
}
