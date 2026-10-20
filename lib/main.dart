import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/ad_service.dart';
import 'services/stats_store.dart';
import 'ui/home_screen.dart';
import 'ui/palette.dart';
import 'ui/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(BlockDailyApp(stats: await StatsStore.open(), ads: const NoAdService()));
}

class BlockDailyApp extends StatelessWidget {
  const BlockDailyApp({super.key, required this.stats, required this.ads, this.today = DateTime.now});

  final StatsStore stats;
  final AdService ads;
  final DateTime Function() today;

  @override
  Widget build(BuildContext context) {
    return Services(
      stats: stats,
      ads: ads,
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
