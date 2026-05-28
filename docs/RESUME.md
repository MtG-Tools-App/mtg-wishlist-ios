# RESUME — Fresh Claude Code セッション用ブートストラップ

このドキュメントは「新しい Claude Code セッションが、何が出来ていて、次に何をやるか」を
5 分以内で把握するためのもの。設計詳細は `docs/PORT-PLAN.md` を参照。

---

## tl;dr

- **何**: Web 版 MtG Wishlist (Next.js + Turso) の iOS ネイティブ移植
- **方針**: 構造とふるまいを Web から literal port、見た目は iOS spec で再構築
  （明朝 / クリーム / Liquid Glass）
- **データ**: SwiftData ローカル独立。Web ⇄ iOS の橋は JSON backup 形式（v1）
- **対象**: iOS 26+、iPhone のみ、portrait のみ、シングルユーザー
- **状態**: Phase 0〜4 完了（CRUD 揃い）/ Phase 5〜6 未着手

---

## Phase 進捗

| # | タイトル | 状態 | 主要成果物 |
|---|---|---|---|
| 0 | Scaffold | ✓ | XcodeGen 構成、フォント 5 個、カラートークン 11 個、StyleGuide |
| 1 | SwiftData モデル | ✓ | Card / WishlistItem / PriceLog @Model、ModelContainer 統合 |
| 2 | ウィッシュリスト一覧 (read-only) | ✓ | WishlistView (Vidaloka ヒーロー + format 別 grid)、FoilBadge |
| 3 | 追加（Scryfall 検索） | ✓ | ScryfallClient (actor)、AddCardView + AddCardForm、Upsert |
| 4 | 編集 + 削除 | ✓ | EditItemView、NavigationLink + 長押し contextMenu |
| 5 | 価格ログ | ⏳ | PriceLog model は Phase 1 で作成済、UI 未着手 |
| 6 | Import / Export | ⏳ | Arena txt + JSON backup（Web 側で確定した v1 仕様を流用） |

---

## How to Resume — 環境確認

ワーキングツリーは main, クリーン想定：

```bash
cd ~/Desktop/mtg_wishlist_ios
git status                  # → "nothing to commit"
git log --oneline -8        # 最新コミットを確認
git branch -a               # main + feature/phase-* + docs/port-plan
```

ビルド確認（iPhone 17 Pro Sim, iOS 26.5）：

```bash
cd ~/Desktop/mtg_wishlist_ios
xcodegen generate           # .xcodeproj は gitignore、project.yml が source of truth
xcodebuild \
  -project MtGWishlist.xcodeproj \
  -scheme MtGWishlist \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -configuration Debug build
```

シミュレータに流す：

```bash
SIM_ID=99102E1E-0A7E-459A-8EA9-541F0B24E69C   # iPhone 17 Pro
APP_PATH="/Users/akitomotakahashi/Library/Developer/Xcode/DerivedData/MtGWishlist-ciwjlbxpisgbazgkitqvmadbhtip/Build/Products/Debug-iphonesimulator/MtG Wishlist.app"

xcrun simctl terminate "$SIM_ID" com.mtgtools.wishlist
xcrun simctl uninstall  "$SIM_ID" com.mtgtools.wishlist
xcrun simctl install    "$SIM_ID" "$APP_PATH"
xcrun simctl launch     "$SIM_ID" com.mtgtools.wishlist
xcrun simctl io         "$SIM_ID" screenshot /tmp/sim.png
```

### 開発時用 launch arg

タップ操作なしで状態を組めるよう、起動引数でショートカット：

| 引数 | 効果 |
|---|---|
| `--seed-samples` | 起動時に 5 件のサンプル wishlist 挿入（store が空のときのみ） |
| `--open-add-card` | AddCardView (sheet) を即提示 |
| `--auto-search=<term>` | AddCardView 内で `<term>` の検索を自動実行 |
| `--open-edit-first` | 先頭アイテムの EditItemView を即 push |

例: `xcrun simctl launch "$SIM_ID" com.mtgtools.wishlist --seed-samples --open-edit-first`

スクショは `/tmp/mtg_ios_screenshots/` に貯まっています（過去分: empty / populated / search / edit）。

---

## アーキテクチャ (file tree)

```
MtGWishlist/
├── Assets.xcassets/                # 11 colorset (bgCanvas..destructive) + AppIcon
├── Resources/Fonts/                # NotoSerifJP × 3 (Regular/Medium/SemiBold)
│                                   #   + Oranienbaum + Vidaloka
└── Sources/
    ├── MtGWishlistApp.swift        # @main + ModelContainer(for: [Card, WishlistItem, PriceLog])
    ├── FontInventory.swift         # 起動時 PostScript 名 dump + verify
    ├── AppColor.swift              # Color.bgCanvas 等の型安全アクセサ
    ├── AppFont.swift               # appTitle/appBody/etc + latinDisplay A/B
    │
    ├── DebugViews/
    │   └── StyleGuideView.swift    # 元 ContentView。デザイントークン検証
    │
    ├── Models/
    │   ├── Card.swift                  # @Model (scryfall_id 主、@Attribute(.unique) 不採用)
    │   ├── WishlistItem.swift          # @Model (Card への mandatory to-one)
    │   ├── PriceLog.swift              # @Model (WishlistItem への optional 逆参照)
    │   ├── Enums.swift                 # CardFinish / CardCondition / PriceLogShop
    │   ├── BasicLand.swift             # qtyHaveOptionsFor / qtyNeedOptionsFor
    │   ├── Format.swift                # FormatTag enum
    │   ├── Format+Legalities.swift     # getDefaultFormatTag / getFormatOptions
    │   ├── FrameFilter.swift           # isSpecialPrint + Lang/Finish/Frame filter enums
    │   ├── FinishHelpers.swift         # finishLabel / hasFoilBadge (Oil Slick 等判定)
    │   ├── Card+Upsert.swift           # INSERT...ON CONFLICT 等価 helper
    │   └── SeedData.swift              # 実 Scryfall データ 5 件 (Lightning Bolt 等)
    │
    ├── Scryfall/
    │   ├── ScryfallTypes.swift         # Decodable subset (Card / SearchResponse / Error)
    │   ├── NormalizedCard.swift        # in-memory struct + normalize() 関数
    │   └── ScryfallClient.swift        # actor: rate 200ms / 429 retry / JA two-step
    │
    └── Views/
        ├── WishlistView.swift          # root: heroHeader + filter + grouped grid
        ├── WishlistCardView.swift      # 個別カード + tap NavLink + contextMenu delete
        ├── FormatFilterTabs.swift      # All/8 format の上部 chip
        ├── FoilBadge.swift             # 9pt outlined pill
        ├── AddCardView.swift           # 検索 + 3 段フィルタ + 結果 grid
        ├── SearchResultCard.swift      # 検索結果セル
        ├── AddCardForm.swift           # 検索結果 tap 後の追加フォーム
        ├── EditItemView.swift          # 編集 + 削除フォーム
        └── FilterChipRow.swift         # generic な横スクロール pill 行
```

---

## 残タスク

### Phase 5: 価格ログ

**Web 側参照**: `src/app/item/[id]/log/page.tsx` + `LogForm.tsx` + `src/lib/actions/priceLogs.ts`

**iOS 側で作る物**:
1. `PriceLogView` — 過去 5 件リスト + 入力フォーム（sheet として EditItemView から開く想定）
2. EditItemView に「価格を記録」ボタン追加して PriceLogView を提示
3. WishlistCardView に「最新ログ」表示の小さい行を追加（model 側の `latestPriceLog` を使用）
4. 店舗 picker（晴れる屋 / BIG MAGIC / カードラッシュ / 駿河屋 / メルカリ / その他）—
   `PriceLogShop` enum + displayName は Phase 1 で実装済
5. フィールド: 価格 (¥) / コンディション (NM/EX/GD) / URL / 在庫有無

**コスト**: 1 commit、3〜4 ファイル、~半日

### Phase 6: Import / Export

**Web 側参照**:
- `src/lib/actions/export.ts` — Arena 形式 txt + JSON backup
- `src/lib/actions/import.ts` — auto-detect + dedupe
- `src/lib/import/parse.ts` + `parse-backup.ts` + `resolve.ts`
- `src/components/ImportModal.tsx`

**iOS 側で作る物**:
1. **Export**:
   - Arena txt エクスポータ（`<qty> <name> (<SET>) <cn>[ *F*]`）
   - JSON backup エクスポータ（`{version:1, exported_at, items:[...]}`、1 行/アイテム）
   - 出力先: `UIActivityViewController` 経由の share sheet
2. **Import**:
   - Arena 形式パーサ（regex）
   - JSON backup パーサ（Codable）
   - Auto-detect: 先頭文字が `{` → JSON、それ以外 → Arena
   - Scryfall `/cards/collection` bulk endpoint（75 ids/req）で解決
   - 重複判定: `(scryfall_id, format_tag)` でスキップ
   - 入力 UI: `.fileImporter` (.txt / .json) + textarea
3. **重要**: JSON backup スキーマは Web 側で v1 固定済（PORT-PLAN.md 参照）
   - 入る項目: set, collector_number, finish, name_en, format_tag, target_price,
     condition_min, notes, qty_have, qty_need
   - 入らない項目: price_logs（「wishlist = 意図、price_logs = 観測」の関心分離）

**コスト**: 1〜2 commit、6〜8 ファイル、~1 日

---

## 既知の未解決事項

| 事項 | 詳細 |
|---|---|
| JA strict match 緩さ | Scryfall の `lang:ja !"稲妻"` で「稲妻の連撃」等が混入。Web も同挙動。client-side post-filter で改善可能（v0.2 候補） |
| AsyncImage キャッシュ | 同じ画像を二度フェッチする場合がある。`URLCache.shared` チューニングで改善可（v0.2） |
| 検索レイテンシ | 基本土地クエリは 6 秒前後。pagination depth の代償（dir=desc + MAX_PAGES=30） |
| iCloud sync | 後回し（PORT-PLAN.md 棚上げ） |
| カメラスキャン | 後回し（ユーザー指示で MVP 外） |
| Sol Ring (Other) が wishlist のスクショで見えない | フィルタ ALL 時、画面下にスクロールすると出る。バグではない |

---

## デザイン判断ログ（次の Claude が同じ罠を踏まないように）

| 判断 | 理由 |
|---|---|
| SwiftData 採用（Core Data / SQLite ではなく） | iOS 17+ 専用なので問題なし、macro でボイラープレート減 |
| `@Attribute(.unique)` を Card.scryfallId に**付けない** | Core Data 制約: unique + mandatory inverse 関係がある場合、削除規則を cascade にしないと "Cannot use uniqueness constraints" エラー。cascade だとカードキャッシュ削除で wishlist が消える破壊的挙動になる。Web の `INSERT...ON CONFLICT` と同じく app 層 (Card.upsert helper) で一意性管理 |
| XcodeGen 導入 | project.yml が source of truth、.xcodeproj は gitignore。GUI 操作なしで完結 |
| ナビバー title 不使用、自前 Vidaloka ヒーローをスクロール内に | `.navigationTitle()` は San Francisco フォント固定で AppFont を当てられない |
| Scryfall 検索 `dir=desc` + MAX_PAGES=30 | 新しい順 page 1 に THB Nyxtouched / SLD / Oil Slick を集約、page 末尾で Alpha も拾える |
| EditItemView の編集はローカル `@State` バッファ | Web の form-submit パターンに合わせて、戻るキャンセル相当の挙動を保証 |
| LazyVGrid に swipe-to-delete ではなく長押し contextMenu | `swipeActions` は List 専用。grid なら長押しが native パターン |
| Latin display = `.vidaloka`（`.oranienbaum` 候補） | より modern。`AppFont.latinDisplay` の 1 行変更で A/B 可能 |
| Backup JSON に price_logs を**含めない** | wishlist は意図、price_logs は観測、関心の分離 |
| iOS は dev only 起動引数で開発時 UX を組む | --seed-samples / --open-add-card / --auto-search= / --open-edit-first 等 |

---

## Web 側リファレンス

```
~/Desktop/mtg_wishlist/                  # Web 版（凍結済み参照用）
├── src/app/
│   ├── page.tsx                         # / wishlist
│   ├── add/AddPageClient.tsx            # /add
│   └── item/[id]/
│       ├── edit/EditForm.tsx            # /item/N/edit  ← Phase 4 で移植済
│       └── log/                         # /item/N/log   ← Phase 5 で移植する
│           ├── page.tsx
│           └── LogForm.tsx
├── src/lib/
│   ├── actions/
│   │   ├── cards.ts                     # ← Phase 3 で移植済
│   │   ├── wishlist.ts                  # ← Phase 4 で移植済
│   │   ├── priceLogs.ts                 # ← Phase 5 で移植する
│   │   ├── export.ts                    # ← Phase 6 で移植する
│   │   └── import.ts                    # ← Phase 6 で移植する
│   ├── format/
│   │   ├── formats.ts                   # ← Phase 2 で移植済
│   │   ├── finish.ts                    # ← Phase 2 で移植済
│   │   ├── basicLand.ts                 # ← Phase 3 で移植済
│   │   └── wisdomGuild.ts               # ← まだ移植してない (任意)
│   ├── import/                          # ← Phase 6 で移植する
│   └── scryfall/                        # ← Phase 3 で移植済
└── ...
```

**Web 側のフリーズ範囲**: 視覚デザイン（V3 UI）は凍結。機能追加は引き続き可能だが、
本プロジェクトの優先度は iOS 側の機能パリティ追従。

---

## ブランチ運用

- `main`: 各 phase 完了後の合流先
- `feature/phase-N-*`: phase ごとの実装ブランチ。完了したら fast-forward merge
- `docs/*`: ドキュメント単独更新
- 個人開発なので PR レビュー不要、main 直 merge

---

## 規約

- UI 文字列はすべて日本語
- コードコメント / SwiftDoc は英語
- 色は必ず `Color.bgCanvas` 等のトークン経由（ハードコード禁止）
- フォントは必ず `AppFont.appBody()` 等経由（ハードコード禁止）
- 各 phase 完了時にシミュレータスクショ確認
- commit メッセージは bilingual OK（JA メイン、技術タームは EN）
