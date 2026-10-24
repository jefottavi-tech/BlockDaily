/// Ad placements. Screens only use this interface, so the AdMob (mobile) and
/// portal SDK (web) implementations can be swapped in without touching gameplay.
abstract class AdService {
  /// Between games. Implementations enforce the frequency cap.
  Future<void> showInterstitial();

  /// Rewarded video; returns true if the player earned the reward.
  Future<bool> showRewarded();
}

/// Development stand-in: no ads, rewards always granted.
class NoAdService implements AdService {
  const NoAdService();

  @override
  Future<void> showInterstitial() async {}

  @override
  Future<bool> showRewarded() async => true;
}

/// Keeps interstitials rare: none in a new player's first minutes, then at most one per [gap].
/// Rewarded ads are opt-in, so they pass through.
class FrequencyCappedAdService implements AdService {
  FrequencyCappedAdService(
    this._inner, {
    required this.firstLaunch,
    this.clock = DateTime.now,
    this.grace = const Duration(minutes: 3),
    this.gap = const Duration(seconds: 90),
  });

  final AdService _inner;
  final DateTime firstLaunch;
  final DateTime Function() clock;
  final Duration grace;
  final Duration gap;
  DateTime? _last;

  @override
  Future<void> showInterstitial() async {
    final now = clock();
    if (now.difference(firstLaunch) < grace) return;
    if (_last != null && now.difference(_last!) < gap) return;
    _last = now;
    await _inner.showInterstitial();
  }

  @override
  Future<bool> showRewarded() => _inner.showRewarded();
}

/// "Remove Ads" owners get no interstitials; the rewarded Continue stays available.
class PremiumAwareAdService implements AdService {
  const PremiumAwareAdService(this._inner, this._isPremium);

  final AdService _inner;
  final bool Function() _isPremium;

  @override
  Future<void> showInterstitial() async {
    if (!_isPremium()) await _inner.showInterstitial();
  }

  @override
  Future<bool> showRewarded() => _inner.showRewarded();
}
