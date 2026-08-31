import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Today's cafeteria menu — placeholder until the real menu page lands.
/// Lives under the home branch (`/home/dining`) so the tab bar stays visible.
class DiningMenuScreen extends StatelessWidget {
  const DiningMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.home_card_dining_title)),
      body: Center(
        child: Text(
          l.common_comingSoon,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
