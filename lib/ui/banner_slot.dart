import 'package:flutter/material.dart';

import 'services.dart';

/// Strip under the tray for the banner ad; collapses once "Remove Ads" is bought.
class BannerSlot extends StatelessWidget {
  const BannerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return ListenableBuilder(
      listenable: services.premium,
      builder: (context, _) => services.premium.isPremium
          ? const SizedBox.shrink()
          : SizedBox(height: 56, child: Center(child: services.banner?.call(context))),
    );
  }
}
