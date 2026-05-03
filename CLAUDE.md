# CLAUDE.md

## 作業スタイル
1. まず探索: コードを変更する前に関連ファイルを確認する
2. 次に計画: 大きな変更は短い計画を書いて最新に保つ
3. 最後に実装: 長い説明より実際のファイル・テスト・検証を優先する

## 検証方法
- iOS: Xcodeまたは `xcodebuild -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15' build`
- iOSテスト: `xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'`
- バックエンド: `cd Backend && npm install && npm run dev`、テストは `npm test`、型チェックは `npm run typecheck`
- Vercel Preview: `npm run check:vercel` で構文確認。ブラウザ保存/フォルダは`localStorage`のPreview用実装
- 実装後はビルドエラー・プライバシー漏洩・APIキー露出・コスト増加・音声スコープの混入を自己レビューする

## ハードルール
- KoremiteのMVPは貼り付けた文字起こしテキストのみを扱う
- 録音・マイク権限・Speech Recognition権限・音声アップロード・音声ファイルインポートを追加しない
- iOSからAIプロバイダーを直接呼び出さない
- AI APIキーはバックエンドの環境変数にのみ置く
- 貼り付けた文字起こしテキスト・生成テキスト・APIペイロード全文・ユーザー個人データをログに記録しない
- クラッシュ/アナリティクス/エラーメッセージに会話テキストを含めない
- 外部への共有はユーザーの明示的な操作を必要とする
- アーカイブと全量ログの検索UXを壊さない。入力中のフォーカス維持、保存済み議事録の詳細遷移、タブ復帰時のアーカイブトップ表示を確認する

## コストルール
- 設計判断にコスト最小化を含める
- 入力長・チャンキング・ローカルキャッシュ・固定JSONスキーマ・上限付きリトライ・タイムアウト・モデル切り替え可能なバックエンド設定を使用する
- SwiftDataアーカイブ機能が増えたらXCTestでカバーする
- 処理パイプラインが変わったら `docs/COST_STRATEGY.md` を更新する

## コンテキスト管理
コンテキストが増えてきたら、現在の進捗を `docs/TASKS.md` に、設計判断を `docs/DECISIONS.md` に記録する。次のエージェントはそれらのファイルから作業を継続する。

## Gitルール
- コミットは変更の単位ごとに分割する（バグ修正・機能追加・ドキュメント更新などを1コミットにまとめない）
- プッシュ前にユーザーに確認する、または明示的に「プッシュして」と言われた場合のみ実行する

## 作業報告
作業後は変更ファイル・実行したコマンド・検証結果・残課題・次の推奨タスクを報告する。
