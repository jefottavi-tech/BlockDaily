import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

enum Sfx { pick, place, clear1, clear2, clear3, clear4, clear5, perfect, gameover }

abstract class SoundService {
  bool get muted;
  Future<void> setMuted(bool value);
  void play(Sfx sfx);

  /// Clear sound for a combo level: higher pitch for longer combos.
  static Sfx clearFor(int combo) => Sfx.values[Sfx.clear1.index + (combo.clamp(1, 5) - 1)];
}

class NoSound implements SoundService {
  @override
  bool muted = false;

  final played = <Sfx>[];

  @override
  Future<void> setMuted(bool value) async => muted = value;

  @override
  void play(Sfx sfx) {
    if (!muted) played.add(sfx);
  }
}

/// Short effects from assets/sfx (synthesized by tools/make_sfx.py), one small player pool each.
class AudioSoundService implements SoundService {
  AudioSoundService({required bool muted, required Future<void> Function(bool) persist})
      : _muted = muted, // ignore: prefer_initializing_formals
        _persist = persist; // ignore: prefer_initializing_formals

  bool _muted;
  final Future<void> Function(bool) _persist;
  final _pools = <Sfx, Future<AudioPool>>{};

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
    await _persist(value);
  }

  @override
  void play(Sfx sfx) {
    if (_muted) return;
    final pool = _pools.putIfAbsent(sfx, () => AudioPool.createFromAsset(path: 'sfx/${sfx.name}.wav', maxPlayers: 3));
    unawaited(() async {
      try {
        await (await pool).start(volume: 0.8);
      } catch (_) {
        // Browsers can refuse audio before the first user gesture; a missed effect is fine.
      }
    }());
  }
}
