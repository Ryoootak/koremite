# API設計

## エンドポイント
`POST /v1/minutes`

## リクエスト
```json
{
  "transcript": "string",
  "category": "住宅 | 仕事 | 家庭 | その他",
  "speakers": ["string"],
  "focusPoints": ["話の流れ", "話題ごとのポイント", "金額", "スケジュール", "懸念点", "感情"],
  "clientRequestId": "string",
  "sourceHash": "string"
}
```

## レスポンス
```json
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
```

## エラー
アプリへは安全な日本語メッセージを返す。エラーに文字起こし本文を含めてはいけない。

- `400`: 入力なし、または入力が長すぎる
- `429`: レート制限超過
- `502`: AIプロバイダー障害
- `504`: タイムアウト

## バックエンドの責務
- 入力サイズのバリデーション
- MVP期間はIPベースのレート制限（将来的にデバイストークン方式も検討）
- 入力長によって処理モードを選択
- 固定JSONスキーマを使用
- リトライ回数とタイムアウトを制限
- AIのAPIキーは環境変数のみで保持
- `sourceHash` に対応する成功結果を `CACHE_TTL_SECONDS` の間キャッシュ
- `long_chunked` の場合、高速モデルでチャンクを圧縮してから最終合成
- MVPのAIプロバイダーは `GEMINI_API_KEY` と `GEMINI_BASE_URL` を通じたGemini API
