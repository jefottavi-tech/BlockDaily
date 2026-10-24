# Block Daily: remaining steps to production (Google Play)

Status as of 2026-10-24. Android first; iOS needs an Apple developer account (later).
**Owner:** *you* = the account owner, *Claude* = can be done by Claude, *Google* = waiting on Google.

## Done

- [x] Real AdMob ads on Android: interstitial at game over (capped: none in the first 3 min, then at most one per 90 s), rewarded Continue, banner. Consent (EU/UK, US states) with a Privacy options link.
- [x] AdMob (contact@kallistesoft.ca, pub-7557144664039757): app `~3884220247`, 3 ad units, ad content rating **T**, sensitive categories blocked (alcohol, gambling, dating, get-rich, sexual, social casino).
- [x] Remove Ads purchase in code (`remove_ads`), with a parental gate and Restore purchase. The button stays hidden until the product exists on Play.
- [x] Kallistesoft-branded icon (Android adaptive, iOS, web) and app name "Block Daily".
- [x] App ID `ca.kallistesoft.block_daily` (iOS `ca.kallistesoft.blockDaily`).
- [x] Force / recommended update through Firebase Remote Config (project `block-daily-b71d6`); see README.
- [x] Play developer account is an **organization** account (KallisteSoft), so the 14-day / 12-tester closed test doesn't apply.
- [x] Payments profile created; enrolled in the **15% service fee** program.

## Remaining

### 1. Privacy policy live (*you*)
- [x] Block Daily section live (kallistesoft-site#1).
- [ ] Merge kallistesoft-site#2: dedicated page /en/privacy/block-daily/. Then point the AdMob EU consent message for Block Daily at it (*Claude*).

### 2. Release signing (*Claude*, then *you* back it up)
- [ ] Create the upload keystore and wire it into the release build (`key.properties`, kept out of git). Release builds are still signed with the debug key.
- [ ] **You:** back up the keystore file and its password (password manager plus a copy off this Mac). Losing it means you can no longer update the app.
- [ ] Add the keystore as GitHub secrets for a future Android CI job.

### 3. Crash reporting (*Claude*, recommended)
- [ ] Firebase Crashlytics in the existing project, plus one line in the privacy policy.

### 4. Create the app in Play Console (*Claude* through Chrome, *you* approve the declarations)
- [ ] Create "Block Daily": game, free, default language English.
- [ ] Register `ca.kallistesoft.block_daily` under **Android developer verification** if Google requires it.

### 5. First upload: internal testing (*Claude*)
- [ ] Bump the version if needed, build the signed AAB, upload it to internal testing (this enables Play App Signing).
- [ ] Add your Gmail as an internal tester and install from Play on your Pixel.

### 6. Remove Ads product (*Claude*, after step 5)
- [ ] Create the in-app product `remove_ads` at **$3.99 CAD** (local prices auto-converted) and activate it.
- [ ] Add your Gmail under **License testing** (free test purchases).
- [ ] On the Pixel: buy, then check the banner and interstitials are gone; reinstall, then Restore purchase.

### 7. Store listing and policy forms (*Claude* drafts through Chrome, *you* review)
- [ ] Short and full description (EN; FR next).
- [ ] Phone screenshots (from the emulator), 1024×500 feature graphic, 512 px icon.
- [ ] Content rating questionnaire (expected: Everyone / PEGI 3).
- [ ] Target audience **13+** (family-friendly, not designed for children).
- [ ] Ads declaration: **contains ads**.
- [ ] **Data safety**: advertising ID (AdMob), Firebase installation ID (Remote Config), purchase history (Play), approximate location from IP (ads); no account, no data sold.
- [ ] Privacy policy URL: https://kallistesoft.ca/en/privacy/block-daily/ (FR: /confidentialite/block-daily/)
- [ ] App access: no login needed.

### 8. Final checks (*you* plus *Claude*)
- [ ] 10-minute play session on the Pixel (internal test build from Play): full-screen ad, Continue video, Remove Ads purchase, daily share.
- [ ] Release build smoke test on the emulator (startup, no crash).
- [ ] Bank account verified in the payments profile (*Google*: test deposit, then *you* confirm the amount).

### 9. Production release (*you* press the button)
- [ ] Promote the internal build to production (all countries except where Play isn't available).
- [ ] Google review: usually a few days for a new app.

### 10. Right after launch (*Claude*)
- [ ] Link the AdMob app to the Play listing (lifts limited ad serving; AdMob reviews the app).
- [ ] Check app-ads.txt is detected for Block Daily.
- [ ] Watch Crashlytics, AdMob fill rate and reviews during the first week.

## Later (not blocking launch)

- Automated tests: PR CI with Android builds, a release smoke test on an emulator, and integration tests (deferred on 2026-10-24).
- Store listing in 15+ languages, then in-app translations.
- Share link in the daily result text (`play.kallistesoft.ca` or the store), plus sharing for classic games.
- iOS release (Apple developer account, AdMob iOS app, App Store Connect).
- The same branded icons for Neon Breaker, Void Raid, Neon Pop, Neon Snake and Neon Stack.
