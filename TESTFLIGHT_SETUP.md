# TestFlight配布セットアップガイド

このガイドでは、SoundscapeArchiveアプリをTestFlightで配布するための設定手順を説明します。

## 前提条件

1. **Apple Developer Program**への登録（年額99 USD）
2. **App Store Connect**へのアクセス
3. **GitHub リポジトリ**の管理者権限

## セットアップ手順

### 1. Apple Developer Programへの登録

1. [Apple Developer Program](https://developer.apple.com/programs/)にアクセス
2. 「Enroll」をクリックして登録手続きを完了
3. 登録完了後、証明書とプロファイルが作成可能になります

### 2. App Store Connectでのアプリ作成

1. [App Store Connect](https://appstoreconnect.apple.com/)にログイン
2. 「マイApp」→「新規App」をクリック
3. 以下の情報を入力：
   - **プラットフォーム**: iOS
   - **名前**: SoundscapeArchive
   - **プライマリ言語**: 日本語
   - **バンドルID**: com.yourcompany.soundscape-archive
   - **SKU**: soundscape-archive

### 3. 証明書とプロビジョニングプロファイルの作成

#### 方法A: Fastlane Match（推奨）

```bash
# matchの初期化
fastlane match init

# App Store用証明書の作成
fastlane match appstore
```

#### 方法B: 手動作成

1. [Apple Developer](https://developer.apple.com/account/)の「Certificates, Identifiers & Profiles」
2. 「Certificates」で Distribution証明書を作成
3. 「Identifiers」でApp IDを作成（Bundle ID: com.yourcompany.soundscape-archive）
4. 「Profiles」でApp Store用プロビジョニングプロファイルを作成

### 4. App Store Connect API Keyの作成

1. [App Store Connect](https://appstoreconnect.apple.com/access/api)の「ユーザとアクセス」→「キー」
2. 「APIキーを生成」をクリック
3. 名前を入力し、「アクセス」で「App Manager」以上を選択
4. ダウンロードした.p8ファイルを安全に保管
5. 以下の情報をメモ：
   - **Issuer ID**
   - **Key ID**
   - **API Key（.p8ファイルの内容）**

### 5. GitHub Secretsの設定

リポジトリの Settings → Secrets and variables → Actions で以下を設定：

| Secret名 | 説明 |
|----------|------|
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | API KeyのKey ID |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | API KeyのIssuer ID |
| `APP_STORE_CONNECT_API_KEY_KEY` | .p8ファイルの内容（Base64エンコード） |
| `MATCH_GIT_URL` | Match用の証明書リポジトリURL |
| `MATCH_PASSWORD` | Match暗号化パスワード |
| `APP_IDENTIFIER` | アプリのBundle ID |
| `TEAM_ID` | Apple Developer Team ID |

### 6. Firebase設定ファイルの追加

1. [Firebase Console](https://console.firebase.google.com/)からGoogleService-Info.plistをダウンロード
2. リポジトリのSecretsに`GOOGLE_SERVICE_INFO_PLIST`としてBase64エンコードして追加

### 7. GitHub Actionsワークフローの更新

`.github/workflows/build.yml`のarchiveジョブを以下のように更新：

```yaml
archive:
  name: Deploy to TestFlight
  runs-on: macos-14
  needs: build
  if: github.ref == 'refs/heads/main'

  steps:
    - uses: actions/checkout@v4

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.4.app

    - name: Install dependencies
      run: |
        brew install xcodegen
        gem install fastlane

    - name: Generate Xcode project
      run: xcodegen generate

    - name: Setup Firebase config
      run: |
        echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" | base64 -d > SoundscapeArchive/GoogleService-Info.plist

    - name: Setup App Store Connect API Key
      run: |
        mkdir -p ~/.appstoreconnect/private_keys
        echo "${{ secrets.APP_STORE_CONNECT_API_KEY_KEY }}" | base64 -d > ~/.appstoreconnect/private_keys/AuthKey_${{ secrets.APP_STORE_CONNECT_API_KEY_KEY_ID }}.p8

    - name: Deploy to TestFlight
      env:
        APP_STORE_CONNECT_API_KEY_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_KEY_ID }}
        APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ISSUER_ID }}
        MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
        MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        APP_IDENTIFIER: ${{ secrets.APP_IDENTIFIER }}
        TEAM_ID: ${{ secrets.TEAM_ID }}
      run: |
        fastlane beta
```

## ローカルでの配布（手動）

1. Xcodeでプロジェクトを開く
2. Product → Archive
3. Organizer → Distribute App → App Store Connect
4. Upload → 完了

## トラブルシューティング

### 証明書エラー

```bash
# 証明書の確認
security find-identity -v -p codesigning

# キーチェーンのロック解除
security unlock-keychain -p PASSWORD login.keychain
```

### プロビジョニングプロファイルエラー

1. Xcode → Preferences → Accounts → Download Manual Profiles
2. または Fastlane match で再同期

### ビルドエラー

```bash
# クリーンビルド
xcodebuild clean -project SoundscapeArchive.xcodeproj -scheme SoundscapeArchive

# キャッシュクリア
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## 参考リンク

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
