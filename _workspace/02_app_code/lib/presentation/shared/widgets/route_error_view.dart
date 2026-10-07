import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'state_views.dart';

/// Full-screen "page not found" shown by go_router's `errorBuilder` (audit
/// L-10): unknown or malformed locations used to land on the framework's
/// English "Page Not Found" text with no way back. The only action is a
/// return to the home tab, which also resets the shell to a known state.
class RouteErrorView extends StatelessWidget {
  const RouteErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.route_notFound_title)),
      body: EmptyStateView(
        icon: Symbols.explore_off,
        title: l.route_notFound_title,
        body: l.route_notFound_body,
        actionLabel: l.route_notFound_home,
        onAction: () => context.go('/home'),
      ),
    );
  }
}
