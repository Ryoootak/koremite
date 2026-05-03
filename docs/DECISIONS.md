# 設計判断記録

## 2026-05-01: ネイティブ SwiftUI（WebView 不採用）
KoremiteはネイティブSwiftUIアプリとして実装する。提供されたHTMLはビジュアル参考のみ。App Store審査通過・アクセシビリティ・iOS標準UXへの準拠を優先した判断。

## 2026-05-01: テキスト専用MVP
MVPは貼り付けられた文字起こしテキストのみを扱う。音声録音・マイク権限・Speech Recognition・音声ファイルインポート・音声アップロード・話者分離はスコープ外。

## 2026-05-01: iOS 17+ と SwiftData
iOS 17+を最低対応バージョンとするため、ローカルアーカイブの第一選択はSwiftData。永続化のボイラープレートを削減できる。

## 2026-05-01: バックエンド必須（iOS直接AI呼び出し禁止）
iOSはAIプロバイダーを直接呼び出さない。アプリはKoremiteバックエンドを呼び出し、バックエンドがプロバイダー認証情報・モデル選択・レート制限・入力制限・タイムアウト・リトライを管理する。

## 2026-05-01: バックエンドはCloudflare Workers
Supabase Edge FunctionsやVercel Functionsではなく、Cloudflare Workersを採用。小規模なステートレスAPIにシンプル・低コスト・デプロイ容易・環境変数シークレット対応の点で優位。Supabaseは認証/DB機能が中心になった場合、VercelはNext.js Webが中心になった場合の候補として残す。

## 2026-05-01: コストを意識した処理モード
`short`・`normal`・`long_chunked` の3モードをUIで説明。バックエンド実装ではモデルとトークン上限を環境変数で切り替え可能にする。

## 2026-05-01: 参考HTMLのデザイン適応方針
温かみのあるオフホワイト背景・白カード・モスグリーンアクセント・ピル型チップ・セグメントコントロール・ゆとりある余白・iOS的な抑制感を維持。波形・録音ボタン・音声インポートなど音声中心のUIは除外する。

## 2026-05-01: SwiftData アーカイブラッパー構成
アーカイブをインメモリStateからSwiftData（`ArchivedMinutesRecord`）へ移行。`ArchiveStore`を小さなUIラッパーとして維持することで、Viewの変更を最小限に抑え、永続化境界のテストを容易にする。

## 2026-05-01: Gemini バックエンドアダプター
WorkerはGemini API `generateContent` エンドポイントを`GEMINI_BASE_URL`で呼び出す。AIキーはCloudflareシークレット`GEMINI_API_KEY`に格納し、iOSはKoremiteバックエンドのみと通信する。

## 2026-05-03: VercelウェブプレビューによるiOS UX検証
Vercel Next.jsページ（`/`）がiOSの入力→ローディング→結果フローをlocalStorageを使って再現する。Vercel Function（`/api/minutes-test`）がCloudflare Workersバックエンドへプロキシする。GeminiキーはCloudflareのみに保持し、Vercelには`KOREMITE_API_BASE_URL`だけ設定する。

## 2026-05-03: 3層出力構成（共有版 / 議事録 / 全量ログ）
ResultViewは「共有版」「議事録」「全量ログ」の3タブを持つ。全量ログタブは話者別エントリのリストで、タブ内検索フィールドにより話者名・テキストで絞り込み可能。一度削除したが、要約済み出力と並べて生の追跡可能性を保持するために復元した。

## 2026-05-03: ユーザー管理フォルダ（自動分類なし）
アーカイブ整理はフラットなフォルダモデル（SwiftDataの`FolderRecord`）で行う。フォルダはユーザーが作成・名前変更・削除する。`MeetingCategory`（用途）に基づく自動フォルダ割り当ては実施しない。カテゴリは表示とプロンプトのヒントとしてのみ機能する。フォルダへの割り当ては、ResultView保存/フォルダボタンから表示される`FolderPickerSheet`で手動に行う。フォルダ削除時、中のアイテムはデフォルトで「フォルダなし」へ移動し、一括削除も選択できる。

## 2026-05-03: SwiftDataレコードの安定ID
`ArchivedMinutesRecord.decodedResult()`で`result.id`を保存時の`recordID`から復元する。この修正なしでは、`refresh()`のたびに新しいUUIDが生成され、SwiftUIの`ForEach`差分処理がキーストロークごとに全アイテムを新規と見なし、検索フォームのフォーカス喪失と`NavigationLink`の動作不全を引き起こしていた。

## 2026-05-03: タブ切替時のアーカイブナビゲーションリセット
`RootView`がアーカイブ用`NavigationStack`の`NavigationPath`を所有する。別タブからアーカイブタブを選択するたびにパスを空にリセットする（`onChange(of: selectedTab)`）。これにより、アーカイブに戻るたびにフォルダ一覧トップ画面から始まるようになる。
