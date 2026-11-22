# 構図カメラ（composition-grid-cam）

画家のための構図と水平のためのファインダー。

- Bundle ID: `com.shodai4.compositiongridcam`
- 表示名: 構図カメラ
- 対応: iPhone / iOS 17.0 以上 / 縦向き
- 依存: Google Mobile Ads 13.x（Swift Package）

## できること

- 構図線: 三分割 / 黄金比 / 対角線 / 水平線 / フィボナッチ黄金螺旋
- 黄金螺旋は 4 方向の回転と左右反転に対応（無料で使える）
- 線の色（白・黒・赤・シアン）、太さ（0.5 / 1.0 / 2.0 pt）、濃さ（35 / 60 / 90 %）
- キャンバス号数の枠: 1:1、F3〜F12、P3〜P10、M3〜M10、S6
- 水準器: 傾き（水平）と仰角を 0.1 度単位で表示。水平に入ると錆青と触覚で知らせる
- 停止（フリーズ）と、構図線あり／なしを選べる写真への保存

## 画面の作り

```
VStack
 ├ ファインダー      AVCaptureVideoPreviewLayer（videoGravity = .resizeAspect）
 │                   ＋ SwiftUI.Canvas の構図線（同じ矩形になるよう同じ式で割り付ける）
 ├ 操作帯            墨 #1A1A1B 90% の半透明。文字と数値だけ
 └ 広告              最下部の独立した帯（Pro 購入後は消える）
```

色は墨 `#1A1A1B`、文字と線はアイボリー `#F9F8F5`、合図だけ錆青 `#4A6A7A`。
数値は `.monospaced`。絵文字・英字の補足・原色のボタンは使わない。

## 中の構成

| 場所 | 役割 |
| --- | --- |
| `Sources/Models/PreviewGeometry.swift` | 映像と枠の割り付け、保存の切り取り |
| `Sources/Models/GridGeometry.swift` | 三分割・黄金比・対角線・水平線・黄金螺旋の座標 |
| `Sources/Models/LevelMath.swift` | 重力ベクトルから傾き・仰角・泡の位置 |
| `Sources/Models/CanvasPreset.swift` | 号数（JIS 呼び寸法の mm） |
| `Sources/Services/CameraController.swift` | カメラ、直近の 1 枚の保持 |
| `Sources/Services/MotionController.swift` | deviceMotion 30 回/秒の水準器 |
| `Sources/Services/ExportRenderer.swift` | 枠で切り取り、構図線を焼き込む |
| `Sources/Services/PhotoSaver.swift` | 写真への追加（`.addOnly`） |
| `Sources/Views/*` | ファインダー・構図線・操作帯・バナー |
| `Sources/Store/ProStore.swift` | StoreKit 2（`com.shodai4.compositiongridcam.pro`） |

## 手元での点検

```sh
python3 scripts/verify-logic.py     # 計算の自己点検（760 件あまり）
python3 scripts/check-syntax.py     # Swift の構文点検（tree-sitter）
python3 scripts/generate_icon.py    # アイコンを作り直す（1024×1024・RGB）
```

`scripts/geometry.py` は Swift 側と同じ式を Python に写したもの。画面と保存画像の
割り付けは、この 1 か所の式から両方を作る。

## CI（GitHub Actions）

`ci/ios-build.yml` を `.github/workflows/ios-build.yml` に置くと、`main` への push で
`test` → `build` → `testflight` の 3 ジョブが順に走る。必要な Secrets は次の 4 つ。

| Secret | 内容 |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API キーの Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | AuthKey_\*.p8 の中身 |
| `APPLE_TEAM_ID` | チーム ID（86WNUS2875） |

署名は、署名なしのアーカイブ → 埋め込み `Frameworks/*` へ ad-hoc 仮署名 →
`-exportArchive`（クラウド署名）→ `xcrun altool --upload-app` の順で通す。
