import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
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
            onChanged: (value) {
              if (value != null) notifier.setLocale(Locale(value));
            },
            child: Column(
              children: [
                RadioListTile<String>(
                    value: 'ko',
                    // Locale hint so a non-Korean TTS pronounces "한국어" correctly.
                    title: Text(l.settings_language_ko,
                        locale: const Locale('ko'))),
                RadioListTile<String>(
                    value: 'en',
                    title: Text(l.settings_language_en,
                        locale: const Locale('en'))),
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
              applicationName: 'Campus-On',
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
