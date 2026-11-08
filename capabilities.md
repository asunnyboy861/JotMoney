# Capabilities Configuration

> This is the PHASE 2 developer view. It is rewritten into a user-facing configuration reference in PHASE 8.5.

## Analysis

Detected requirements from the Chinese guide + `us.md`:

| Requirement | Keyword source | Capability |
|---|---|---|
| Optional iCloud sync of the ledger | "iCloud 同步可选" / `cloudKitDatabase: .private` | iCloud / CloudKit |
| Family shared ledger | "家庭/共享账本" / CKShare | iCloud (CloudKit sharing) |
| Lock screen Safe to Spend widget | "锁屏 inline widget" | WidgetKit + App Group |
| Voice entry | "语音记账" / on-device dictation | Microphone + Speech Recognition |
| Receipt OCR capture | "拍小票" / VisionKit DataScanner | Camera (+ Photo Library fallback) |
| Siri quick logging | "Hey Siri, log coffee five fifty" | App Intents / Siri |
| Subscriptions | Pro Monthly / Pro Yearly / BYO Lifetime / Family | In-App Purchase (StoreKit 2) |
| Outbound AI calls | BYO OpenAI-compatible + GLM cloud | App Transport Security default (HTTPS) |

## Auto-Configured Capabilities

| Capability | Status | Method |
|---|---|---|
| iCloud container `iCloud.com.zzoutuo.JotMoney` | ✅ Configured in entitlements | `project.yml` → `JotMoney/JotMoney.entitlements` |
| CloudKit service | ✅ Configured | `com.apple.developer.icloud-services = CloudKit` |
| Ubiquity key-value store | ✅ Configured | `$(TeamIdentifierPrefix)com.zzoutuo.JotMoney` |
| `aps-environment` (CloudKit silent push) | ✅ Configured (`development`) | Required for CloudKit background sync |
| App Group `group.com.zzoutuo.JotMoney` | ✅ Configured (App + Widget) | Both entitlement files |
| WidgetKit lock screen widget target | ✅ Configured | `JotMoneyWidget` app-extension target |
| Camera usage string | ✅ Configured | `INFOPLIST_KEY_NSCameraUsageDescription` |
| Microphone usage string | ✅ Configured | `INFOPLIST_KEY_NSMicrophoneUsageDescription` |
| Speech recognition usage string | ✅ Configured | `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription` |
| Photo library usage string | ✅ Configured | `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` |
| Export compliance | ✅ Configured | `ITSAppUsesNonExemptEncryption = NO` |
| Privacy manifest (App) | ✅ Configured | `JotMoney/Resources/PrivacyInfo.xcprivacy` — UserDefaults CA92.1 + FileTimestamp C617.1, no tracking, no collected data |
| Privacy manifest (Widget) | ✅ Configured | `JotMoneyWidget/PrivacyInfo.xcprivacy` — UserDefaults CA92.1 |
| In-App Purchase | ✅ Configured | StoreKit 2 code-level; products created in ASC (PHASE 3 defines IDs) |
| App Intents / Siri | ✅ Configured | `Intents/` module, no extra entitlement required |
| iPhone + iPad | ✅ Configured | `TARGETED_DEVICE_FAMILY = "1,2"` |
| Signing team | ✅ Baked at project level | `DEVELOPMENT_TEAM = JP4TN5PTS3` |

## Manual Configuration Required

| Capability | Status | Steps |
|---|---|---|
| Device signing with App Group + iCloud | ⏳ Deferred | Sign into Xcode with the developer Apple ID, then run `xcodebuild -project JotMoney.xcodeproj -scheme JotMoney -destination 'generic/platform=iOS' -allowProvisioningUpdates build`. Xcode auto-registers the App Group and iCloud container on the portal. |
| CloudKit schema → Production | ⏳ Pending | After the first real-device (or iCloud-signed-in simulator) run, open CloudKit Dashboard → container `iCloud.com.zzoutuo.JotMoney` → Deploy Schema Changes to Production. Required before App Store release. |
| StoreKit products | ⏳ Pending | Created via ASC in PHASE 3 / `ios-asc-metadata-pricing`. |
| GLM cloud proxy key | ⏳ Pending | Handled by the `glm-api-config` skill in PHASE 4+5 (key stays server-side). |

## No Configuration Needed

- Push Notifications (remote) — not used; only CloudKit's automatic silent push, covered by `aps-environment`.
- HealthKit — not applicable.
- Location Services — not applicable.
- Background Modes — no `UIBackgroundModes` required; SwiftData + CloudKit syncs opportunistically.
- Sign in with Apple — deliberately absent (no-account product).
- Analytics / ATT — deliberately absent (privacy is a selling point).

## iCloud / CloudKit Verification Notes

- Entitlement keys present: `com.apple.developer.icloud-container-identifiers`, `com.apple.developer.icloud-services`, `com.apple.developer.ubiquity-kvstore-identifier`, `aps-environment`.
- Container naming follows `iCloud.<bundleId>` = `iCloud.com.zzoutuo.JotMoney`.
- Widget extension intentionally has **no** iCloud entitlement — it reads a snapshot through the App Group only.
- SwiftData + CloudKit code constraints for PHASE 4+5 (mandatory):
  - No `@Attribute(.unique)` anywhere.
  - Every stored property has a default value or is optional.
  - Relationships are optional (or have defaults).
  - Enums persisted as `rawValue`.
  - `ModelConfiguration(schema:cloudKitDatabase: .private("iCloud.com.zzoutuo.JotMoney"))` with a degradation chain: CloudKit → local → in-memory, never crash.
- Simulator builds resolve `ENTITLEMENTS_REQUIRED = NO` and produce an empty entitlements dict — expected, not a configuration error. Real-device build is the authoritative check.

## Verification

- **Build succeeded after configuration (iOS Simulator, iPhone 16)**: ✅ `** BUILD SUCCEEDED **`
- **All entitlements correct**: ✅ (App: 5 keys; Widget: App Group only)
- **Signing verification (`generic/platform=iOS`)**: ⏳ DEFERRED — provisioning profile does not yet include App Group / iCloud; user signs into Xcode, then runs `-allowProvisioningUpdates` once
- **DEVELOPMENT_TEAM**: `JP4TN5PTS3` baked at project level (inherited by every target)
- **PrivacyInfo.xcprivacy**: App target + Widget target covered
- **Project root**: `/Volumes/ORICO-APFS/app/APP/IOS-APP/2026/202610/20261014/JotMoney`
