# JotMoney — Configuration Reference

Everything that can be automated is already configured. The short list below is what only you can do, because it requires your Apple Account.

## Manual configuration required (do these before release)

### 1. Sign the app for a real device (iOS)

The project already contains a valid project-level team (`JP4TN5PTS3`) and automatic signing. The provisioning profile on this machine does not yet include the App Group or the iCloud container, so a device build reports a signing error until Xcode registers them.

1. Open `JotMoney.xcodeproj` in Xcode and sign in with your Apple ID (Xcode → Settings → Accounts).
2. Select the `JotMoney` scheme and run:

```
xcodebuild -project JotMoney.xcodeproj -scheme JotMoney \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build
```

Xcode registers `group.com.zzoutuo.JotMoney` and `iCloud.com.zzoutuo.JotMoney` on the developer portal automatically.

### 2. Deploy the CloudKit schema to Production

1. Run the app once on a real device (or a simulator signed into iCloud).
2. Open https://icloud.developer.apple.com → container `iCloud.com.zzoutuo.JotMoney` → **Deploy Schema Changes to Production**.

Required before App Store release. Without it, iCloud sync fails for release users; the app still works locally.

### 3. Create the four in-app purchase products in App Store Connect

| Product ID | Type | Price |
|---|---|---|
| `com.zzoutuo.jotmoney.pro.monthly` | Auto-renewable, group "JotMoney Pro" | $3.99 / month |
| `com.zzoutuo.jotmoney.pro.yearly` | Auto-renewable, group "JotMoney Pro" | $19.99 / year, 7-day free trial |
| `com.zzoutuo.jotmoney.family.yearly` | Auto-renewable, group "JotMoney Pro" | $29.99 / year |
| `com.zzoutuo.jotmoney.pro.lifetime` | Non-consumable | $59.99 once |

Display names and descriptions are in `price.md` (all within Apple's 35/55 character limits).

### 4. GLM cloud AI development key (optional, only for local testing without a subscription)

The app uses the subscription JWS channel in production, which needs no setup. For local testing without a subscription, place the development key at `JotMoney/GLMProxySecret.txt`:

```
<dev key value>
```

That file is git-ignored and excluded from Release builds via `EXCLUDED_SOURCE_FILE_NAMES`. The app's Bundle ID is already registered in the shared proxy whitelist (`appId: jotmoney`).

### 5. App Store Connect app record

Create the app, set the name `JotMoney`, subtitle, category Finance, age rating 4+, and paste the metadata from `keytext.md`. Support / Privacy / Terms URLs are live (see below).

---

## Auto-configured (no action needed)

| Capability | Status | Where |
|---|---|---|
| Bundle ID `com.zzoutuo.JotMoney` | Configured | `project.yml` |
| Development team | Configured project-wide | `project.yml` (`JP4TN5PTS3`) |
| App Group `group.com.zzoutuo.JotMoney` | Configured (App + Widget) | both `.entitlements` |
| iCloud container `iCloud.com.zzoutuo.JotMoney` | Configured | `JotMoney/JotMoney.entitlements` |
| CloudKit service + `aps-environment` | Configured | entitlements |
| WidgetKit lock screen widget | Configured | `JotMoneyWidget` target |
| Camera, Microphone, Speech, Photo usage strings | Configured | `INFOPLIST_KEY_*` in `project.yml` |
| Export compliance | Configured (`ITSAppUsesNonExemptEncryption = NO`) | build settings |
| Privacy manifest (App) | Configured (no tracking, no collected data) | `JotMoney/Resources/PrivacyInfo.xcprivacy` |
| Privacy manifest (Widget) | Configured | `JotMoneyWidget/PrivacyInfo.xcprivacy` |
| StoreKit 2 purchase manager | Implemented | `Store/StoreManager.swift` |
| Local StoreKit test products | Configured | `JotMoney/Products.storekit` + scheme |
| App Intents / Siri | Implemented | `Intents/JotMoneyIntents.swift` |
| Feedback backend | Configured | `https://msg.calcs.top/api/feedback` |
| iPhone + iPad | Configured | `TARGETED_DEVICE_FAMILY = 1,2` |
| Policy pages | Deployed | GitHub Pages from `/docs` |
| GLM proxy whitelist | Registered (`jotmoney`) | Cloudflare D1 |

## Deliberately absent

- No analytics SDK, no advertising SDK, no attribution SDK.
- No account system and no Sign in with Apple.
- No ATT prompt (nothing is tracked).
- No HealthKit, no Location, no background modes.
- No server of our own storing ledger data.

## URLs

| Page | URL |
|---|---|
| Landing | https://asunnyboy861.github.io/JotMoney/ |
| Support | https://asunnyboy861.github.io/JotMoney/support.html |
| Privacy | https://asunnyboy861.github.io/JotMoney/privacy.html |
| Terms | https://asunnyboy861.github.io/JotMoney/terms.html |

## Verification performed

| Check | Result |
|---|---|
| iPhone 16 simulator build | BUILD SUCCEEDED |
| iPad Pro 13-inch simulator build | BUILD SUCCEEDED |
| Fresh install → onboarding → home | Passed (3-screen onboarding, first transaction) |
| Home / Ledger / Insights render | Passed (screenshots verified) |
| Device signing | Deferred to step 1 above (portal registration) |
| Secret scan before push | Clean |
| Empty `DEVELOPMENT_TEAM` scan | 0 matches |
| Privacy manifest present in both targets | Yes |
| Paywall legal links | Present (Privacy, Terms, Support) |
