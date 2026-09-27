import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/layout/flexible_text_layout.dart';
import '../../../core/theme/app_theme.dart';

/// Shared building blocks for the DONG-A-MATE UI mockups
/// (DONG-A-MATE_UI_*.png): rounded white cards with inset dividers, tinted
/// icon tiles, pill badges, info banners and pill segmented controls.

/// Accent tones used by icon tiles and badges. Each tone is a soft
/// background + a strong foreground; dark mode swaps to translucent fills.
enum Tone { blue, navy, yellow, green, coral, purple, red, neutral }

extension ToneColors on Tone {
  Color fg(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      Tone.blue => dark ? const Color(0xFF8DB4FF) : AppColors.blue,
      Tone.navy => dark ? const Color(0xFFC9D8F5) : AppColors.navy,
      Tone.yellow => dark ? const Color(0xFFFFD25C) : AppColors.yellowInk,
      Tone.green => dark ? const Color(0xFF6FD9A6) : AppColors.green,
      Tone.coral => dark ? const Color(0xFFFF9C80) : AppColors.coral,
      Tone.purple => dark ? const Color(0xFFB9A6FF) : AppColors.purple,
      Tone.red => dark ? const Color(0xFFFF8A8E) : AppColors.red,
      Tone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  Color bg(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return this == Tone.neutral
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : fg(context).withValues(alpha: 0.16);
    }
    return switch (this) {
      Tone.blue => AppColors.blueSoft,
      Tone.navy => AppColors.blueBadge,
      Tone.yellow => AppColors.yellowSoft,
      Tone.green => AppColors.greenSoft,
      Tone.coral => AppColors.coralSoft,
      Tone.purple => AppColors.purpleSoft,
      Tone.red => AppColors.redSoft,
      Tone.neutral => AppColors.pillNeutral,
    };
  }
}

/// Heading color: deep navy in light mode, primary in dark mode.
Color headingColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurface
        : AppColors.navy;

/// Soft drop shadow under cards / floating fields in the mockups.
List<BoxShadow> softShadow(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const []
        : [
            BoxShadow(
              color: const Color(0xFF1B3A7A).withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ];

/// White rounded card (radius 24, hairline border, soft shadow). When
/// [children] has several entries they're separated by inset dividers, the
/// grouped-list look used on the guide / settings / calendar screens.
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.dividerIndent = 0,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: softShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(indent: dividerIndent, height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-square tinted icon plate (56dp) — list rows, feature cards.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tone = Tone.blue,
    this.size = 48,
    this.iconSize,
  });

  final IconData icon;
  final Tone tone;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.bg(context),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize ?? size * 0.5, color: tone.fg(context)),
    );
  }
}

/// Small pill label ("휴일", "학사", "승학", counts, floor tags).
class ToneBadge extends StatelessWidget {
  const ToneBadge(
    this.text, {
    super.key,
    this.tone = Tone.neutral,
    this.minWidth = 0,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  final String text;
  final Tone tone;
  final double minWidth;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final fg = tone == Tone.neutral ? headingColor(context) : tone.fg(context);
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: padding,
      decoration: BoxDecoration(
        color: tone.bg(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        // One line at ordinary sizes. At large text / on a 320dp phone a badge
        // in a Wrap (e.g. the home date chip) can be wider than the row, so
        // it wraps rather than silently clipping its tail.
        maxLines: prefersFlexibleLayout(context) ? null : 1,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

/// Light-blue notice box with an info icon ("지금은 예시 일정이에요 …").
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Symbols.info});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fg = Tone.blue.fg(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: Tone.blue.bg(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped segmented control (campus selector, language picker): a
/// pale track with a white raised thumb behind the selected label.
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? scheme.surfaceContainerHighest : const Color(0xFFE9EEF6),
        borderRadius: BorderRadius.circular(999),
      ),
      // Equal-height segments even when one label wraps at large text.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final v in values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: v == selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      // Min height, not fixed: at large text the label grows
                      // the thumb instead of being clipped.
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: v == selected ? scheme.surface : null,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: v == selected ? softShadow(context) : null,
                      ),
                      child: Text(
                        labelOf(v),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              v == selected ? FontWeight.w800 : FontWeight.w500,
                          color: v == selected
                              ? headingColor(context)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase-ish gray section caption ("정보", "언어 · LANGUAGE").
class SectionCaption extends StatelessWidget {
  const SectionCaption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Soft-blue pill action ("지도에서 보기", "크게 보기").
class SoftPillButton extends StatelessWidget {
  const SoftPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = Tone.blue.fg(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: fg),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: Tone.blue.bg(context),
        foregroundColor: fg,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}
