import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/ad_service.dart';
import 'services/sound_service.dart';
import 'services/stats_store.dart';
import 'ui/home_screen.dart';
import 'ui/palette.dart';
import 'ui/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final stats = await StatsStore.open();
  runApp(BlockDailyApp(
    stats: stats,
    ads: const NoAdService(),
    sound: AudioSoundService(muted: stats.muted, persist: stats.setMuted),
  ));
}

class BlockDailyApp extends StatelessWidget {
  const BlockDailyApp({
    super.key,
    required this.stats,
    required this.ads,
    required this.sound,
    this.today = DateTime.now,
  });

  final StatsStore stats;
  final AdService ads;
  final SoundService sound;
  final DateTime Function() today;

  @override
  Widget build(BuildContext context) {
    return Services(
      stats: stats,
      ads: ads,
      sound: sound,
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
