import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';

/// S9 — Settings. Week 2 wires the core language switch (instant, no restart)
/// and the favorites entry; About/data-source sub-pages land in week 3.
class SettingsStubScreen extends ConsumerWidget {
  const SettingsStubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l.settings_language_title,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (value) {
              if (value != null) notifier.setLocale(Locale(value));
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'ko',
                  title: Text(l.settings_language_ko),
                ),
                RadioListTile<String>(
                  value: 'en',
                  title: Text(l.settings_language_en),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.settings_stub_body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ),
        ],
      ),
    );
  }
}
