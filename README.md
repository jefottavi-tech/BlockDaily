# Block Daily

Block puzzle (8×8, drag 3 pieces, clear rows and columns) for Android (iOS later), free with ads. There is no public web version: play.kallistesoft.ca only serves the "coming to Google Play" page in `web_closed/`.

- **Classic:** endless. Dealt pieces always include at least one that fits. One revive per game through a rewarded ad.
- **Daily:** one attempt per day, and every player gets the same piece sequence, so scores are comparable and shareable ("Block Daily #42 🧩 ⭐ 3,450 🔥 combo x7"). This is the free, organic growth loop.
- **Scoring:** 1 point per block placed, plus 10 × lines² × combo for clears, plus 300 for a perfect clear. A combo survives 3 placements without a clear.
- **Ads** go through `AdService`: AdMob on Android (interstitial between games, rewarded revive, bottom banner), never during play. Web and iOS are ad-free for now. A one-time "No ads" purchase (`remove_ads`) removes interstitials and the banner.
- **Updates** (Android): Firebase Remote Config, project `block-daily-b71d6` (contact@kallistesoft.ca). See below.

## Forcing or suggesting an update

In the Firebase console › Remote Config, set a Number parameter to a `versionCode` (the `+N` in `pubspec.yaml`'s `version`) and publish:

| Parameter | Effect on builds below that versionCode |
|---|---|
| `min_version_code` | Full-screen "Update required"; the game is blocked until updated |
| `recommended_version_code` | "Update available" dialog with Later, once per launch |
| `…_debug` variants | The same, for debug builds only (to try the screens) |

0 means off. Publish the new release on Play first, wait until it is available, then raise the value. The update goes through Play's in-app update screen (the Play Store page for test installs).

`android/app/google-services.json` is not in git (public repo): download it from the Firebase console (project settings › Block Daily Android) for local Android builds. CI gets it from the `GOOGLE_SERVICES_JSON` secret.

```sh
flutter test              # engine, stats, share text and gameplay (drag & drop) tests
flutter run               # on an Android device or emulator (chrome still works for quick UI checks)
```

Code: `lib/game/` (pure Dart engine), `lib/services/` (stats, ads, share text), `lib/ui/`.
