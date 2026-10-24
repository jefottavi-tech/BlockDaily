import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';

/// Opens the share sheet; falls back to the clipboard where sharing isn't available (desktop web).
Future<void> shareText(BuildContext context, String text) async {
  final messenger = ScaffoldMessenger.of(context);
  final copied = AppLocalizations.of(context).shareCopied;
  try {
    final result = await SharePlus.instance.share(ShareParams(text: text));
    if (result.status != ShareResultStatus.unavailable) return;
  } catch (_) {
    // Fall through to the clipboard.
  }
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(SnackBar(content: Text(copied)));
}
