import 'dart:math';

import 'package:block_daily/game/board.dart';
import 'package:block_daily/game/game.dart';
import 'package:block_daily/game/pieces.dart';
import 'package:block_daily/main.dart';
import 'package:block_daily/services/ad_service.dart';
import 'package:block_daily/services/sound_service.dart';
import 'package:block_daily/services/stats_store.dart';
import 'package:block_daily/ui/board_view.dart';
import 'package:block_daily/ui/game_screen.dart';
import 'package:block_daily/ui/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAds implements AdService {
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

final today = DateTime(2026, 10, 25); // daily #6

void checkerboard(Board b) {
  for (var r = 0; r < Board.size; r++) {
    for (var c = 0; c < Board.size; c++) {
      b.cells[r * Board.size + c] = (r + c).isEven ? 1 : 0;
    }
  }
}

void main() {
  late StatsStore stats;
  late FakeAds ads;
  late NoSound sound;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
    ads = FakeAds();
    sound = NoSound();
  });

  Future<void> pumpGame(WidgetTester tester, Game game) async {
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Services(
      stats: stats,
      ads: ads,
      sound: sound,
      today: () => today,
      child: MaterialApp(home: GameScreen(game: game)),
    ));
  }

  /// Drags the piece in [slot] so its top-left cell lands on (row, col).
  Future<void> drag(WidgetTester tester, Game game, int slot, int row, int col) async {
    final boardRect = tester.getRect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is BoardPainter));
    final cell = BoardPainter.cellSize(boardRect.width);
    final piece = game.tray[slot]!;
    final target = boardRect.topLeft +
        Offset(BoardPainter.padding + col * cell, BoardPainter.padding + row * cell) +
        Offset(piece.cols * cell / 2, piece.rows * cell + cell * 1.6);
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(Key('slot-$slot'))));
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  String text(WidgetTester tester, String key) => (tester.widget<Text>(find.byKey(Key(key)))).data!;

  testWidgets('dragging a piece onto the board places it and scores', (tester) async {
    final game = Game.classic(random: Random(4));
    await pumpGame(tester, game);
    final piece = game.tray[0]!;

    await drag(tester, game, 0, 2, 1);
    for (final c in piece.cells) {
      expect(game.board.at(2 + c.r, 1 + c.c), piece.color);
    }
    expect(text(tester, 'score'), '${piece.size}');
    expect(game.tray[0], isNull);
  });

  testWidgets('dropping outside the board does nothing', (tester) async {
    final game = Game.classic(random: Random(4));
    await pumpGame(tester, game);
    await drag(tester, game, 0, 12, 0);
    expect(game.board.isEmpty, isTrue);
    expect(game.tray[0], isNotNull);
  });

  testWidgets('completing a line clears it and shows the combo popup', (tester) async {
    final game = Game.classic(random: Random(4));
    for (var c = 0; c < 7; c++) {
      game.board.cells[7 * Board.size + c] = 3;
    }
    game.tray[0] = piecesById['dot'];
    await pumpGame(tester, game);
    await drag(tester, game, 0, 7, 7);
    expect(game.board.isEmpty, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('+311'), findsOneWidget); // 1 + 10 + 300 perfect clear
    expect(find.text('PERFECT!'), findsOneWidget);
    expect(sound.played, [Sfx.pick, Sfx.perfect]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('game over offers one revive through a rewarded ad, then records the best', (tester) async {
    final game = Game.classic(random: Random(4));
    checkerboard(game.board);
    game.tray.setAll(0, [piecesById['dot'], piecesById['o2'], piecesById['o2']]);
    await pumpGame(tester, game);

    await drag(tester, game, 0, 0, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No more space'), findsOneWidget);
    expect(stats.bestScore, 0, reason: 'not recorded while a revive is possible');

    await tester.tap(find.byKey(const Key('revive')));
    await tester.pump();
    expect(ads.rewarded, 1);
    expect(find.text('No more space'), findsNothing);
    expect(game.isOver, isFalse);

    // Make it end again: no second revive, score recorded as best.
    checkerboard(game.board);
    game.tray.setAll(0, [piecesById['dot'], piecesById['o2'], piecesById['o2']]);
    await tester.pump();
    await drag(tester, game, 0, 0, 3);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('revive')), findsNothing);
    expect(stats.bestScore, game.score);
    expect(find.text('🏆 New best!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('again')));
    await tester.pump();
    expect(ads.interstitials, 1);
    expect(text(tester, 'score'), '0');
  });

  testWidgets('daily: no revive, result saved once, home shows it', (tester) async {
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BlockDailyApp(stats: stats, ads: ads, sound: sound, today: () => today));
    expect(find.text('Daily #6'), findsOneWidget);
    expect(find.text('Same pieces for everyone today'), findsOneWidget);

    await tester.tap(find.byKey(const Key('daily')));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(GameScreen));
    final game = (state.widget as GameScreen).game;
    expect(game.mode, GameMode.daily);
    checkerboard(game.board);
    game.tray.setAll(0, [piecesById['dot'], piecesById['o2'], piecesById['o2']]);
    await tester.pump();
    await drag(tester, game, 0, 0, 1);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Daily complete!'), findsOneWidget);
    expect(find.byKey(const Key('revive')), findsNothing);
    expect(find.byKey(const Key('share')), findsOneWidget);
    expect(stats.daily(6)!.score, 1);

    await tester.tap(find.byKey(const Key('home')));
    await tester.pumpAndSettle();
    expect(find.text('Score 1 · tap to share'), findsOneWidget);
    expect(find.text('🔥 1'), findsOneWidget);
  });

  testWidgets('an unfinished classic game is saved and resumed from home', (tester) async {
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BlockDailyApp(stats: stats, ads: ads, sound: sound, today: () => today));
    expect(find.text('PLAY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play')));
    await tester.pumpAndSettle();
    var game = (tester.widget<GameScreen>(find.byType(GameScreen))).game;
    // The new game deals random pieces; use a known one so the drop lands every time.
    game.tray[0] = piecesById['dot'];
    await tester.pump();
    final piece = game.tray[0]!;
    await drag(tester, game, 0, 0, 0);
    await tester.pumpAndSettle();
    expect(stats.savedGame('classic'), isNotNull);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.byKey(const Key('play')));
    await tester.pumpAndSettle();
    game = (tester.widget<GameScreen>(find.byType(GameScreen))).game;
    expect(game.score, piece.size);
    expect(game.board.at(0, 0), piece.color);
  });

  testWidgets('a daily left unfinished yesterday is recorded, today starts fresh', (tester) async {
    final yesterday = Game.daily(5)..score = 42;
    await stats.saveGame('daily', yesterday.toJson());
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BlockDailyApp(stats: stats, ads: ads, sound: sound, today: () => today));
    await tester.tap(find.byKey(const Key('daily')));
    await tester.pumpAndSettle();
    expect(stats.daily(5)!.score, 42);
    final game = (tester.widget<GameScreen>(find.byType(GameScreen))).game;
    expect(game.dailyNumber, 6);
    expect(game.score, 0);
  });

  testWidgets('mute toggle silences effects', (tester) async {
    final game = Game.classic(random: Random(4));
    await pumpGame(tester, game);
    await tester.tap(find.byKey(const Key('mute')));
    await tester.pump();
    expect(sound.muted, isTrue);
    await drag(tester, game, 0, 0, 0);
    expect(sound.played, isEmpty);
  });

  test('praise grows with the number of lines', () {
    expect(praiseFor(1), '');
    expect(praiseFor(2), 'Great!');
    expect(praiseFor(3), 'Amazing!');
    expect(praiseFor(5), 'Unbelievable!');
    expect(praiseFor(1, perfect: true), 'PERFECT!');
  });
}
