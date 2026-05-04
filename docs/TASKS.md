# タスク管理

## 現在の状態
- MVPの前提: テキスト専用Koremite、音声処理なし
- Cloudflare Workersステージングは `https://koremite-api-staging.koremite.workers.dev` にデプロイ済み
- `swiftc -parse` は現在のSwiftソースで通過
- ローカル環境では `xcode-select` が `/Library/Developer/CommandLineTools` を指しているため `xcodebuild` は実行不可

## 完了済み
- 参考HTMLのデザイン分析（カラー・カード・チップ・セグメント・余白・iOS的トーン）
- プロダクト・アーキテクチャ・API・プロンプト・コスト・セキュリティ・プライバシー・App Store・設計判断の各ドキュメント作成
- `Koremite.xcodeproj` 追加
- DesignSystem追加（温かみ背景・カード・モスアクセント・チップ・プライマリボタン）
- 入力画面（貼り付けエリア・文字数・長文ヒント・任意話者追加・保存先フォルダ・重視ポイント・サーバー処理告知）
- ローディング画面と結果画面（短くまとめ/詳しくまとめ/元の記録タブ）
- アーカイブ画面（検索・削除）
- `AIClient`・`MockAIClient`・`RemoteAIClient` 追加
- `ArchivedMinutesRecord` によるSwiftDataアーカイブ追加
- XCTestターゲットと初期テスト追加
- Cloudflare Workersバックエンド（`/v1/minutes`・Gemini API・スキーマバリデーション・タイムアウト・リトライ上限・キャッシュ・レート制限・長文チャンク基盤）
- バックエンドテスト7件通過
- バックエンドtypecheck通過（`npm run typecheck`）
- Gemini APIステージング確認（HTTP 200）
- 同一 `sourceHash` で `costInfo.cacheHit: true` を確認
- Vercelテストページと `/api/minutes-test` プロキシ追加
- GitHub Actions CI追加（バックエンドチェック・Vercel構文・iOSシミュレータビルド/テスト）
- GitHub Actions CI run #2 mainブランチで通過
- **Codex 2026-05-03補足**: 参考HTMLに近いVercel Previewへ刷新、Cloudflare Workersステージングへ疎通、Vercel環境変数は`KOREMITE_API_BASE_URL`のみ、GeminiキーはCloudflare secretのみで運用する方針を確認
- **Codex 2026-05-03補足**: Web PreviewのアーカイブをlocalStorageで永続化、保存ボタンを追加、生成中コピーから「コストを抑える」表現を削除
- **安定ID修正**: `ArchivedMinutesRecord.decodedResult()` が `recordID` から一貫したUUIDを復元するよう修正（検索フォーカス喪失・NavigationLink不動作の根本原因を解決）
- **フォルダシステム**: `FolderRecord`（SwiftData）・`ArchiveStore` のフォルダCRUD・`folderAssignments`ディクショナリ追加
- **ArchiveView全面刷新**: フォルダ階層ナビ（全て/フォルダなし/各フォルダへのドリルダウン）・フォルダ作成/削除/名前変更・タブ切替でトップ画面に戻るリセット
- **元の記録タブ復活**: 結果画面に3枚目タブとして復元（話者・テキスト両方で絞り込み検索付き）
- **手動フォルダ割り当て**: 保存ボタン→FolderPickerSheetフロー・シートからフォルダ新規作成も可能・自動分類なし
- 全ドキュメントを日本語化
- **Vercel index.html全面刷新**: 元の記録タブ（3枚目・発言/話者検索付き）追加・ユーザー管理フォルダ（作成/削除・localStorage永続化）・保存前フォルダ選択シート・アーカイブ画面フォルダフィルタチップ・壊れていたログタブ強制リセット削除・ダミーアーカイブ削除（タップ無反応の原因）
- **検索改善**: iOS/SwiftUIとWeb Previewのアーカイブ検索・元の記録検索を曖昧検索化。アーカイブ検索対象に詳しくまとめと元の記録本文も含める
- **Web Preview検索フォーカス修正**: アーカイブ/元の記録検索の入力ごとの再描画でフォーカスが外れる問題を、再描画後のフォーカス復元で修正
- **検索確定タイミング修正**: iOS/SwiftUIとWeb Previewのアーカイブ検索・元の記録検索は、入力中ではなくReturn/Enterまたは検索ボタンで確定した時だけ結果を更新する
- **保存重複対策**: SwiftData保存時に`sourceHash`だけでなく`recordID`でも既存レコードを検出し、同じまとめの二重保存を避ける
- **フォルダUX改善**: 入力画面の「用途」を「保存先フォルダ」に統合。フォルダアイコン付き選択、新規フォルダ作成導線、生成結果保存時の候補フォルダ引き継ぎを追加。アーカイブトップは説明過多な見出しを避け、フォルダ・一覧・最近のまとめで整理
- **画面遷移修正**: Web Previewでアーカイブから保存済みまとめを開いた結果画面の戻り先を、作成設定ではなくアーカイブにするよう文脈管理を追加
- **話者入力UX改善**: 入力画面の話者欄を任意項目化し、「自分」を固定、相手は1人ずつ追加/削除するUIへ変更。カンマ区切り入力を廃止
- **AIプロンプト日本語化**: BackendのGemini向けシステム/ユーザープロンプトと`docs/AI_PROMPTS.md`を日本語指示に統一
- **ロゴ配置**: 提供された`logo.png`をiOSアセットカタログとVercel Previewのヘッダー/ホームに配置
- **網羅チェック修正**: Xcodeプロジェクトへの追加Swiftファイル登録漏れを修正、Cloudflare本番varsのモデルplaceholderをGeminiモデルに更新、Vercel Previewの初期ダミー入力/初期フォルダをiOSに合わせて空に変更
- **まとめ名称・構成変更**: 出力タブを「短くまとめ」「詳しくまとめ」「元の記録」に変更。短くまとめは「ざっくり」のみ、詳しくまとめは「話の流れ」「話題ごとのポイント」「AIが気になったこと」に絞り、決定事項/TODO系は生成方針と表示から外した

## 次のステップ
- Xcodeでビルドし、iOSシミュレータで動作確認
- `xcode-select` をXcode.appに切り替えてXCTestを実行
- Xcode実行環境が整ったらSwiftData統合テストを追加
- ステージングWorkerで実際のAIプロバイダーをテストシークレットで検証
- iOS `RemoteAIClient` をビルド/設定スイッチ経由でステージングURLに接続
- VercelプレビューデプロイからブラウザでCloudflareステージングへの疎通確認
- iOSのXCTestカバレッジ拡充（ユーティリティとモッククライアント以外）
- 本番トラフィックが発生した場合、インメモリWorkerキャッシュ/レート制限をKV/Durable Objectに移行

## バックログ
- XCTestカバレッジの拡充
- サーバーサイド耐久キャッシュ/レート制限の実装
- MVP後のShare Extension

## ローカル検証メモ
`xcodebuild -list -project Koremite.xcodeproj` は現在以下のエラーで失敗:

```text
xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance
```

後で実行する場合:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -list -project Koremite.xcodeproj
xcodebuild test -project Koremite.xcodeproj -scheme Koremite -destination 'platform=iOS Simulator,name=iPhone 15'
```
