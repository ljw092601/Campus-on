import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

/// Classroom-location search — placeholder until the real search UI lands.
/// Pushed full-screen above the shell at `/classroom-search` (root navigator),
/// entered from the home hero banner / its pill.
class ClassroomSearchScreen extends StatelessWidget {
  const ClassroomSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.classroom_search_title)),
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
