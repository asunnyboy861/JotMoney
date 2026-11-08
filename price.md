# Pricing Configuration

## Monetization Model: Freemium with IAP (Auto-Renewable Subscriptions + One-Time Buyout)

JotMoney is free to download with a fully functional free tier. Pro features are unlocked by an auto-renewable subscription (monthly or yearly, primary) or a Family subscription, and there is a single non-consumable BYO Lifetime purchase for users who want to own the app forever and supply their own AI key.

## Subscription Group

- **Group Name**: JotMoney Pro
- **Reference Name**: JotMoney Pro
- **Products in group**: `com.zzoutuo.jotmoney.pro.monthly`, `com.zzoutuo.jotmoney.pro.yearly`, `com.zzoutuo.jotmoney.family.yearly`

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription

- **Reference Name**: JotMoney Pro Monthly
- **Product ID**: `com.zzoutuo.jotmoney.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $3.99 USD per month
- **Display Name**: `JotMoney Pro Monthly` (20 chars, ≤35 ✅)
- **Description**: `Unlimited accounts, budgets, receipts and sync.` (49 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: JotMoney Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription ⭐ Primary

- **Reference Name**: JotMoney Pro Annual
- **Product ID**: `com.zzoutuo.jotmoney.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $19.99 USD per year (58% savings vs monthly)
- **Display Name**: `JotMoney Pro Annual` (19 chars, ≤35 ✅)
- **Description**: `Every Pro feature. Free for 7 days, cancel anytime.` (51 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: JotMoney Pro (same group as monthly)
- **Free Trial**: 7 days (introductory offer)
- **Restore Purchases**: ✅ Required

### 3. Family Yearly Subscription

- **Reference Name**: JotMoney Family Annual
- **Product ID**: `com.zzoutuo.jotmoney.family.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year
- **Display Name**: `JotMoney Family Annual` (22 chars, ≤35 ✅)
- **Description**: `Pro for up to 8 people with a shared ledger.` (45 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: JotMoney Pro (same group as monthly/yearly)
- **Restore Purchases**: ✅ Required
- **Differentiation Note**: Family includes everything in Pro Annual plus a shared ledger for up to 8 people and a household net-worth view. It is the only tier that raises the shared-ledger seat limit above 5.

## One-Time Purchases (Non-Consumable)

### 1. BYO Lifetime

- **Reference Name**: JotMoney BYO Lifetime
- **Product ID**: `com.zzoutuo.jotmoney.pro.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $59.99 USD (one-time)
- **Display Name**: `JotMoney BYO Lifetime` (21 chars, ≤35 ✅)
- **Description**: `Own it forever. Use your own AI key, unlimited.` (47 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Differentiation Note**: BYO Lifetime permanently unlocks every Pro app feature but does **not** include the built-in GLM cloud AI quota (a metered third-party cost). Instead, the user pastes their own OpenAI-compatible API key (GLM, OpenAI, Gemini, Claude, DeepSeek, or custom) and AI usage is unlimited at their own cost. Subscriptions include the built-in quota; Lifetime does not.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - Unlimited manual and quick-entry transactions (deterministic parser is unlimited)
  - 2 accounts with opening balances, net worth, and Safe to Spend
  - 1 budget
  - Categories, notes, and search
  - Merchant memory learning
  - Apple on-device AI parsing: 10 uses per day
  - Duplicate detection and merge
  - Installments and recurring rules
  - CSV export
  - Offline use, no account, no tracking
  - Lock screen Safe to Spend widget
- **Conversion hooks**:
  - "You have 2 accounts. Pro unlocks unlimited accounts and budgets."
  - "Receipt scanning reads the total, tax, and tip for you — Pro."
  - "Forecast your next 30 days and catch subscriptions you forgot about — Pro."
  - "Sync across your iPhone and iPad with iCloud — Pro."

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (Monthly / Yearly / Family) |
|---------|:----:|:-------------------------------:|
| Quick entry & deterministic parsing | ✅ Unlimited | ✅ Unlimited |
| Accounts | ✅ 2 | ✅ Unlimited |
| Budgets | ✅ 1 | ✅ Unlimited |
| Safe to Spend, net worth, duplicate detection | ✅ | ✅ |
| Installments, recurring rules, CSV export | ✅ | ✅ |
| Apple on-device AI parsing | ✅ 10 / day | ✅ Unlimited |
| Receipt OCR (built-in GLM cloud quota) | ❌ | ✅ 30 / month |
| Money Coach (built-in GLM cloud quota) | ❌ | ✅ 60 messages / month |
| Cashflow forecast (30 days) | ❌ | ✅ |
| Subscription radar | ❌ | ✅ |
| iCloud sync across devices | ❌ | ✅ |
| Shared ledger (CKShare) | ❌ | ✅ Up to 5 people |
| Shared ledger seats | — | ✅ Family: up to 8 people |
| Household net-worth view | ❌ | ✅ Family only |
| Money Wrapped premium card designs | ❌ | ✅ |
| Lock screen Safe to Spend widget | ✅ | ✅ |
| BYO custom AI key (unlimited AI) | ❌ | ❌ Separate $59.99 one-time purchase |

## Free Trial

- **Duration**: 7 days
- **Type**: Free trial (introductory offer, auto-converts to the paid annual subscription)
- **Available for**: Pro Yearly only

## Policy Pages Required

- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (required — the app offers auto-renewable subscriptions)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist

- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView
- [x] Free trial terms included (7 days, Pro Yearly)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (paywall shows only JotMoney's own products)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO model: Lifetime is gated only by one-time unlock plus the user's own key — no generation counting
