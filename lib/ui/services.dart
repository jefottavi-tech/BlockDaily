import 'package:flutter/widgets.dart';

import '../services/ad_service.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';

/// App-wide services, available to every screen.
class Services extends InheritedWidget {
  const Services({super.key, required this.stats, required this.ads, required this.sound, required this.today, required super.child});

  final StatsStore stats;
  final AdService ads;
  final SoundService sound;

  /// Injectable clock for the daily puzzle.
  final DateTime Function() today;

  static Services of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Services>()!;

  @override
  bool updateShouldNotify(Services old) => old.stats != stats || old.ads != ads || old.sound != sound;
}
