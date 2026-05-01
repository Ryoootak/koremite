import crypto from "node:crypto";

const categories = new Set(["住宅", "仕事", "家庭", "その他"]);
const allowedFocusPoints = new Set(["決定事項", "やること", "金額", "スケジュール", "懸念点", "感情"]);

export default async function handler(request, response) {
  if (request.method !== "POST") {
    response.setHeader("Allow", "POST");
    return response.status(405).json({ message: "POSTで送信してください。" });
  }

  const baseURL = process.env.KOREMITE_API_BASE_URL;
  if (!baseURL) {
    return response.status(500).json({ message: "KOREMITE_API_BASE_URLがVercelに設定されていません。" });
  }

  const body = request.body ?? {};
  const transcript = typeof body.transcript === "string" ? body.transcript.trim() : "";
  if (!transcript) {
    return response.status(400).json({ message: "文字起こしテキストを入力してください。" });
  }

  const category = categories.has(body.category) ? body.category : "その他";
  const speakers = Array.isArray(body.speakers)
    ? body.speakers.filter((speaker) => typeof speaker === "string" && speaker.trim()).slice(0, 8)
    : [];
  const focusPoints = Array.isArray(body.focusPoints)
    ? body.focusPoints.filter((point) => allowedFocusPoints.has(point)).slice(0, 12)
    : [];

  const sourceHash = hashSource({ transcript, category, speakers, focusPoints });

  try {
    const upstream = await fetch(`${baseURL.replace(/\/$/, "")}/v1/minutes`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        transcript,
        category,
        speakers,
        focusPoints,
        clientRequestId: crypto.randomUUID(),
        sourceHash
      })
    });

    const text = await upstream.text();
    response.status(upstream.status);
    response.setHeader("Content-Type", upstream.headers.get("Content-Type") ?? "application/json; charset=utf-8");
    return response.send(text);
  } catch {
    return response.status(502).json({ message: "Koremite staging APIに接続できませんでした。" });
  }
}

function hashSource(value) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(value))
    .digest("hex");
}
