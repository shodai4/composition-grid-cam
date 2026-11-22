# GitHub Actions の定義（未設置）

`.github/workflows/` へ置くと動く。このリポジトリへの push では、GitHub App に
`workflows` 権限がないため `.github/workflows/*.yml` を含められず、ここに退避している。

```sh
mkdir -p .github/workflows
cp ci/ios-build.yml .github/workflows/
git add .github/workflows && git commit -m "CI を設置" && git push
```

`ios-build.yml` は 3 つのジョブを順に走らせる。

| ジョブ | 環境 | 内容 |
| --- | --- | --- |
| `test` | ubuntu-latest | `verify-logic.py`（計算）と `check-syntax.py`（構文） |
| `build` | macos-26 | XcodeGen ＋ SPM 解決 ＋ 署名なしビルド |
| `testflight` | macos-26 | アーカイブ → 仮署名 → 書き出し → TestFlight へアップロード |

必要なリポジトリ Secrets:

| Secret | 内容 |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API キーの Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | AuthKey_\*.p8 の中身 |
| `APPLE_TEAM_ID` | チーム ID（86WNUS2875） |
