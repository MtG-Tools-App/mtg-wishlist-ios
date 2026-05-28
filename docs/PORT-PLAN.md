# Web → iOS 移植プラン

## 方針

- **解釈 B**: 構造とふるまいを移植。見た目は iOS 側で 明朝 / クリーム / Liquid Glass で作り直す（HTML/CSS の literal コピーはしない）。
- **範囲**: **Web 機能パリティ**。MVP カットはしない。Web で動く全機能を SwiftUI で再現。
- **データ**: 完全独立。SwiftData ローカル DB。Web ⇄ iOS の往来は今朝固定した **JSON backup 形式** が橋。
- **iOS 独自機能**: OS 標準パターン（pull-to-refresh / swipe / share sheet / haptic / Dynamic Type）は最初から含める。**それ以外の盛り盛り機能（カメラスキャン / Watch / Widget / iCloud sync 等）は MVP 後に検討**。

---

## データモデル（SwiftData）

Web 側の SQL スキーマをそのまま反映。

```swift
@Model final class Card {
    @Attribute(.unique) var scryfallId: String   // "{uuid}:{finish}"
    var nameEn: String
    var nameJa: String?
    var setCode: String
    var collectorNumber: String
    var finish: String            // "nonfoil" / "foil" / "etched"
    var imageURL: URL?
    var oracleId: String
    var cachedAt: Date
    var legalities: String?       // JSON
    var lang: String?
    var frame: String?
    var borderColor: String?
    var frameEffects: String?     // JSON array
    var setType: String?
    var promoTypes: String?       // JSON array
}

@Model final class WishlistItem {
    var card: Card
    var formatTag: String?
    var conditionMin: String?     // "NM" / "EX" / "GD" / nil
    var targetPrice: Int?
    var notes: String?
    var qtyHave: Int = 0
    var qtyNeed: Int = 1
    var createdAt: Date
}

@Model final class PriceLog {
    var wishlistItem: WishlistItem
    var price: Int
    var shop: String              // "hareruya" / "bigmagic" / 等
    var conditionActual: String?
    var url: URL?
    var available: Bool
    var loggedAt: Date
}
```

---

## 実装フェーズ

> 進捗ステータスは `docs/RESUME.md` で常時最新化。本ドキュメントは設計の意図を残す。

### Phase 1: データ層

- SwiftData 上記 3 model 定義
- `ModelContainer` を App entry でセットアップ
- スクリーンショット用のシード data（Lightning Bolt M21 + Sol Ring CMR foil + 基本土地 SLD あたり）

### Phase 2: 一覧（read-only）

| Web 機能 | iOS 対応 |
|---|---|
| Format フィルタタブ | `Picker(.segmented)` または horizontal scroll の chip 群 |
| Format 別グループ化（standard / pioneer / modern…） | `Section` + `ForEach` |
| Card grid 2/3/4 列 | `LazyVGrid` with adaptive columns |
| 各 card: image / 名前 / 価格 / qty / set#cn | `WishlistCardView` (VStack + AsyncImage + Text) |
| Foil バッジ / Oil Slick / Surge Foil 等 | `FoilBadge` 共通コンポーネント |
| Sold out グレーアウト | `.opacity(0.6)` modifier |

### Phase 3: 追加（Scryfall 検索）

| Web 機能 | iOS 対応 |
|---|---|
| カード名検索 (JA/EN) | `TextField` + Scryfall API client |
| Set + collector pin 検索 | 上段の絞り込み入力 |
| Lang / Finish / Frame / Set フィルタ | filter pills |
| 検索結果 grid → 展開して target_price 等を入力 → 追加 | `Sheet` でモーダル展開 |
| Format 自動推定（legalities ベース） | Swift で `getDefaultFormatTag` 移植 |

### Phase 4: 編集 + 削除

| Web 機能 | iOS 対応 |
|---|---|
| Item 編集（format_tag / target_price / condition / notes / qty） | `EditView` (Form) → `NavigationLink` or `.sheet` |
| Inline qty edit (0..4 / 基本土地 1..30) | 一覧上で長押し or detail で `Picker` |
| 削除 | List の swipe action（左にスワイプ → Delete） |

### Phase 5: 価格ログ

Web 側は `src/app/item/[id]/log/` に実装済（過去 5 件表示 + 価格/店舗/condition/URL/在庫の記録フォーム）。
ウィッシュリストカードに表示される「最新価格・店舗・日付」もこの機能の出力。

| Web 機能 | iOS 対応 |
|---|---|
| `/item/[id]/log` ページ（過去ログ + 入力フォーム） | `PriceLogSheet`（item detail から `.sheet`） |
| 店舗 picker（hareruya/bigmagic/cardrush/surugaya/mercari/other） | `Picker(.segmented)` または `Menu` |
| 価格 / コンディション / URL / 在庫有無 | Form fields |
| 過去 5 件のログ一覧 | List of `PriceLogRow` cells |
| 最新ログを wishlist 一覧に表示 | Phase 2 のカードに価格バッジ追加 |

**方針**: まずは Web のフォームを literal に移植（A 案）。リリース後、iOS UX に合わせて再設計
（写真撮影で URL 自動取得、店頭スキャン、Haptic 等）を検討（C 案）。

### Phase 6: Import / Export

| Web 機能 | iOS 対応 |
|---|---|
| Arena txt エクスポート | UIActivityViewController（Share sheet） |
| バックアップ JSON エクスポート | 同上、.json 拡張子 |
| 取り込み（auto-detect） | `.fileImporter` (.txt / .json 両対応) |
| プレビュー（parse 成功数 / エラー件数） | Confirmation sheet |
| 重複スキップ（scryfall_id + format_tag） | Web と同ロジック移植 |

**注意**: JSON backup 形式は現在 `wishlist_items` のみで、`price_logs` は含めない設計
（Web 版も同じ）。これは「wishlist は意図、price_logs は観測」という関心の分離。
Web → iOS 間で price_logs を持ち越す必要が出たら、backup v2 で対応検討。

---

## OS 標準 iOS パターン（実装に含める）

- Pull-to-refresh（一覧再読込）
- Swipe-to-delete（一覧から削除）
- Share sheet（export 時の標準フロー）
- File picker（import 時の標準フロー）
- Haptic Feedback（追加完了・削除完了時）
- Dynamic Type（既に `Font.custom(_, relativeTo:)` で対応済）
- Sheet / NavigationStack（モーダル / 画面遷移）

これらは「iOS 独自盛り」ではなく **OS 標準の作法**。シンプル機能重視と矛盾しない。

---

## 棚上げ（あとで検討）

| 機能 | 検討タイミング |
|---|---|
| カメラスキャン（カード OCR で追加） | MVP 後 |
| Apple Watch 同伴アプリ | App Store ローンチ後の延長機能 |
| Widget / Live Activity / Lock Screen | 同上 |
| iCloud Sync（複数 iOS 間でのデータ同期） | 同上、CloudKit 統合 |
| Push 通知（価格下落アラート等） | 価格データソース確保後 |
| 共有レイヤー（ウィッシュリストを友達に共有） | 認証システム導入と同時期 |

---

## ブランチ運用

- `main`: 安定版
- `docs/*`: ドキュメント追加・更新
- `feature/phase-N-*`: 各 Phase の実装
- Web 側のポリシー（main only → Vercel 自動デプロイ）と違って、iOS は App Store 経由なので緩く運用可。各 phase 終わりに main へ merge

---

## 次のアクション

1. このプランをレビューしてもらう
2. OK ならこのドキュメントを main に merge
3. Phase 1 ブランチ `feature/phase-1-data-model` を切って実装開始

## ブラッシュアップ予定（MVP 後の v0.2 以降）

- 価格ログの UX 再設計（写真スキャン、Haptic、店頭利用に最適化）
- カメラスキャン（カード OCR で追加）
- 上記まで一通り Web に逆輸入する選択肢の検討
