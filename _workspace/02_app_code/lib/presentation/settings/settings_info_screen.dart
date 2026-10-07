import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/config/app_config.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../shared/external_links.dart';

/// Which static info page to render (Settings sub-pages, S9).
enum SettingsInfoType { about, dataSource, contact }

/// S9 sub-page — a simple static text page for About / Data sources / Contact.
/// The Contact variant adds a "send email" action.
class SettingsInfoScreen extends StatelessWidget {
  const SettingsInfoScreen({super.key, required this.type});

  final SettingsInfoType type;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = context.dimens;

    final (title, body) = switch (type) {
      SettingsInfoType.about => (l.settings_about, l.settings_about_body),
      SettingsInfoType.dataSource => (
          l.settings_dataSource,
          l.settings_dataSource_body
        ),
      SettingsInfoType.contact => (l.settings_contact, l.settings_contact_body),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: EdgeInsets.all(d.spaceMd),
        children: [
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          if (type == SettingsInfoType.contact) ...[
            SizedBox(height: d.spaceLg),
            FilledButton.tonalIcon(
              onPressed: () => _sendEmail(context, AppConfig.contactEmail),
              icon: const Icon(Symbols.mail),
              label: Text(l.settings_contact_emailLabel),
            ),
            SizedBox(height: d.spaceSm),
            SelectableText(
              AppConfig.contactEmail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    // Localized subject (audit L-31) and the shared "couldn't open" notice
    // when no mail client handles the link (audit L-8).
    final subject = AppLocalizations.of(context).settings_contact_emailSubject;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    await openExternal(context, uri);
  }
}
