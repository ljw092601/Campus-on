import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/i18n/app_languages.dart';
import '../../l10n/gen/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../shared/widgets/ui_kit.dart';

/// S9 — Settings. Language switch (instant, no restart), favorites entry, and
/// the About/data-source/contact/privacy/licenses info section, closed by the
/// DM emblem + version footer (DONG-A-MATE mockup layout).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final notifier = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SectionCaption(l.settings_language_title.toUpperCase()),
          // One grouped card, one radio row per language. Each language is
          // named in itself and carries a locale hint so a screen reader
          // pronounces it in that language; the active one is the filled blue
          // radio. Real radios give the mutually-exclusive semantics for free.
          RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (code) {
              if (code == null) return;
              _changeLanguage(context, notifier, code);
            },
            child: GroupCard(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              dividerIndent: 12,
              children: [
                for (final code in appLanguageCodes)
                  _LanguageTile(
                    code: code,
                    selected: locale.languageCode == code,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GroupCard(
            children: [
              _SettingsRow(
                icon: Symbols.star,
                tone: Tone.yellow,
                title: l.settings_favorites_title,
                subtitle: l.settings_favorites_subtitle,
                onTap: () => context.go('/settings/favorites'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionCaption(l.settings_section_info),
          GroupCard(
            children: [
              _SettingsRow(
                icon: Symbols.info,
                title: l.settings_about,
                onTap: () => context.go('/settings/about'),
              ),
              _SettingsRow(
                icon: Symbols.description,
                title: l.settings_dataSource,
                onTap: () => context.go('/settings/data-source'),
              ),
              _SettingsRow(
                icon: Symbols.mail,
                title: l.settings_contact,
                onTap: () => context.go('/settings/contact'),
              ),
              _SettingsRow(
                icon: Symbols.shield,
                title: l.settings_privacy,
                external: true,
                onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
              ),
              _SettingsRow(
                icon: Symbols.article,
                title: l.settings_licenses,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l.appTitle,
                  applicationVersion: l.settings_version_value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _VersionFooter(),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(
      BuildContext context, LocaleNotifier notifier, String code) async {
    final messenger = ScaffoldMessenger.of(context);
    // The switch itself always happens; only remembering it can fail
    // (private window, blocked site data). Tell the reader, in the
    // language they just picked, that it may not survive a restart —
    // being surprised by it later is worse (감사 05/035 NIT-2).
    if (!await notifier.setLocale(Locale(code))) {
      if (!context.mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          // Two sentences in a second language need more than the
          // default four seconds (감사 05/037 SF-3).
          duration: const Duration(seconds: 10),
          content:
              Text(AppLocalizations.of(context).settings_language_save_failed),
        ));
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// One language choice in the grouped card: a [RadioListTile] (value/group
/// from the enclosing [RadioGroup]) titled with the language's own name, with
/// a locale hint so TTS reads it in that language. Radio on the trailing side
/// in the primary blue, bold navy title when active — the mockup's look.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.code, required this.selected});

  final String code;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RadioListTile<String>(
      value: code,
      activeColor: scheme.primary,
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      shape: const RoundedRectangleBorder(),
      title: Text(
        appLanguageNames[code]!,
        locale: Locale(code),
        style: TextStyle(
          fontSize: 17,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? headingColor(context) : scheme.onSurface,
        ),
      ),
    );
  }
}

/// One grouped-card row: tinted icon tile, bold title, optional gray
/// subtitle, optional external-link glyph, chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tone = Tone.blue,
    this.external = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Tone tone;
  final bool external;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              IconTile(icon: icon, tone: tone, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (external) ...[
                const SizedBox(width: 8),
                Icon(Symbols.open_in_new,
                    size: 20, color: scheme.onSurfaceVariant),
              ],
              const SizedBox(width: 6),
              Icon(Symbols.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// DM emblem + "버전 0.2.0 (MVP)" with the version number emphasised. The
/// whole line is one semantics node so it reads "Version 0.2.0 (MVP)".
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final value = l.settings_version_value;
    // "0.2.0 (MVP)" → bold "0.2.0" + regular " (MVP)".
    final split = value.indexOf(' ');
    final number = split < 0 ? value : value.substring(0, split);
    final rest = split < 0 ? '' : value.substring(split);

    return Column(
      children: [
        ExcludeSemantics(
          child: Image.asset('assets/home/app_emblem.png', height: 52),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14, color: muted),
            children: [
              TextSpan(text: '${l.settings_version}  '),
              TextSpan(
                text: number,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: headingColor(context),
                ),
              ),
              TextSpan(text: rest),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
