import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/ad_service.dart';
import 'services/admob_ad_service.dart';
import 'services/premium_service.dart';
import 'services/sound_service.dart';
import 'services/stats_store.dart';
import 'ui/home_screen.dart';
import 'ui/palette.dart';
import 'ui/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final stats = await StatsStore.open();
  final firstLaunch = stats.firstLaunch();

  // Real ads and the "Remove Ads" purchase on Android only for now; web and iOS stay ad-free.
  final mobile = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  AdService ads = const NoAdService();
  PremiumService premium = NoPremiumService();
  WidgetBuilder? banner;
  ValueListenable<bool>? privacyOptionsRequired;
  VoidCallback? showPrivacyOptions;
  if (mobile) {
    final admob = AdMobAdService();
    final store = StorePremiumService(stats);
    premium = store;
    ads = PremiumAwareAdService(FrequencyCappedAdService(admob, firstLaunch: firstLaunch), () => store.isPremium);
    banner = (_) => admob.banner();
    privacyOptionsRequired = admob.privacyOptionsRequired;
    showPrivacyOptions = admob.showPrivacyOptions;
    admob.init();
    store.init();
  }

  runApp(BlockDailyApp(
    stats: stats,
    ads: ads,
    premium: premium,
    banner: banner,
    privacyOptionsRequired: privacyOptionsRequired,
    showPrivacyOptions: showPrivacyOptions,
    sound: AudioSoundService(muted: stats.muted, persist: stats.setMuted),
  ));
}

class BlockDailyApp extends StatelessWidget {
  const BlockDailyApp({
    super.key,
    required this.stats,
    required this.ads,
    required this.sound,
    this.premium,
    this.banner,
    this.privacyOptionsRequired,
    this.showPrivacyOptions,
    this.today = DateTime.now,
  });

  final StatsStore stats;
  final AdService ads;
  final SoundService sound;
  final PremiumService? premium;
  final WidgetBuilder? banner;
  final ValueListenable<bool>? privacyOptionsRequired;
  final VoidCallback? showPrivacyOptions;
  final DateTime Function() today;

  @override
  Widget build(BuildContext context) {
    return Services(
      stats: stats,
      ads: ads,
      sound: sound,
      premium: premium,
      banner: banner,
      privacyOptionsRequired: privacyOptionsRequired,
      showPrivacyOptions: showPrivacyOptions,
      today: today,
      child: MaterialApp(
        title: 'Block Daily',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: accent,
          scaffoldBackgroundColor: background,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
