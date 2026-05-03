# AGENTS.md

## プロジェクト概要
KoremiteはiOS 17+ SwiftUIアプリで、貼り付けた文字起こしテキストを送れる共有版・詳細な議事録・全量ログの3層に整える。MVPはテキスト専用。音声録音・音声ファイルインポート・マイク権限・Speech Recognition権限・音声アップロードは実装してはいけない。

## ゴール
「文字起こしテキストをコピー → 議事録生成 → コピー/共有/保存」のApp Store申請可能なMVPを、低AIAPIコストをコアの製品価値として出荷する。

## スタック
- iOS: SwiftUI・Swift Concurrency・SwiftData・MVVM/軽量クリーンアーキテクチャ
- バックエンド: Cloudflare Workers・TypeScript
- AI接続: iOS → Koremiteバックエンド → AI API のみ
- ローカル開発AI: `MockAIClient`

## ディレクトリ構成
- `Koremite/`: SwiftUIアプリソース
- `Koremite/DesignSystem/`: カラー・余白・タイポグラフィ・再利用スタイル
- `Koremite/Models/`: ドメインモデルとAPIモデル
- `Koremite/Services/`: API・ストレージ・クリップボード/共有ヘルパー
- `Koremite/ViewModels/`: 画面状態と調整ロジック
- `Koremite/Views/`: SwiftUIスクリーン/コンポーネント
- `Backend/`: Cloudflare Worker API
- `docs/`: プロダクト・アーキテクチャ・セキュリティ・コスト・タスク・設計判断

## ビルドとテスト
- `Koremite.xcodeproj` をXcodeで開き、iOS 17+シミュレータでKoremiteスキームを実行する
- CLIビルド: `xcodebuild -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15' build`
- CLIテスト: `xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'`
- バックエンドローカル起動: `cd Backend && npm install && npm run dev`
- バックエンドテスト: `cd Backend && npm test`
- バックエンドtypecheck: `cd Backend && npm run typecheck`

## コーディングルール
- 探索→計画→実装の順で進める
- 編集前に関連ファイルを読み、非自明な作業はプランを更新する
- Viewは小さく保つ。定数は `DesignSystem`、振る舞いはViewModels、ネットワーク処理はServicesへ
- 文字列パースよりJSON構造化パースを優先する
- UIコピーは日本語。システム/API識別子のみ英語が必要な場合は例外
- MVPに音声機能を追加しない
- 貼り付けた文字起こし・生成済み議事録・APIペイロード・個人データをログに記録しない
- iOSコード・plistファイル・アセット・GitにAI APIキーを置かない

## コストルール
- コスト最小化は後付けではなく製品の振る舞いとして扱う
- 入力長に基づく処理モード `short`・`normal`・`long_chunked` を使用する
- 可能な場合は同一入力ハッシュのローカル保存結果を再利用する
- 1つの固定JSONスキーマですべての出力を一度にリクエストする
- 入力サイズ・出力サイズ・タイムアウト・リトライ回数を制限する
- バックエンドでキャッシュTTL・レート制限・タイムアウト・リトライ上限・長文チャンク圧縮を使用する

## 完了の定義
- ビルド可能、またはブロック理由が明確に文書化されている
- 関連テストまたは手動確認が完了している
- `docs/TASKS.md` が現在の状態に更新されている
- アーキテクチャ/プロダクト判断について `docs/DECISIONS.md` が更新されている
- セキュリティ・プライバシー・コスト・MVPスコープの自己レビューが完了している
- 最終レポートに変更ファイル・確認コマンド・完了作業・未完了作業・次のステップが含まれている

## 引き継ぎ
CodexとClaude Code間で引き継ぐ際は、このファイル・`CLAUDE.md`・`docs/TASKS.md`・`docs/DECISIONS.md` を最初に読む。作業を止める前に進行中の作業を `docs/TASKS.md` にまとめる。
