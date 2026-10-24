import 'package:block_daily/main.dart';
import 'package:block_daily/services/ad_service.dart';
import 'package:block_daily/services/sound_service.dart';
import 'package:block_daily/services/stats_store.dart';
import 'package:block_daily/services/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('status from Remote Config versions', () {
    expect(updateStatusFor(build: 5, minVersion: 0, recommendedVersion: 0), UpdateStatus.none);
    expect(updateStatusFor(build: 5, minVersion: 5, recommendedVersion: 5), UpdateStatus.none);
    expect(updateStatusFor(build: 5, minVersion: 0, recommendedVersion: 6), UpdateStatus.recommended);
    expect(updateStatusFor(build: 5, minVersion: 6, recommendedVersion: 6), UpdateStatus.required);
    expect(updateStatusFor(build: 5, minVersion: 6, recommendedVersion: 0), UpdateStatus.required);
  });

  group('update gate', () {
    late StatsStore stats;
    late ValueNotifier<UpdateStatus> status;
    late int updates;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      stats = await StatsStore.open();
      status = ValueNotifier(UpdateStatus.none);
      updates = 0;
    });

    Future<void> pumpApp(WidgetTester tester, {Locale? locale}) async {
      tester.view.physicalSize = const Size(412, 880);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlockDailyApp(
        stats: stats,
        ads: const NoAdService(),
        sound: NoSound(),
        updateStatus: status,
        onUpdate: () => updates++,
        today: () => DateTime(2026, 10, 25),
        locale: locale,
      ));
    }

    testWidgets('update prompts in French', (tester) async {
      await pumpApp(tester, locale: const Locale('fr'));
      status.value = UpdateStatus.recommended;
      await tester.pumpAndSettle();
      expect(find.text('Mise à jour disponible'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
      expect(find.text('Mettre à jour'), findsOneWidget);
      await tester.tap(find.byKey(const Key('updateLater')));
      await tester.pumpAndSettle();
      status.value = UpdateStatus.required;
      await tester.pump();
      expect(find.text('Mise à jour requise'), findsOneWidget);
      expect(find.text('METTRE À JOUR'), findsOneWidget);
    });

    testWidgets('required update blocks the game', (tester) async {
      await pumpApp(tester);
      expect(find.text('PLAY'), findsOneWidget);
      status.value = UpdateStatus.required;
      await tester.pump();
      expect(find.text('PLAY'), findsNothing);
      await tester.tap(find.byKey(const Key('updateRequiredButton')));
      expect(updates, 1);
    });

    testWidgets('recommended update is offered once and can be dismissed', (tester) async {
      await pumpApp(tester);
      status.value = UpdateStatus.recommended;
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
      await tester.tap(find.byKey(const Key('updateLater')));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsNothing);
      expect(find.text('PLAY'), findsOneWidget);
      expect(updates, 0);
    });
  });
}
