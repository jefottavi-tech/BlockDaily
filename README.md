# Block Daily

Block puzzle (8×8, drag 3 pieces, clear rows and columns) for iOS, Android and web, free with ads.

- **Classic:** endless. Dealt pieces always include at least one that fits. One revive per game through a rewarded ad.
- **Daily:** one attempt per day, and every player gets the same piece sequence, so scores are comparable and shareable ("Block Daily #42 🧩 ⭐ 3,450 🔥 combo x7"). This is the free, organic growth loop.
- **Scoring:** 1 point per block placed, plus 10 × lines² × combo for clears, plus 300 for a perfect clear. A combo survives 3 placements without a clear.
- **Ads** go through `AdService` (currently `NoAdService`): an interstitial between games, a rewarded video to revive, and a space reserved for a bottom banner. Never during play.

```sh
flutter test              # engine, stats, share text and gameplay (drag & drop) tests
flutter run -d chrome     # or an Android device / iOS simulator
```

Code: `lib/game/` (pure Dart engine), `lib/services/` (stats, ads, share text), `lib/ui/`.
