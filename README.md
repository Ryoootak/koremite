# Koremite

Koremiteは、貼り付けた文字起こしテキストを送りやすく・見返しやすい議事録に整えるiPhoneアプリです。

MVPの使い方はシンプルです。ボイスメモや別のアプリで文字起こしされたテキストをコピーし、Koremiteに貼り付け、会議の用途と重視ポイントを選んで議事録を生成、コピー/共有/保存する。

## できること
- 貼り付けた文字起こしテキストを受け付ける
- LINEやメッセージで送れる短い共有版を生成する
- 詳細な議事録を生成する
- 全量ログ（話者別エントリ）を保持する
- 生成済み議事録をローカルに保存する
- 入力時に保存先フォルダを選び、フォルダ管理、曖昧検索、削除ができる

## できないこと
- 録音なし
- 音声ファイルインポートなし
- マイク権限なし
- Speech Recognition権限なし
- 音声アップロードなし
- MVPにログイン・課金・iCloud Sync・Share Extensionなし

## MVPのスコープ
SwiftUI入力/結果/アーカイブ画面・`MockAIClient`・バックエンド接続用`RemoteAIClient`・ローカルアーカイブ（フォルダ管理付き）・コピー/共有・エラーとリトライ・プライバシー/セキュリティドキュメント・コストを意識したAI処理設計

## 技術スタック
- iOS 17+・SwiftUI・Swift Concurrency・SwiftData
- MVVM/軽量クリーンアーキテクチャ
- バックエンド: Cloudflare Workers + TypeScript
- AI経路: iOS → Koremiteバックエンド → AI API
- アーカイブ: デバイス上のSwiftData（フォルダ管理付き）

## iOSの起動方法
`Koremite.xcodeproj` をXcodeで開き、iOS 17+シミュレータで `Koremite` スキームを実行する。

CLIビルド:

```sh
xcodebuild -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## バックエンドの起動方法
```sh
cd Backend
npm install
npm run dev
```

## Vercelテストページ
Vercelが `/` に小さなブラウザテストページをホストできる。`/api/minutes-test` 経由でCloudflare Workersステージング APIにリクエストを転送する。
このページは古いMacでもUXを確認するためのPreviewで、保存済み議事録とフォルダはブラウザの`localStorage`に保存する。同じブラウザ内では再読み込み後も残るが、端末間同期はしない。

必要なVercel環境変数:

- `KOREMITE_API_BASE_URL=https://koremite-api-staging.koremite.workers.dev`

`GEMINI_API_KEY` はVercelに追加しない。GeminiのAPIキーはCloudflare Workersシークレットにのみ置く。

## 環境変数
`Backend/.env.example` をローカルの環境変数プロバイダーにコピーする。実際のシークレットは絶対にコミットしない。

必要なバックエンド変数:
- `GEMINI_API_KEY`
- `GEMINI_BASE_URL`
- `AI_MODEL_FAST`
- `AI_MODEL_QUALITY`
- `MAX_INPUT_CHARS`
- `AI_TIMEOUT_MS`
- `AI_MAX_RETRIES`
- `CHUNK_CHAR_LIMIT`
- `CACHE_TTL_SECONDS`
- `RATE_LIMIT_MAX_REQUESTS`
- `RATE_LIMIT_WINDOW_SECONDS`

## テスト
- iOS: `xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'`
- バックエンド: `cd Backend && npm test`
- バックエンドtypecheck: `cd Backend && npm run typecheck`
- Vercel Functionの構文チェック: `npm run check:vercel`
- GitHub Actions: `.github/workflows/ci.yml` がpush/PRごとにバックエンドテスト/typecheck・Vercel構文チェック・iOSシミュレータビルド/テストを実行

ローカル制限事項: `xcode-select -p` が `/Library/Developer/CommandLineTools` を指している間は `xcodebuild` が実行できない。解決方法:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -list -project Koremite.xcodeproj
xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'
```

## ディレクトリ構成
- `Koremite/`: iOSアプリ
- `Backend/`: APIワーカー
- `.github/workflows/`: GitHub Actions CI
- `docs/`: プロダクト・エンジニアリングドキュメント

## 開発上の注意
AI APIキーをiOSコードに置かない。貼り付けテキストをログに記録しない。MVPはテキスト専用を維持する。コスト最小化は製品の一部: キャッシュ結果の再利用・入力/リトライの上限・長文の段階的処理を実施する。

## App Store申請前
申請前に `docs/APP_STORE_CHECKLIST.md` を完了し、プライバシーポリシーを公開し、Privacy Nutrition Labelsを確認し、将来のスコープで明示的に追加しない限りマイクやSpeech Recognitionの利用説明文がないことを確認する。
