import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/app_languages.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';

/// S9 — Settings. Language switch (instant, no restart), favorites entry, and
/// the About/data-source/contact/privacy/licenses info section.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: ListView(
        children: [
          _SectionHeader(l.settings_language_title),
          RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (value) async {
              if (value == null) return;
              final messenger = ScaffoldMessenger.of(context);
              // The switch itself always happens; only remembering it can fail
              // (private window, blocked site data). Tell the reader, in the
              // language they just picked, that it may not survive a restart —
              // being surprised by it later is worse (감사 05/035 NIT-2).
              if (!await notifier.setLocale(Locale(value))) {
                if (!context.mounted) return;
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    // Two sentences in a second language need more than the
                    // default four seconds (감사 05/037 SF-3).
                    duration: const Duration(seconds: 10),
                    content: Text(
                        AppLocalizations.of(context).settings_language_save_failed),
                  ));
              }
            },
            child: Column(
              children: [
                // Each language is named in itself, and carries a locale hint
                // so a screen reader pronounces it in that language.
                for (final code in appLanguageCodes)
                  RadioListTile<String>(
                    value: code,
                    title: Text(appLanguageNames[code]!, locale: Locale(code)),
                  ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.star),
            title: Text(l.settings_favorites_title),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () => context.go('/settings/favorites'),
          ),
          const Divider(),
          _SectionHeader(l.settings_section_info),
          ListTile(
            leading: const Icon(Symbols.info),
            title: Text(l.settings_about),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () => context.go('/settings/about'),
          ),
          ListTile(
            leading: const Icon(Symbols.source),
            title: Text(l.settings_dataSource),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () => context.go('/settings/data-source'),
          ),
          ListTile(
            leading: const Icon(Symbols.mail),
            title: Text(l.settings_contact),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () => context.go('/settings/contact'),
          ),
          ListTile(
            leading: const Icon(Symbols.privacy_tip),
            title: Text(l.settings_privacy),
            trailing: Icon(Symbols.open_in_new,
                size: 18, color: scheme.onSurfaceVariant),
            onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Symbols.description),
            title: Text(l.settings_licenses),
            trailing: const Icon(Symbols.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l.appTitle,
              applicationVersion: l.settings_version_value,
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.info_i),
            title: Text(l.settings_version),
            // Value as subtitle (not trailing) so it never overflows the row
            // under large font scale (QA A-4).
            subtitle: Text(l.settings_version_value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              )),
    );
  }
}
