import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';
import 'palette.dart';

/// Blocks the app when this version is too old, and offers recommended updates once per launch.
class UpdateGate extends StatefulWidget {
  const UpdateGate({
    super.key,
    required this.status,
    required this.onUpdate,
    required this.navigatorKey,
    required this.child,
  });

  final ValueListenable<UpdateStatus> status;
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onUpdate;
  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  bool _offered = false;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: widget.status,
        builder: (context, status, child) {
          if (status == UpdateStatus.required) return _Required(onUpdate: widget.onUpdate);
          if (status == UpdateStatus.recommended && !_offered) {
            _offered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _offer());
          }
          return child!;
        },
        child: widget.child,
      );

  void _offer() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    final l10n = AppLocalizations.of(navigator.context);
    showDialog<void>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        title: Text(l10n.updateAvailableTitle),
        content: Text(l10n.updateAvailableBody),
        actions: [
          TextButton(key: const Key('updateLater'), onPressed: () => Navigator.pop(context), child: Text(l10n.updateLater)),
          FilledButton(
            key: const Key('updateNow'),
            onPressed: () {
              Navigator.pop(context);
              widget.onUpdate();
            },
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }
}

class _Required extends StatelessWidget {
  const _Required({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('updateRequired'),
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.system_update_rounded, color: accent, size: 72),
            const SizedBox(height: 24),
            Text(l10n.updateRequiredTitle,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              l10n.updateRequiredBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('updateRequiredButton'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: background,
                minimumSize: const Size.fromHeight(56),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              onPressed: onUpdate,
              child: Text(l10n.updateRequiredButton),
            ),
          ]),
        ),
      ),
    );
  }
}
