import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateStatus { none, recommended, required }

/// Compares this build with the versions set in Remote Config (0 = no requirement).
UpdateStatus updateStatusFor({required int build, required int minVersion, required int recommendedVersion}) {
  if (build < minVersion) return UpdateStatus.required;
  if (build < recommendedVersion) return UpdateStatus.recommended;
  return UpdateStatus.none;
}

/// Force / suggest updates from Firebase Remote Config (project block-daily-b71d6).
///
/// Parameters (Number): `min_version_code` blocks older builds, `recommended_version_code` offers the update.
/// Debug builds read the `_debug` variants instead, so the screens can be tried without touching players.
class UpdateService {
  static const _playUrl = 'https://play.google.com/store/apps/details?id=ca.kallistesoft.block_daily';

  final status = ValueNotifier(UpdateStatus.none);
  int _build = 0;

  String _key(String name) => kDebugMode ? '${name}_debug' : name;

  Future<void> check() async {
    try {
      _build = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
      await Firebase.initializeApp();
      final config = FirebaseRemoteConfig.instance;
      await config.setDefaults({
        for (final name in ['min_version_code', 'recommended_version_code']) ...{name: 0, '${name}_debug': 0},
      });
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      // Offline: the values from the last successful fetch still apply.
      await config.fetchAndActivate().catchError((_) => false);
      status.value = updateStatusFor(
        build: _build,
        minVersion: config.getInt(_key('min_version_code')),
        recommendedVersion: config.getInt(_key('recommended_version_code')),
      );
    } catch (_) {
      // No Firebase or no network on first launch: never block the game for that.
    }
  }

  /// Google Play's in-app update screen; the store page when the app wasn't installed from Play.
  Future<void> update() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
    } catch (_) {
      // Not installed from Play (test builds) or Play unavailable.
    }
    await launchUrl(Uri.parse(_playUrl), mode: LaunchMode.externalApplication);
  }
}
