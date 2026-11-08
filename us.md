# JotMoney — iOS Development Guide

## Executive Summary

**Product vision**: JotMoney is a "log it in 2 seconds" personal ledger for the US market. The user opens the app, types `coffee 5.5`, hits return — done. Amount, merchant, category, and account are filled in automatically. Everything runs offline, with no account and no data leaving the device (iCloud private sync is optional). Every transaction, installment period, and interest accrual is computed correctly.

**Tagline**: "Type it. Done. No subscription, ever."

**Target audience**: US consumers suffering from subscription fatigue — people leaving YNAB ($109/yr), Copilot ($95/yr), and Monarch ($99–199/yr), plus privacy-sensitive users who refuse to hand bank credentials to Plaid-based aggregators.

**Core differentiators**
1. **Free tier contains what competitors charge for** — offline, account-free, full ledger, 2 accounts, Safe to Spend, budgets, CSV export.
2. **Two-second loop** — `[merchant] [amount]` natural-language entry with deterministic parsing first, AI only as a fallback.
3. **Financial correctness as a feature** — duplicate detector, installment billing-day anchoring, daily-balance interest engine, normalized merchant keys. These directly turn Tarsi's self-reported bug history into our selling points.
4. **Honest pricing** — Free / Pro $3.99-mo / Pro $19.99-yr (primary) / BYO Lifetime $59.99 / Family $29.99-yr, with a competitor price-anchor wall.
5. **AI without lock-in** — Apple on-device Foundation Models (free, offline) → BYO key for any OpenAI-compatible provider → built-in GLM cloud quota for Pro.

**Category**: Finance. **Age rating**: 4+. **Localization**: English only (US). **Currency**: USD default, per-account currency supported.

---

## Naming & Store Metadata

| Item | Value |
|---|---|
| App name | **JotMoney** |
| Subtitle (≤30 chars) | `Type it. Done. No subscription` |
| Category | Finance |
| Age rating | 4+ |
| Marketing line | "Type it. Done. Your money in two seconds — no subscription, ever." |

**Bundle ID**: `com.zzoutuo.JotMoney`

> ⚠️ **Engineering convention override**: the Chinese guide contains no explicit Bundle ID, and where a guide-suggested Bundle ID exists it is ignored per skill precedence. `BUNDLE_PREFIX=com.zzoutuo.` from the skill `.env` is authoritative — Bundle ID is `com.zzoutuo.JotMoney`.

**Name availability**: As of 2026-10-13, a US-store iTunes Search API check found JotMoney unoccupied (only fuzzy matches to unrelated apps). Re-verify in App Store Connect before submission. Forbidden names (already taken): Tarsi, YNAB, Copilot, Monarch, Spendle, TapLedger. Fallbacks: PennyJot, Blipbook, Quickscribble.

---

## Competitive Analysis

| App | Pricing | Strengths | Weaknesses | Our Advantage |
|-----|---------|-----------|------------|---------------|
| **Tarsi** | $4.99 one-time + Cloud €22.99/yr | Natural-language entry, on-device parsing, multi-account net worth, installments, interest, shared ledger, receipt OCR; $20K first month, #1 paid in 5 countries | Changelog self-reports: installment billing-day errors, duplicate entries from shared-ledger edits, recurring plans disappearing, interest records wrong and need manual fixes, case-duplicate payee names; no bank connection; no desktop | We ship the correctness engines as first-class features (duplicate detection, billing-day anchoring, daily-balance interest, normalized merchant keys) at a $0 entry price |
| **YNAB** | $109/yr or $14.99/mo | Zero-based budgeting gold standard | Steep learning curve; silent price increases; full annual auto-renew charge + refused refunds are the largest source of 1–3 star reviews | No learning curve — one big number; no auto-renew trap in the free tier |
| **Copilot Money** | $95/yr or $12.99/mo | Beautiful UI, AI categorization | AI miscategorizes and needs manual correction; weak investments; no free tier | Free tier with real functionality; corrections are learned permanently via MerchantMemory |
| **Monarch** | $99.99/yr (Plus $199/yr) | Full financial picture, bank sync | Plaid disconnects every 7–14 days (Chase/Capital One re-auth); Mint migration data loss | No Plaid at all — no credential sharing, no disconnect loop |
| **Rocket Money** | Free + $7–14/mo | Subscription cancel, bill negotiation | Takes 30–60% of first-year savings; aggressive upsell | Zero upsell popups; no commission business model |
| **Buckets** | $64 one-time | Envelope budgeting | Desktop-first, poor mobile UX, high price | $59.99 lifetime with far more capability, mobile-first |
| **EveryDollar** | Free manual + $79.99/yr | Ramsey method | Manual per-transaction entry is friction the free tier never solves | 2-second entry is the whole product |
| **Actual Budget** | Free, open source | Local-first | Requires self-hosting/manual import; official iOS app not shipped until late 2026 | Zero setup, native iOS, local-first by default |

**Price anchor for the paywall**: YNAB $109/yr · Copilot $95/yr · Monarch $100–199/yr → **JotMoney $19.99/yr** ($1.67/mo).

---

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | **Onboarding — 3 screens** | 1. First launch → Screen 1 "No sign-up. Your data stays on this phone." → 2. Screen 2 create first account (Cash/Checking/Credit + opening balance) → 3. Screen 3 pre-filled first entry `coffee 4.5` → return | Taps, account name, account kind, opening balance | Creates Account record; runs the standard quick-entry pipeline for the demo transaction | Success animation on the first logged entry; lands on Home | `Account` record; `UserDefaults` onboarding-complete flag | Fresh install → 3 screens → first transaction exists → Home shows it in today's list |
| 2 | **Quick entry (text)** | Type in persistent bottom bar → keyboard opens immediately → inline confirm card auto-fills → return to commit | Free text e.g. `coffee 5.5`, `$5.50 sbux`, `paid 12 to Uber` | `QuickEntryParser`: amount regex `\d+([.,]\d{1,2})?`, merchant token extraction, dictionary + MerchantMemory normalization, confidence scoring; if confidence < 0.85 → AI fallback | Confirm card with amount / merchant / category / account; green check + haptic; Safe to Spend animates | `Transaction` with `idempotencyKey`, `merchantKey`, `localTimeZoneID`, `source` | Typing `coffee 5.5` + return creates a $5.50 dining transaction in under 3 seconds |
| 3 | **Voice entry** | Tap mic on entry bar → on-device dictation → transcript drops into the same entry field → parse as feature 2 | Speech | `SFSpeechRecognizer` (on-device) → string → QuickEntryParser | Same as feature 2 | Same as feature 2 | Speaking "coffee five fifty" produces a $5.50 transaction without network |
| 4 | **Receipt OCR (Pro)** | Tap receipt icon → VisionKit `DataScannerViewController` captures frame → GLM-5.3-Flash vision extracts structured JSON → confirm card prefilled with items | Receipt JPEG (base64) | GLM vision call with strict JSON schema; fallback to Apple on-device with lower-accuracy notice | Prefilled transaction with merchant, total, tax, tip, items, suggested category, confidence | `Transaction` + `receiptImageID` (local file); audit log entry | Photographing a receipt yields a transaction whose total matches the printed total; disconnect → graceful fallback notice |
| 5 | **Multi-account + net worth** | Home → account chip / Settings → Accounts → add / edit / archive | Account name, kind, currency, opening balance, APR | `BalanceEngine` sums opening balances plus signed transactions per account; net worth = assets − liabilities | Account list with balances; net worth card | `Account` (normalizedKey prevents case duplicates) | Adding an account with $100 opening balance and a $5.50 expense shows $94.50; net worth updates immediately |
| 6 | **Safe to Spend** | Open app → one large number at top of Home | Accounts, budgets, recurring rules, installment plans | `STT = available balance − committed spend (remaining fixed bills this cycle + installment periods + unused budget amortized per day)`; conservative / standard / relaxed modes | 96pt monospaced number, animates on every new transaction; period progress bar | Computed on the fly (no stored value) | Logging a $5.50 expense decrements the number by exactly $5.50 |
| 7 | **Duplicate detection** | Any save path → pre-save scan → if suspect, side-by-side confirm card "Duplicate? Merge / Keep both" | Candidate transaction + recent transactions | Amount equal ±1 cent ∧ date window ±3 days ∧ merchant Jaro-Winkler ≥ 0.85 → suspect; same-amount/same-day/same-merchant second entry → high suspect | Confirm card; merge records `pendingOf` chain and writes an undoable audit entry | `Transaction.pendingOf`; audit log | Logging `coffee 5.50` twice on the same day triggers the card; choosing "Keep both" retains both rows |
| 8 | **Installments / BNPL** | Ledger → Installments → create plan (merchant, total, period count, first charge date, cadence) → engine materializes due periods | Total, periods count, per-period amount, first charge date, cadence (Klarna 4× biweekly / monthly / custom) | `InstallmentEngine`: anchor = first charge date, `Calendar.date(byAdding:)`, month-end clamping (Jan 31 → Feb 28), validation periods × per-period = total (±1 cent residual allocated to period 1), `generatedCount` resumable materialization | Installment calendar; generated transactions tagged with `ruleID` | `InstallmentPlan` + generated `Transaction`s | Creating 4 × $25 with first charge Jan 31 yields Feb 28 / Mar 31 / Apr 30 style clamping; total equals $100 exactly |
| 9 | **Interest engine** | Account detail → enable APR → monthly accrual view | APR in basis points, daily balance snapshots | `InterestEngine`: `daily = APR/365 × balance`, summed per calendar day; savings compounds monthly; credit accrues per statement cycle | `InterestEntry` rows, individually correctable with an audit trail (never silent overwrite) | `InterestEntry` model | A $1,000 balance at 12% APR accrues ≈ $0.33/day; correcting an entry preserves the original in the audit log |
| 10 | **Shared ledger (Pro)** | Settings → Shared Ledger → invite via CKShare → participants sync | CKShare invitation, remote records | Upsert by `idempotencyKey` (never append); attribution per creator; participant-scoped aggregation | Shared ledger list, per-person totals; participant sees only their own spend statistics | SwiftData + CloudKit shared store | Two devices editing the same record produce one row, not two; person B's spend never inflates person A's totals |
| 11 | **Cashflow forecast + subscription radar (Pro)** | Insights → Forecast; Insights → Subscription Radar | Recurring rules, installment plans, 90-day variable-spend history | Forecast: current balance + scheduled fixed in/out + 90-day average variable spend × 1.1 volatility for 30 days. Radar: same merchant ∧ amount ±5% ∧ stable interval (7/30/31/365 ±2 days) ≥ 3 consecutive | 30-day chart (Swift Charts); suspected-subscription list | Derived (no new model) | Forecast chart renders 30 points; three $9.99 monthly charges to the same merchant are flagged |
| 12 | **Money Wrapped (month-end share card)** | Insights → Money Wrapped → generate → share | Monthly transactions | Largest single transaction, most-visited merchant, amount saved vs prior month, category story copy | 9:16 dark share card with JotMoney watermark and `#JotMoney` | Generated image cached locally | Card renders at 1080×1920, shareable to Instagram Stories; watermark and hashtag present |
| 13 | **Weekly Pulse** | Sunday → Home banner card | Current week transactions | Spend total, biggest overspend category, upcoming subscription reminders | One card summary | Derived | Card content matches the week's actual data |
| 14 | **BYO AI settings** | Settings → AI → provider template picker + baseURL / model / key fields + vision toggle | Provider, baseURL, API key, model name, supportsVision | Key stored in Keychain; OpenAI-compatible request builder; vision gate for OCR tasks | Test-connection result; AI routed to user's provider | Keychain (key); `UserDefaults`/SwiftData (non-secret settings) | Pasting an OpenAI key and tapping Test returns a 200; OCR is blocked with a clear message when vision is off |
| 15 | **Budgets** | Insights → Budgets → create/edit per category | Category, monthly limit | Budget progress = spent/limit; feeds Safe to Spend committed spend (Free: 1 budget, Pro: unlimited) | Progress rings; over-budget amber/red | `Budget` model | Creating a $200 grocery budget and spending $90 shows 45% |
| 16 | **Recurring rules** | Ledger → Recurring → create rule (merchant, amount, cadence, next date) | Merchant, amount, cadence, anchor date | Rule is the single source of truth; transactions expand from the rule tagged with `ruleID`; deleting a transaction never deletes the rule; rule edits affect only future periods | Recurring list; generated transactions | `RecurringRule` + `Transaction.ruleID` | Editing a rule's amount changes only future entries; deleting a generated transaction leaves the rule intact |
| 17 | **CSV / JSON export** | Settings → Export | Date range | Serializes transactions with ISO dates and integer cents | Share sheet with file | — | Exported CSV opens in Numbers/Excel with correct amounts and dates |
| 18 | **Lock screen widget** | Add widget → lock screen inline | Current Safe to Spend | WidgetKit timeline provider reads the app group snapshot | `Safe to Spend: $42.18` | App Group shared container snapshot | Widget shows the same number as the app after the next refresh |
| 19 | **Siri / App Intents** | "Hey Siri, log coffee five fifty" | Spoken phrase | App Intent → QuickEntryParser → save | Confirmation spoken / shown | `Transaction` | The intent resolves an amount and merchant and saves a transaction |
| 20 | **Categories, notes, search** | Entry confirm card → tap category; Ledger → search bar | Category selection, note text, query | Normalized search across merchantRaw/merchantKey/note; categories are editable | Filtered list; category chips | `Category` + `Transaction.categoryID` / `note` | Searching "coffee" returns all coffee transactions across accounts |
| 21 | **Merchant memory learning** | Confirm card → user corrects category → save | Correction | `MerchantMemory.hitCount` increments; aliases merged; storage lowercase+trim, display keeps user's casing | Next entry with the same merchant arrives pre-categorized | `MerchantMemory` | Correcting `sbux` to Dining once makes the next `sbux` entry default to Dining |
| 22 | **iCloud sync (Pro)** | Settings → toggle iCloud sync | Local SwiftData store | SwiftData `cloudKitDatabase: .private`; all attributes have defaults, relationships optional, no `#Unique` | Synced data across the user's devices | CloudKit private database | Toggling sync on a second device surfaces the same transactions |
| 23 | **Paywall / subscriptions** | Any Pro gate → paywall | — | StoreKit 2 + RevenueCat entitlements; packages: Pro Monthly $3.99, Pro Yearly $19.99 (7-day trial, primary), BYO Lifetime $59.99, Family $29.99 | Paywall with competitor price anchors, legal links | RevenueCat entitlement | Purchase unlocks Pro; restore purchases works; legal links open |
| 24 | **Settings & policies** | Settings tab | — | Links to Support / Privacy / Terms, contact support form, version read dynamically | Settings list | `UserDefaults` | All three policy links open; version matches the build |
| 25 | **Contact support** | Settings → Contact Support | Preset subject tile, message, optional email | POST to `${FEEDBACK_BACKEND_URL}`; success/error feedback | Toast confirmation | — | Submitting a message returns success without leaving the app |

### Sub-Features & Detail Interactions

| # | Parent Feature | Sub-Feature | Detail Description | Interaction Pattern |
|---|---------------|-------------|-------------------|--------------------|
| 1.1 | Onboarding | No-account manifesto screen | "No sign-up. Your data stays on this phone." Sets the emotional anchor before any setup | Tap "Continue" |
| 1.2 | Onboarding | First account creation | Cash / Checking / Credit selector + opening balance in 30 seconds | Tap chips, numeric keypad |
| 1.3 | Onboarding | First transaction demo | Entry field pre-filled with `coffee 4.5`; return completes the loop | Return key |
| 2.1 | Quick entry | Persistent entry bar | Bottom bar is a real text field, not a FAB — one tap opens the keyboard in place | Tap anywhere on the bar |
| 2.2 | Quick entry | Confirm card auto-skip | High-confidence parses commit immediately; only low confidence shows the card | Automatic |
| 2.3 | Quick entry | Haptic success | `UINotificationFeedbackGenerator.success()` + green check | Automatic |
| 2.4 | Quick entry | Amount formats | `5`, `5.5`, `5.50`, `$5.50`, `coffee $5`, `5 coffee`, `paid 12 to Uber` | Text |
| 2.5 | Quick entry | Duplicate intercept | Pre-save scan may replace the confirm card with a side-by-side duplicate card | Tap "Merge" / "Keep both" |
| 7.1 | Duplicate detection | pending→posted merge | Second entry defaults to "this confirms the earlier one"; merging keeps the original timestamp | Toggle + merge |
| 7.2 | Duplicate detection | Undo | Merges write an audit log entry that can be undone | Swipe action |
| 8.1 | Installments | Klarna/Afterpay preset | 4 periods every 2 weeks preconfigured | Template chip |
| 8.2 | Installments | Residual allocation | `total − periods × perPeriod` goes to period 1 | Automatic |
| 9.1 | Interest | Manual correction with trail | Editing an accrual never overwrites the original value | Edit sheet |
| 10.1 | Shared ledger | Idempotent upsert | Every write path uses `idempotencyKey` upsert, never append | Automatic |
| 10.2 | Shared ledger | Per-creator attribution | Statistics aggregate per participant view | Automatic |
| 11.1 | Radar | Interval tolerance | 7/30/31/365 days ±2 days counts as stable | Automatic |
| 12.1 | Wrapped | Watermark + hashtag | `#JotMoney` and logo bottom-right of every card | Automatic |
| 20.1 | Entry | Category quick-pick | Category chips directly on the confirm card, no modal stack | Tap chip |
| 20.2 | Entry | Note field | Optional one-line note | Text |
| 21.1 | Merchant memory | Alias merging | `sbux`, `starbux` → `Starbucks` display name | Automatic |
| 21.2 | Merchant memory | Casing policy | Store lowercase; display the user's preferred casing | Automatic |
| 3.1 | Voice | On-device dictation | `requiresOnDeviceRecognition = true` so audio never leaves the device | Tap mic |
| 4.1 | OCR | Failure degradation | Timeout/5xx → 1 retry → Apple on-device OCR with "lower accuracy" notice → queue for re-upload | Automatic |
| 6.1 | Safe to Spend | Three strictness modes | Conservative / Standard / Relaxed configurable in Settings | Segmented control |
| 5.1 | Accounts | Archive, never delete | `isArchived` keeps history intact for sync safety | Swipe action |

### Cross-Feature Dependencies

| Dependency | Source Feature | Target Feature | Data Passed | Trigger Condition |
|------------|---------------|----------------|-------------|-------------------|
| New transaction updates Safe to Spend | Quick entry / OCR / Installments / Recurring | Safe to Spend | `amountCents`, `accountID`, `date` | On every committed transaction |
| New transaction updates budgets | Any save path | Budgets | `categoryID`, `amountCents` | On commit |
| Merchant correction trains the parser | Confirm card | Quick entry | `merchantKey`, `defaultCategoryID`, alias list | When the user changes the category then saves |
| Installment plan expands to transactions | Installments | Ledger / Balance | `perPeriodCents`, dates, `ruleID` | On plan creation and on every app launch (due materialization) |
| Recurring rule expands to transactions | Recurring rules | Ledger / Balance | Amount, cadence, `ruleID` | On rule creation and app launch |
| Transactions feed Insights | Ledger | Forecast / Radar / Wrapped / Weekly Pulse | Aggregate sums and merchant groupings | When the Insights tab opens |
| Safe to Spend feeds the widget | Home | Widget | Snapshot value in the App Group | On transaction commit + timeline refresh |
| Duplicate check reads recent transactions | Any save path | Duplicate detection | Candidate + recent window | Before every save |
| Account deletion archives and hides | Accounts | Home / Ledger | `isArchived` flag | On archive |
| Pro entitlement unlocks gates | Paywall | Accounts, budgets, OCR, shared ledger, widget, sync | Entitlement boolean | At view-render time |

**⚠️ VERIFICATION**: 25 primary features, 24 sub-features, 10 cross-feature dependencies — all traced back to the Chinese guide's feature matrix (§2.2), user flow (§4), data flow (§5), engineering checklist (§6.10), and final checklist (§11). Counts match.

---

## Apple Design Guidelines Compliance

- **HIG — Clarity / Deference / Depth**: Single dominant number on Home; no decorative chrome; 20pt corner cards with subtle depth.
- **HIG — Dynamic Type**: All text uses semantic styles; the 96pt Safe to Spend number scales with `@ScaledMetric` and clamps at accessibility sizes.
- **HIG — Dark mode first**: Dark background is the default aesthetic; light mode fully supported.
- **HIG — Haptics**: `.success` notification feedback on transaction commit; `.selection` on chip taps.
- **HIG — Accessibility**: VoiceOver labels for all interactive controls; the Safe to Spend value has a spoken sentence label ("Safe to spend today: 42 dollars 18 cents").
- **HIG — Widgets**: Lock screen inline widget only; no interactive widget complexity.
- **App Store 4+: no objectionable content.**
- **Privacy**: No account, no analytics SDK, no tracking. Privacy manifest declares no data collection; no ATT prompt needed.
- **Finance category**: no investment advice; purely bookkeeping.
- **Guideline 3.1.2(c)**: Paywall shows title, length, price, auto-renew disclosure, and functional Privacy Policy + Terms (EULA) links.
- **Guideline 2.1(a)**: Every AI affordance has a working path on a reviewer device (Apple Intelligence on iOS 26+, or BYO key guidance on older devices).
- **Guideline 5.1.1**: The app explains that BYO API keys are stored only in the local Keychain.

---

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (default free backend)
The app uses Apple on-device Foundation Models where available (iOS 26+ on supported hardware) for quick-parse fallback and category suggestions.

- **iOS 26+ supported hardware**: Apple Intelligence is the default; AI features work out of the box.
- **iOS < 26 or unsupported hardware**: the app falls back to the deterministic parser plus an optional BYO API key. The UI shows "Apple Intelligence requires iOS 26+. Configure a custom API key for AI parsing." with a link to Settings.
- **Simulator**: Apple Intelligence is unavailable; testing uses the deterministic parser or a BYO key.

### BYO API Key (optional advanced configuration)
Settings → AI → provider template + baseURL + model + key. Keys live only in the Keychain. Supported templates: GLM/Z.ai, OpenAI, Google Gemini, Anthropic Claude, DeepSeek, and any custom OpenAI-compatible endpoint.

### Dead code prevention
- ❌ NEVER add `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, or `incrementGenerationCount()`.
- `canUseAIFeature` must be `isPro || hasAPIKey || appleIntelligenceAvailable` — never a free-generation counter.

### Reviewer access
`app_review_info.md` documents how a reviewer on an older device can paste a demo key. No AI button may lead to a dead-end error.

---

## ⚠️ App Store Compliance — Subscriptions

- Paywall MUST show: subscription title, duration, price, auto-renewal disclosure, Privacy Policy link, Terms of Use (EULA) link, and Restore Purchases.
- Subscription value is framed as "Unlock every Pro feature" — never "unlimited AI generations".
- BYO key users get unlimited AI on their own key; that is a feature of the app, not a subscription benefit.
- Free trial: 7 days on Pro Yearly (configured in App Store Connect, disclosed on the paywall).

---

## Technical Architecture

- **Language**: Swift 5.9+
- **UI**: SwiftUI (primary), `@Observable` view models, Liquid Glass aesthetic on iOS 26 with graceful iOS 17 fallback
- **Data**: SwiftData (local-first), optional CloudKit private database, `NSUbiquitousKeyValueStore` not used for financial data
- **Sharing**: CloudKit `CKShare` with idempotent upsert
- **Charts**: Swift Charts
- **Widgets**: WidgetKit (lock screen inline)
- **Intents**: App Intents + Siri
- **Capture**: VisionKit `DataScannerViewController`
- **IAP**: StoreKit 2, entitlement gating via RevenueCat (or StoreKit 2 `Transaction.currentEntitlements` when RevenueCat is not configured)
- **Speech**: `SFSpeechRecognizer` with `requiresOnDeviceRecognition = true`
- **Networking**: `URLSession` async/await
- **AI**: Apple Foundation Models (when available) → BYO OpenAI-compatible client → GLM cloud proxy
- **Minimum iOS**: 17.0

### Money representation (non-negotiable)
- All amounts are **`Int64` cents**. Never `Double` in balances, interest, installments, or budgets.
- Display formatting goes through a single `MoneyFormatter` (`Decimal` conversion, locale-aware).

### SwiftData + CloudKit rules
- Every `@Model` attribute has a default value.
- Every relationship is optional.
- `#Unique` is forbidden; dedupe via `normalizedKey`.
- Custom `actor` instead of `@ModelActor` when isolation is needed.

---

## Module Structure

```
JotMoney/
├── App/
│   ├── JotMoneyApp.swift
│   └── AppEnvironment.swift
├── Models/
│   ├── Account.swift
│   ├── Transaction.swift
│   ├── Category.swift
│   ├── Budget.swift
│   ├── RecurringRule.swift
│   ├── InstallmentPlan.swift
│   ├── InterestEntry.swift
│   ├── MerchantMemory.swift
│   ├── AuditLogEntry.swift
│   └── Enums.swift
├── Engines/
│   ├── QuickEntryParser.swift
│   ├── BalanceEngine.swift
│   ├── SafeToSpendEngine.swift
│   ├── DuplicateDetector.swift
│   ├── InstallmentEngine.swift
│   ├── InterestEngine.swift
│   ├── CashflowForecast.swift
│   ├── SubscriptionRadar.swift
│   └── JaroWinkler.swift
├── AI/
│   ├── AIRouter.swift
│   ├── AppleIntelligenceService.swift
│   ├── BYOSettings.swift
│   ├── OpenAICompatClient.swift
│   ├── GLMClient.swift
│   └── AIResult.swift
├── Store/
│   ├── StoreManager.swift
│   └── PaywallPackages.swift
├── Views/
│   ├── Onboarding/
│   ├── Home/
│   ├── Ledger/
│   ├── Insights/
│   ├── Settings/
│   ├── Paywall/
│   └── Shared/
├── DesignSystem/
│   ├── Theme.swift
│   ├── MoneyFormatter.swift
│   └── Components.swift
├── Support/
│   ├── ContactSupportView.swift
│   ├── PolicyLinks.swift
│   └── AppVersion.swift
├── Intents/
│   └── JotMoneyIntents.swift
├── Widget/
│   └── SafeToSpendWidget.swift
└── Resources/
    ├── Assets.xcassets
    └── PrivacyInfo.xcprivacy
```

---

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

```
Feature: Quick Entry (text/voice) → Transaction
┌───────────────────────────────────────────────────────────────┐
│  User Input: "coffee 5.5" typed or dictated                   │
│       │                                                       │
│  ViewModel: QuickEntryViewModel                               │
│  └── QuickEntryParser.parse() → amountCents, merchantKey,     │
│      confidence                                               │
│      ├─ confidence ≥ 0.85 → auto-commit                       │
│      └─ confidence < 0.85 → AI fallback → confirm card        │
│       │                                                       │
│  DuplicateDetector.check() against ±3 day window              │
│      ├─ suspect → duplicate card (merge / keep both)          │
│      └─ clean → save                                          │
│       │                                                       │
│  ModelContext.insert(Transaction)  (idempotencyKey upsert)    │
│  MerchantMemory learn(correction)                             │
│       │                                                       │
│  Display: Home Safe to Spend animates, today's list appends   │
│       │                                                       │
│  Cross-feature: budgets recalc, widget snapshot refresh        │
└───────────────────────────────────────────────────────────────┘

Feature: Safe to Spend
┌───────────────────────────────────────────────────────────────┐
│  Inputs: Account.openingBalanceCents, Transaction rows,       │
│          Budget.limitCents, RecurringRule, InstallmentPlan    │
│       │                                                       │
│  SafeToSpendEngine.compute(mode:) → Int64 cents               │
│       │                                                       │
│  Home renders the number + progress bar                       │
│       │                                                       │
│  Cross-feature: App Group snapshot for the widget             │
└───────────────────────────────────────────────────────────────┘

Feature: Installments
┌───────────────────────────────────────────────────────────────┐
│  Input: total, periodCount, perPeriod, firstChargeDate, cadence│
│       │                                                       │
│  InstallmentEngine.validate() → throws on mismatch            │
│  InstallmentEngine.schedule() → [Date] with month-end clamp   │
│  InstallmentEngine.materializeDue() → Transaction + ruleID    │
│       │                                                       │
│  Ledger shows generated periods; Balance/Safe to Spend update │
└───────────────────────────────────────────────────────────────┘

Feature: Receipt OCR (Pro)
┌───────────────────────────────────────────────────────────────┐
│  Input: captured JPEG                                        │
│       │                                                       │
│  AIRouter.route(.receiptOCR)                                  │
│      ├─ BYO with vision → OpenAICompatClient                  │
│      ├─ GLM cloud quota → GLMClient (proxy)                   │
│      └─ fallback → Apple on-device (lower accuracy notice)     │
│       │                                                       │
│  Parsed ReceiptResult {merchant, total, tax, tip, items, cat} │
│       │                                                       │
│  Confirm card prefilled → save Transaction + receipt ref      │
└───────────────────────────────────────────────────────────────┘

Feature: Merchant Memory learning
┌───────────────────────────────────────────────────────────────┐
│  Input: user category correction on confirm card              │
│       │                                                       │
│  MerchantMemory upsert(lowercase+trim key, alias merge,       │
│  defaultCategoryID, hitCount + 1)                             │
│       │                                                       │
│  Next parse of the same merchant returns the learned category │
└───────────────────────────────────────────────────────────────┘

Feature: Shared Ledger (Pro)
┌───────────────────────────────────────────────────────────────┐
│  Input: CKShare invitation accepted                           │
│       │                                                       │
│  CloudKit records → upsert by idempotencyKey (never append)    │
│  Audit log records remote mutations                           │
│       │                                                       │
│  Per-creator attribution → participant-scoped statistics      │
└───────────────────────────────────────────────────────────────┘

Feature: Insights (Forecast / Radar / Wrapped / Weekly Pulse)
┌───────────────────────────────────────────────────────────────┐
│  Input: transactions, rules, plans, budgets                   │
│       │                                                       │
│  CashflowForecast / SubscriptionRadar / WrappedComposer       │
│       │                                                       │
│  Swift Charts + share card (9:16, watermark)                  │
└───────────────────────────────────────────────────────────────┘
```

**⚠️ VERIFICATION**: Every feature in the inventory has a traceable path from user input to persisted model to on-screen output. No view renders data without an engine or model behind it.

---

## Implementation Flow

1. **Project skeleton** — xcodegen `project.yml`, SwiftUI app target, App Group, SwiftData container.
2. **Data layer** — all models with default values and optional relationships; `MoneyFormatter`; enum definitions.
3. **Engines (pure local, deterministic)** — `QuickEntryParser`, `JaroWinkler`, `DuplicateDetector`, `InstallmentEngine`, `InterestEngine`, `BalanceEngine`, `SafeToSpendEngine`, `CashflowForecast`, `SubscriptionRadar`.
4. **Design system** — colors (mint `#00C48C`, dark base), typography scale, card component, entry bar.
5. **Onboarding** — 3 screens, creates the first account and first transaction.
6. **Home** — Safe to Spend hero number, period progress, today's list, persistent entry bar, confirm card, haptics.
7. **Ledger** — transaction list, search, edit, categories, recurring rules, installments.
8. **Insights** — charts, budgets, Weekly Pulse, subscription radar, Money Wrapped share card.
9. **AI layer** — `AIRouter`, BYO settings (Keychain), OpenAI-compatible client, GLM client, receipt OCR with degradation.
10. **Monetization** — StoreKit 2 products, entitlement manager, paywall with price anchors and legal links, restore.
11. **Settings** — accounts, AI configuration, iCloud toggle, export, policy links, contact support, dynamic version.
12. **Extensions** — lock screen widget, App Intents.
13. **Verification** — build for iPhone and iPad simulators, run onboarding → entry → paywall smoke path.

---

## UI/UX Design Specifications

- **Style**: iOS 26 native SwiftUI with a Liquid Glass sensibility; dark-first; large numeric typography; 20pt corner radii; SF Symbols throughout.
- **Primary color**: Mint **#00C48C** (success / positive / brand).
- **Background**: Near-black `#0B0F0E`; elevated surface `#151A18`; hairline separator `#242B28`.
- **Warning**: Amber `#FFB020`; danger `#FF5A5F`.
- **Text**: Primary `#F5F7F6`, secondary `#9AA5A1`.
- **Typography**: SF Pro. Safe to Spend 96pt monospaced-digit; section titles 22pt semibold; body 17pt; captions 13pt.
- **Home layout**:
  - Top: account chip + settings gear.
  - Hero: "Safe to Spend" label (13pt uppercase, tracking) + 96pt number.
  - Below hero: period progress bar + "left this week".
  - Middle: today's transactions grouped by merchant with category glyph.
  - Bottom: persistent entry bar pinned above the tab bar; mic and receipt icons inside it.
- **Tabs**: exactly three — Home / Ledger / Insights. No tab maze.
- **Entry confirm card**: appears as an inline sheet from the bar; shows amount (large), merchant, category chip row, account selector; primary action "Done" (return key).
- **Animations**: numeric roll for Safe to Spend on commit (0.35s spring); green check scale-in (0.2s); card presentation `.snappy`.
- **Haptics**: success on commit, selection on chips, warning on duplicate detection.
- **Money Wrapped**: 1080×1920 dark card, oversized numerals, mint accents, JotMoney wordmark and `#JotMoney` bottom-right.

---

## Code Generation Rules

1. All money is `Int64` cents; no floating point in financial math.
2. Core flows (balance, Safe to Spend, installments, interest, duplicates) are 100% local and deterministic — AI is input acceleration only.
3. Every write path uses an `idempotencyKey` upsert; installment materialization uses `generatedCount` for resumability.
4. SwiftData + CloudKit rules: defaults on all attributes, optional relationships, no `#Unique`, custom actor when needed.
5. Normalize merchant/account keys to lowercase+trim; display preserves the user's casing; merge aliases.
6. Never physically delete financial records — archive plus audit log.
7. Entitlement gating goes through one `StoreManager`; cloud AI calls are gated server-side.
8. No account, no analytics SDK, no tracking; privacy manifest declares no collection.
9. English-only UI copy, US English number and date formatting.
10. Version read dynamically from `Bundle.main.infoDictionary`; never hardcoded.
11. Comments only where logic is non-obvious; prefer self-describing names.

---

## Build & Deployment Checklist

- [ ] `project.yml` targets iOS 17.0, bundle id `com.zzoutuo.JotMoney`, display name JotMoney
- [ ] App Group configured for the widget snapshot
- [ ] SwiftData container created with all models registered
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) with no collected data types
- [ ] StoreKit configuration file for local testing (Pro Monthly / Pro Yearly / BYO Lifetime / Family)
- [ ] Build succeeds on iPhone and iPad simulators
- [ ] Fresh install → onboarding → first transaction → Home smoke path passes
- [ ] Free tier limits: 2 accounts, 1 budget, no OCR/shared ledger/forecast gates
- [ ] Paywall shows legal links, price, duration, restore
- [ ] Policy pages deployed (Support / Privacy / Terms) and linked from Settings
- [ ] App Store metadata and screenshots prepared separately
