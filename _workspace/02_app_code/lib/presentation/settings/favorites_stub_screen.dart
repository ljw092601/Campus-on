import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/widgets/state_views.dart';

/// S10 — Favorites. Full list (facility/guide segments, swipe-delete) lands in
/// week 3; favorites are already persisted locally via [favoritesProvider].
class FavoritesStubScreen extends StatelessWidget {
  const FavoritesStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.favorites_title)),
      body: EmptyStateView(
        icon: Symbols.star,
        title: l.favorites_empty_title,
        body: l.favorites_stub_body,
      ),
    );
  }
}
