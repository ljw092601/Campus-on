import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/widgets/state_views.dart';

/// S5–S7 (guide categories / item list / detail) are implemented in week 3.
/// This stub keeps the Guide tab route live so navigation & deep links resolve.
class GuideStubScreen extends StatelessWidget {
  const GuideStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.guide_stub_title)),
      body: EmptyStateView(
        icon: Symbols.checklist,
        title: l.guide_stub_title,
        body: l.guide_stub_body,
      ),
    );
  }
}
