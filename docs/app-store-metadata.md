# App Store 提出用メタデータ — 構図カメラ

App Store Connect にそのまま貼れる形でまとめた。字数は実測値（全角1文字＝1文字で計算）。
最終更新 2026-11-23 ／ 対象バージョン 1.0（ビルド番号は CI の `github.run_number`）。

## 1. 基本情報

| 項目 | 値 |
| --- | --- |
| ホーム画面の表示名 | 構図カメラ |
| App Store のアプリ名 | 構図カメラ（5文字／上限30） |
| Bundle ID | `com.shodai4.compositiongridcam` |
| App Store Connect の Apple ID | 6837956213 |
| バージョン | 1.0 |
| 対応 | iPhone（iOS 17.0 以上）・縦向きのみ・iPad 非対応 |
| 価格 | 無料（広告あり） |
| アプリ内課金 | 広告非表示の買い切り `com.shodai4.compositiongridcam.pro`（コード側は実装済み・App Store Connect への商品登録は未了） |
| 対応言語 | 日本語のみ |
| カテゴリ | プライマリ：写真＆ビデオ ／ セカンダリ：グラフィック＆デザイン |
| 年齢制限 | 4+（全年齢） |
| 端末の許可 | カメラ（`NSCameraUsageDescription`）／写真への追加のみ（`NSPhotoLibraryAddUsageDescription`）／端末の姿勢センサー（許可ダイアログなし） |

## 2. App Store に貼るテキスト

### アプリ名（30文字以内）
```
構図カメラ
```

### サブタイトル（30文字以内）
```
構図と水平を撮る前に確かめる
```
（14文字）

### プロモーションテキスト（170文字以内・審査なしで更新できる）
```
三分割・黄金比・対角線・水平線・黄金螺旋を重ね、水準器で傾きまで確かめてから撮れる、画家のためのファインダー。構図線あり／なしを選んで保存できます。
```
（74文字）

### 概要（4000文字以内）
```
画家のための、構図と水平のためのファインダーです。

■ 5つの構図線
三分割・黄金比・対角線・水平線・フィボナッチ黄金螺旋。黄金螺旋は4方向の回転と左右反転に対応しています。線は重ねずに1本ずつ選ぶので、構図の意図がぶれません。

■ 線の見え方を変える
色（白・黒・赤・シアン）、太さ（0.5／1.0／2.0pt）、濃さ（35／60／90%）を、モチーフに合わせて変えられます。

■ キャンバスの枠
1:1、F3〜F12、P3〜P10、M3〜M10、S6 の号数の枠を重ねれば、描く画面の比率で構図を決められます。

■ 水準器
傾きと仰角を 0.1 度単位で表示します。水平に入ると色と触覚で知らせます。

■ 停止して保存
構図を決めたら停止（フリーズ）して、構図線あり／なしを選んで写真に保存できます。保存されるのは、選んだ号数の枠で切り取った範囲です。

■ 端末のなかだけで
映像と姿勢の値は、端末のなかだけで扱います。外部へ送ることはありません（通信は広告の読み込みのみ）。

※ iPhone（iOS 17.0 以上）・縦向き。
```
（474文字）

### キーワード（100文字以内・カンマ区切り・スペースなし）
```
構図,デッサン,黄金比,三分割,水準器,絵画,スケッチ,ファインダー,下描き,アトリエ
```
（43文字）

キーワードの考え方：アプリ名とサブタイトルに入っている語（構図カメラ／構図と水平を撮る前に確かめる）は重複しても検索対象になるため、ここでは**入っていない語**を優先した。「構図」「黄金比」「三分割」「水準器」を軸に、下描き・ファインダーの語を足した。

## 3. URL

| 項目 | URL |
| --- | --- |
| サポートURL（必須） | https://shodai4.com/apps/composition-grid-cam/support.html |
| プライバシーポリシーURL（必須） | https://shodai4.com/apps/composition-grid-cam/privacy.html |
| マーケティングURL（任意） | https://shodai4.com/apps/composition-grid-cam/ |
| サポートの入口（アプリのページ） | https://shodai4.com/apps/composition-grid-cam/ |

3つとも公開済み（2026-11-23 に 200 OK を確認）。

## 4. 年齢制限（App の年齢制限）

- 全年齢（4+）。暴力・性的表現・ギャンブル・ホラー・医薬品・ユーザー生成コンテンツ・位置情報の共有はいずれも「なし」。
- 広告は画面下部の独立した帯に Google AdMob のバナーを表示する（内容は Google の広告ネットワークの審査を通ったもの）。

カメラと姿勢センサーを使うが、映像・姿勢の値を保存・送信しない。

## 5. App のプライバシー（栄養ラベル）

アプリ本体は何も収集しない。広告SDK（Google Mobile Ads）分だけを、サードパーティの広告目的として申告する。

| データの種類 | 収集 | 使途 | トラッキング |
| --- | --- | --- | --- |
| 識別子（端末ID） | する（Google Mobile Ads SDK） | サードパーティの広告 | しない |
| 使用状況データ（広告の表示・反応） | する（Google Mobile Ads SDK） | サードパーティの広告 | しない |
| ユーザーのコンテンツ（写真） | しない | 端末内のみ | — |
| 位置情報 | しない | — | — |
| 診断 | しない | — | — |

- 「トラッキング」はすべて**しない**（ATT を要求しておらず、`PrivacyInfo.xcprivacy` も `NSPrivacyTracking=false`）。App Store Connect では「データをトラッキングに使用していますか」に **いいえ**。
- 提出前に Google の開示（<https://policies.google.com/technologies/partner-sites>）と AdMob SDK のデータ開示を照合し、過不足がないか最終確認する。

## 6. App Review 担当者向けメモ（Review Notes）

英日どちらも貼れるようにしてある。ASC の Review Notes は英語を推奨。

### English

```
No account or sign-in is required. The camera feed is used for the live viewfinder and for saving a still with the composition lines burned in. Still images are saved with add-only photo access (NSPhotoLibraryAddUsageDescription); the app never reads the photo library. Device motion is used only for the level indicator and is not stored.

Everything runs on the device; the app works offline except for the Google Mobile Ads banner. No App Tracking Transparency request; the privacy manifest declares no tracking.

To reach the core feature: launch the app, choose a composition line in the strip (三分割/黄金比/対角線/水平線/黄金螺旋), tilt the phone to see the level readout, then 保存 (choose 構図線あり or なし).
```

### 日本語（控え）

```
ログイン不要。カメラはファインダーと構図線入りの保存にだけ使用。保存は「追加のみ」の権限で、ライブラリの読み取りはしません。姿勢センサーは水準器の表示のみに使用し保存しません。通信は広告のみ、ATTは要求せず。
```

## 7. スクリーンショット

- 必須：iPhone 6.9インチ（1290×2796px または 1320×2868px）。3〜10枚。
- 任意：iPhone 6.5インチ（1284×2778px）。iPad は非対応なので不要。
- 1枚目でアプリの核心が分かる画面を出す（起動 → 構図線を選ぶ → 水準器を確認 → 「保存」（構図線あり／なし））。
- 端末の枠やキャプションを載せる場合も、実際のアプリ画面をそのまま使う（合成した偽のUIは不可）。
- 撮影は実機または iOS 17 以降のシミュレータ。カメラの映像はシミュレータでは出ないため、スクリーンショットは実機で撮る。構図線の違いが分かる2〜3枚を用意する。

## 8. 提出前チェックリスト

- [ ] App Store Connect にアプリレコードがある（Apple ID 6837956213）／Bundle ID `com.shodai4.compositiongridcam`
- [ ] バージョン 1.0 に、CI がアップロードしたビルドを選択
- [ ] サポートURL・プライバシーポリシーURL が 200 で開く
- [ ] 「App のプライバシー」を第5節のとおり入力
- [ ] 年齢制限を 4+ に設定
- [ ] カテゴリを第1節のとおり設定
- [ ] スクリーンショットを 6.9インチで3枚以上
- [ ] 広告の本番IDへの差し替え（下記「未対応」を参照）
- [ ] アプリ内課金を出す場合は商品登録と審査提出、出さない場合は導線が「準備中」で押せないことを確認
- [ ] 輸出コンプライアンス：`ITSAppUsesNonExemptEncryption=false` 済み（追加質問なし）
- [ ] 審査用の連絡先メールと電話を記入

## 9. 未対応・提出前に判断がいること

1. **広告IDが Google のテスト用IDのまま**（`Sources/Views/BannerAdView.swift` の `adUnitID` と `Info.plist` の `GADApplicationIdentifier` が `ca-app-pub-3940256099942544` 系）。このまま審査に出すと広告はテスト広告のままで、収益も出ない。本番のアプリID・ユニットIDへ差し替えるか、いったん広告を外して出すかを決める。差し替えは Swift 側の変更なので、このタスクでは触っていない。
2. **アプリ内課金（広告非表示）が ASC 未登録**。商品を作らないまま提出すると、アプリ内の「広告を消す」が「準備中」で押せない状態になる。審査で「機能していない課金導線」と見られる可能性があるため、商品登録して提出するか、導線ごと外すかを決める。
3. **6本同時提出のスパム判定（ガイドライン4.3）**。同じ開発者から同じ分野のアプリをまとめて出すため、機能の違いが伝わるよう、概要とレビューメモで「何をするアプリか」を明確にしている。スクリーンショットもアプリごとに別の画面にすること。
4. **`PrivacyInfo.xcprivacy` は同梱済み**（追跡なし・UserDefaults の利用理由 CA92.1）。

## 10. 審査で聞かれやすい点と回答

| 想定される指摘 | 回答 |
| --- | --- |
| カメラ／写真を何に使うのか | ファインダーの表示と、構図線を焼き込んだ写真の保存のため。 |
| 通信はあるのか | 広告の読み込みのみ。映像・姿勢の値は送らない。 |
| 広告はどこから出ているのか | 画面下部の独立した帯の AdMob バナー。 |
| データはどこに保存されるのか | 端末内のみ。アプリ内に残るのは購入状態だけ。 |
| 似たアプリが複数ある（4.3） | それぞれ目的が異なる（明暗を見る／配色を逆算する／額装を確かめる／構図を決める／号数と送料を調べる／乾燥日数を見積もる）。画面構成もデータも別で、共通のコードベースは使っていない。 |
