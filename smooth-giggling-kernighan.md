# SoundscapeArchive iOS App 仕様書

## 概要

既存のSoundscapeArchiveシステム（Python/FastAPI）の機能をiOSネイティブアプリとして実装するための仕様書です。

**技術スタック**: SwiftUI + Swift
**バックエンド**: Firebase (Firestore + Storage + Auth)
**オフライン対応**: 必須（ローカルファースト設計）
**対象OS**: iOS 17.0+

---

## 1. アプリ概要

### 1.1 目的

環境音（サウンドスケープ）を録音・保存・分析し、ISO/TS 12913-2に準拠した主観評価を行うモバイルアプリケーション。フィールドワークでの音環境調査を効率化し、オフライン環境でも完全動作を保証。

### 1.2 対象ユーザー

- 音響環境研究者・学生
- 都市計画・環境アセスメント担当者
- サウンドスケープ調査フィールドワーカー

### 1.3 主要機能

| 機能 | 説明 |
|------|------|
| 録音 | 44.1kHz/16bit WAV形式、GPS位置情報自動取得、リアルタイムレベルメーター |
| ライブラリ | 一覧表示、検索・フィルタ、波形付き再生、地図表示 |
| PAQ評価 | ISO/TS 12913-2準拠の8項目5段階評価 + 音源知覚4カテゴリ |
| 同期 | オフライン優先保存、オンライン時自動同期、コンフリクト解決 |

---

## 2. 画面設計

### 2.1 画面遷移

```
[LaunchScreen]
       ↓
[AuthenticationView]
       ↓
[MainTabView]
  ├── Tab 1: RecordingView → RecordingMetadataEditView
  ├── Tab 2: LibraryView → RecordDetailView → EvaluationInputView
  ├── Tab 3: InsightsView (CircumplexChart, Statistics)
  └── Tab 4: SettingsView
```

### 2.2 各画面詳細

#### RecordingView（録音画面）
- VUメーター（-60dB〜0dB）
- 録音ボタン（赤/白切り替え）
- 経過時間表示
- 波形プレビュー
- GPS状態インジケーター

#### RecordingMetadataEditView（メタデータ編集）
- タイトル（必須、最大200文字）
- 説明文（最大2000文字）
- 場所名、タグ、天気、気温
- 機材情報入力
- 波形プレビュー表示

#### LibraryView（ライブラリ）
- 検索バー + フィルターボタン
- リスト/グリッド/マップ切り替え
- 録音一覧（サムネイル、タイトル、日時、LAeq、同期状態）

#### RecordDetailView（詳細画面）
- 波形プレーヤー
- LAeq・統計値表示
- オクターブバンドスペクトルグラフ
- 評価サマリー・入力ボタン

#### EvaluationInputView（PAQ評価入力）
- PAQ 8項目（1-5段階）: Pleasant, Chaotic, Vibrant, Uneventful, Calm, Annoying, Eventful, Monotonous
- 適切さ評価（0-10スライダー）
- 音源知覚4カテゴリ（0-10）: Traffic, Other, Human, Natural
- 自由記述
- リアルタイムCircumplexプレビュー

#### InsightsView（分析画面）
- Circumplexチャート（全評価プロット）
- Quadrant分布円グラフ
- 統計サマリー

---

## 3. データモデル（Swift）

### 3.1 主要構造体

```swift
// 位置情報
struct GeoLocation: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let accuracy: Double?
}

// 機材情報
struct Equipment: Codable {
    var microphone: String?
    var recorder: String?
    var preamp: String?
    var calibration: String?
}

// 音響分析結果
struct AcousticAnalysis: Codable {
    let laeq: Double
    let lmax, lmin: Double
    let l10, l50, l90: Double
    let spectrum: SpectrumData
    let octaveBands: OctaveBandData
}

// メタデータ
struct SoundscapeMetadata: Codable {
    var title: String
    var description: String?
    var location: GeoLocation
    var recordedAt: Date
    var duration: Double
    var sampleRate: Int  // 44100
    var channels: Int    // 1
    var bitDepth: Int    // 16
    var fileFormat: String  // "wav"
    var fileSize: Int
    var tags: [String]
    var locationName: String?
    var weather: String?
    var temperature: Double?
    var notes: String?
    var equipment: Equipment?
}

// 録音レコード
struct SoundscapeRecord: Codable, Identifiable {
    let id: String  // "rec_timestamp_hex8"
    var metadata: SoundscapeMetadata
    var analysis: AcousticAnalysis?
    var waveformPreview: [Double]?
    let createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus
}

// PAQスコア（ISO/TS 12913-2）
struct PAQScores: Codable {
    var pleasant: Int      // 1-5
    var chaotic: Int
    var vibrant: Int
    var uneventful: Int
    var calm: Int
    var annoying: Int
    var eventful: Int
    var monotonous: Int
}

// 音源知覚
struct SoundSourcePerception: Codable {
    var traffic: Double    // 0-10
    var other: Double
    var human: Double
    var natural: Double
}

// ISOメトリクス
struct ISOMetrics: Codable {
    let isoPleasant: Double   // -1 to 1
    let isoEventful: Double   // -1 to 1
    let quadrant: String      // vibrant/chaotic/monotonous/calm
}

// 主観評価
struct SubjectiveEvaluation: Codable, Identifiable {
    let id: String  // UUID
    let recordId: String
    var paqScores: PAQScores
    var appropriateness: Double  // 0-10
    var soundSources: SoundSourcePerception
    var freeText: String?
    var isoMetrics: ISOMetrics
    var evaluationContext: String?
    let createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus
}

enum SyncStatus: String, Codable {
    case synced, pendingUpload, pendingDownload, conflict, error
}
```

### 3.2 ISOメトリクス計算

```swift
// ISO/TS 12913-2 Circumplex Model
let cos45 = sqrt(2) / 2
let D = 4 + sqrt(32)

isoPleasant = ((p-a) + cos45*(c-ch) + cos45*(v-m)) / D
isoEventful = ((e-ue) + cos45*(ch-c) + cos45*(v-m)) / D

quadrant =
  isoPleasant >= 0 && isoEventful >= 0 ? "vibrant" :
  isoPleasant < 0 && isoEventful >= 0 ? "chaotic" :
  isoPleasant < 0 && isoEventful < 0 ? "monotonous" : "calm"
```

---

## 4. Firebase設計

### 4.1 Firestoreコレクション

```
/users/{userId}/
  - profile: { displayName, email, createdAt }
  - settings: { defaultSampleRate, autoSync }

/soundscapes/{recordId}/
  - id, userId
  - metadata: { title, location, recordedAt, duration, ... }
  - analysis: { laeq, lmax, spectrum, ... }
  - audio_file_path: "users/{userId}/soundscapes/{recordId}/audio.wav"
  - waveform_preview: [...]
  - created_at, updated_at

/evaluations/{evaluationId}/
  - id, record_id, user_id
  - paq_scores: { pleasant, chaotic, ... }
  - sound_sources: { traffic, human, ... }
  - iso_metrics: { iso_pleasant, iso_eventful, quadrant }
  - created_at, updated_at
```

### 4.2 Firebase Storage

```
/users/{userId}/soundscapes/{recordId}/
  - audio.wav (or audio.mp3)
  - thumbnail.png (optional)
```

### 4.3 セキュリティルール概要

- soundscapes: 作成者のみ読み書き可
- evaluations: 作成者のみ書き込み可、認証ユーザーは読み取り可
- Storage: 音声ファイルは100MB上限、オーナーのみアクセス可

---

## 5. オフライン同期設計

### 5.1 ローカルストレージ（SwiftData）

```swift
@Model class LocalSoundscapeRecord {
    @Attribute(.unique) var id: String
    var userId: String
    var metadataJSON: Data
    var analysisJSON: Data?
    var localAudioPath: String
    var syncStatus: String
    var remoteVersion: Int
}

@Model class LocalEvaluation {
    @Attribute(.unique) var id: String
    var recordId: String
    var evaluationJSON: Data
    var syncStatus: String
}
```

### 5.2 同期フロー

1. **ローカルファースト**: すべての操作はまずローカルに保存
2. **バックグラウンド同期**: ネットワーク復帰時に自動同期
3. **コンフリクト解決**:
   - Last-write-wins（デフォルト）
   - 手動解決オプション（keepLocal / keepRemote / keepBoth）

### 5.3 SyncManager

- ネットワーク状態監視（NWPathMonitor）
- アップロードキュー管理
- ダウンロード増分同期
- リトライロジック（最大3回）

---

## 6. 音声処理

### 6.1 録音仕様（AVFoundation）

```swift
let recordingSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
    AVSampleRateKey: 44100,
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsBigEndianKey: false,
    AVLinearPCMIsFloatKey: false
]
```

### 6.2 音響分析

- **A重み付け**: IEC 61672-1準拠のデジタルフィルタ
- **LAeq計算**: 10 * log10(mean(10^(Li/10)))
- **統計値**: Lmax, Lmin, L10, L50, L90
- **スペクトル**: vDSP FFT、Hanning窓
- **オクターブバンド**: 31.5Hz〜16kHz

---

## 7. アーキテクチャ

### 7.1 レイヤー構成

```
Views (SwiftUI)
    ↓
ViewModels (ObservableObject)
    ↓
Repositories (Protocol-based)
    ↓
┌─────────────────┬─────────────────┐
│ LocalDataStore  │ FirebaseClient  │
│   (SwiftData)   │   (Firestore)   │
└─────────────────┴─────────────────┘
         ↑
    SyncManager
```

### 7.2 主要ViewModel

- `RecordingViewModel`: 録音状態管理、メタデータ編集
- `LibraryViewModel`: 一覧取得、検索・フィルタ
- `EvaluationViewModel`: PAQ入力、ISO計算
- `SyncViewModel`: 同期状態表示

---

## 8. テストリリース要件

### 8.1 必要な権限（Info.plist）

```xml
NSMicrophoneUsageDescription: "サウンドスケープを録音するためにマイクを使用します。"
NSLocationWhenInUseUsageDescription: "録音した音声の位置情報を記録するために使用します。"
UIBackgroundModes: ["audio", "location"]
```

### 8.2 TestFlight配布

- Apple Developer Program登録（$99/年）
- Bundle ID設定
- GoogleService-Info.plist配置
- 内部テスター登録（最大100名）

### 8.3 プライバシーポリシー要件

収集データ:
- 位置情報（GPS座標）
- 音声データ
- ユーザー入力（タイトル、評価等）
- 認証情報（メールアドレス）

---

## 9. 参照ファイル（既存システム）

実装時に参照すべき既存Pythonコード:

| ファイル | 用途 |
|---------|------|
| `SoundscapeArchive/models/schemas.py` | データモデル定義の参照 |
| `SoundscapeArchive/services/evaluation_service.py` | ISO計算ロジック |
| `SoundscapeArchive/processing/laeq_calculator.py` | A重み付け・LAeq計算 |
| `SoundscapeArchive/processing/spectrum_analyzer.py` | スペクトル分析 |

---

## 10. 実装推奨順序

1. **Phase 1: 基盤**
   - Xcodeプロジェクト作成
   - Firebase設定
   - SwiftDataモデル定義
   - 認証フロー

2. **Phase 2: 録音機能**
   - RecordingManager実装
   - 録音UI
   - メタデータ編集UI
   - ローカル保存

3. **Phase 3: ライブラリ**
   - 一覧表示
   - 詳細表示
   - 音声再生
   - 検索・フィルタ

4. **Phase 4: 評価機能**
   - PAQ入力フォーム
   - ISO計算
   - Circumplexチャート

5. **Phase 5: 同期**
   - SyncManager実装
   - Firebase連携
   - コンフリクト解決UI

6. **Phase 6: テストリリース**
   - TestFlight配布
   - バグ修正
   - パフォーマンス最適化
