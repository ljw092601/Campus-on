import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
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
          PillSegmented<String>(
            values: const ['ko', 'en'],
            selected: locale.languageCode,
            // Each label names its own language, so it is always shown in
            // that language regardless of the current locale.
            labelOf: (code) =>
                code == 'ko' ? l.settings_language_ko : l.settings_language_en,
            onChanged: (code) => notifier.setLocale(Locale(code)),
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
