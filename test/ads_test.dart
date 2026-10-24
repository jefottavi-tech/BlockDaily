
import 'package:block_daily/main.dart';
import 'package:block_daily/services/ad_service.dart';
import 'package:block_daily/services/premium_service.dart';
import 'package:block_daily/services/sound_service.dart';
import 'package:block_daily/services/stats_store.dart';
import 'package:block_daily/ui/banner_slot.dart';
import 'package:block_daily/ui/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingAds implements AdService {
  int interstitials = 0;
  int rewarded = 0;
  @override
  Future<void> showInterstitial() async => interstitials++;
  @override
  Future<bool> showRewarded() async {
    rewarded++;
    return true;
  }
}

class FakePremium extends PremiumService {
  FakePremium({this.available = true});

  @override
  bool available;
  @override
  bool isPremium = false;
  int buys = 0;
  @override
  String? get price => '\$3.99';
  @override
  Future<void> buy() async {
    buys++;
    isPremium = true;
    available = false;
    notifyListeners();
  }

  @override
  Future<void> restore() async {}
}

void main() {
  group('frequency cap', () {
    final start = DateTime(2026, 10, 24, 12);
    late DateTime now;
    late CountingAds inner;
    late FrequencyCappedAdService ads;

    setUp(() {
      now = start;
      inner = CountingAds();
      ads = FrequencyCappedAdService(inner, firstLaunch: start, clock: () => now);
    });

    test('no interstitial in the first 3 minutes', () async {
      now = start.add(const Duration(minutes: 2, seconds: 59));
      await ads.showInterstitial();
      expect(inner.interstitials, 0);
      now = start.add(const Duration(minutes: 3));
      await ads.showInterstitial();
      expect(inner.interstitials, 1);
    });

    test('at most one interstitial per 90 seconds', () async {
      now = start.add(const Duration(minutes: 10));
      await ads.showInterstitial();
      now = now.add(const Duration(seconds: 89));
      await ads.showInterstitial();
      expect(inner.interstitials, 1);
      now = now.add(const Duration(seconds: 1));
      await ads.showInterstitial();
      expect(inner.interstitials, 2);
    });

    test('rewarded is never capped', () async {
      expect(await ads.showRewarded(), isTrue);
      expect(await ads.showRewarded(), isTrue);
      expect(inner.rewarded, 2);
    });
  });

  test('premium skips interstitials but keeps the rewarded Continue', () async {
    var premium = false;
    final inner = CountingAds();
    final ads = PremiumAwareAdService(inner, () => premium);
    await ads.showInterstitial();
    premium = true;
    await ads.showInterstitial();
    expect(await ads.showRewarded(), isTrue);
    expect(inner.interstitials, 1);
    expect(inner.rewarded, 1);
  });

  group('home and banner', () {
    late StatsStore stats;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      stats = await StatsStore.open();
    });

    Future<void> pumpHome(WidgetTester tester, PremiumService premium) async {
      tester.view.physicalSize = const Size(412, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlockDailyApp(
          stats: stats, ads: CountingAds(), sound: NoSound(), premium: premium, today: () => DateTime(2026, 10, 25)));
    }

    testWidgets('No ads is hidden when the store has no product', (tester) async {
      await pumpHome(tester, FakePremium(available: false));
      expect(find.byKey(const Key('removeAds')), findsNothing);
    });

    testWidgets('a wrong grown-up answer does not buy', (tester) async {
      final premium = FakePremium();
      await pumpHome(tester, premium);
      expect(find.textContaining('No ads · \$3.99'), findsOneWidget);
      await tester.tap(find.byKey(const Key('removeAds')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('parentAnswer')), '1');
      await tester.tap(find.byKey(const Key('parentOk')));
      await tester.pumpAndSettle();
      expect(premium.buys, 0);
    });

    testWidgets('the right answer buys and hides the offer', (tester) async {
      final premium = FakePremium();
      await pumpHome(tester, premium);
      await tester.tap(find.byKey(const Key('removeAds')));
      await tester.pumpAndSettle();
      final question = tester.widget<Text>(find.textContaining('×')).data!;
      final nums = RegExp(r'\d+').allMatches(question).map((m) => int.parse(m[0]!)).toList();
      await tester.enterText(find.byKey(const Key('parentAnswer')), '${nums[0] * nums[1]}');
      await tester.tap(find.byKey(const Key('parentOk')));
      await tester.pumpAndSettle();
      expect(premium.buys, 1);
      expect(find.byKey(const Key('removeAds')), findsNothing);
    });

    testWidgets('Privacy options shows only where consent rules require it', (tester) async {
      final required = ValueNotifier(false);
      var opened = 0;
      tester.view.physicalSize = const Size(412, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlockDailyApp(
          stats: stats,
          ads: CountingAds(),
          sound: NoSound(),
          privacyOptionsRequired: required,
          showPrivacyOptions: () => opened++,
          today: () => DateTime(2026, 10, 25)));
      expect(find.byKey(const Key('privacy')), findsNothing);
      required.value = true;
      await tester.pump();
      await tester.tap(find.byKey(const Key('privacy')));
      expect(opened, 1);
    });

    testWidgets('banner slot collapses once premium', (tester) async {
      final premium = FakePremium();
      await tester.pumpWidget(Services(
        stats: stats,
        ads: CountingAds(),
        sound: NoSound(),
        today: DateTime.now,
        premium: premium,
        banner: (_) => const Text('ad', key: Key('banner')),
        child: const MaterialApp(home: Scaffold(body: Column(children: [BannerSlot()]))),
      ));
      expect(find.byKey(const Key('banner')), findsOneWidget);
      await premium.buy();
      await tester.pump();
      expect(find.byKey(const Key('banner')), findsNothing);
    });
  });

}
