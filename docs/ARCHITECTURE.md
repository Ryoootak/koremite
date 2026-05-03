# アーキテクチャ

## 概要
KoremiteはネイティブSwiftUI iOSアプリと小さなバックエンドAPIで構成される。iOSアプリがAIプロバイダーを直接呼び出すことはない。

```text
iOS SwiftUIアプリ -> Koremiteバックエンド -> AIプロバイダー
                  -> ローカルSwiftDataアーカイブ
```

## iOSの層構成
- **Views**: SwiftUIスクリーンと再利用可能なコンポーネント
- **ViewModels**: 状態・バリデーション・ローディング・リトライ・保存/コピー/共有の調整
- **Models**: 固定リクエスト/レスポンススキーマ
- **Services**: `AIClient`・`MockAIClient`・`RemoteAIClient`・アーカイブストレージ
- **DesignSystem**: カラー・余白・タイポグラフィ・カード・チップ・ボタン

## データフロー
1. ユーザーが文字起こしテキストを貼り付ける
2. ViewModelが文字数をバリデートし、処理モードを表示する
3. `AIClient.generateMinutes` を呼び出す
4. 開発中はMockClientがローカルで決定的データを返す
5. Remoteクライアントがバックエンド `/v1/minutes` にPOSTする
6. 結果をJSONとしてデコードする。不正なデータは日本語エラーにフォールバックする
7. ユーザーがコピー/共有/保存する

## ストレージ
SwiftDataが`ArchivedMinutesRecord`を通じて生成済み議事録をデバイスに保存する。保存対象は生成出力・カテゴリ・作成日・sourceHash・検索メタデータ・フォルダID。バックエンドのシークレットは保存しない。

フォルダ管理は`FolderRecord`（SwiftData）で行い、`ArchiveStore`が`folderAssignments`ディクショナリを通じてView層にID→名前のマッピングを提供する。

## バックエンド選択理由
小規模APIに対してシンプル・低コスト・デプロイ容易・環境変数対応・エッジレイテンシ良好・サーバー管理不要という点からCloudflare WorkersをMVPに採用。詳細は `docs/DECISIONS.md` を参照。

## セキュリティ境界
iOSアプリはKoremiteバックエンドのエンドポイントのみを知っている。バックエンドがAIプロバイダー認証情報・入力制限・レート制限ポリシー・リトライ上限・タイムアウト・キャッシュTTL・チャンク処理・スキーマバリデーション・モデル選択をすべて管理する。
