import 'package:flutter/material.dart';

/// Reusable category chip (UX doc §4.5). Always shows icon + label (never
/// color-only) and keeps a ≥48dp touch target.
///
/// DONG-A-MATE mockup style: stadium pill — selected is solid primary blue
/// with white icon + label; unselected is a white pill with a hairline border
/// and gray icon + label. [color] tints the unselected icon only when
/// [tintIcon] is set (kept for callers that want category colors).
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.tintIcon = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool tintIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected
        ? scheme.onPrimary
        : (tintIcon ? color : scheme.onSurfaceVariant);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        avatar: Icon(icon, size: 20, color: fg),
        label: Text(label, overflow: TextOverflow.ellipsis),
        selected: selected,
        showCheckmark: false,
        selectedColor: scheme.primary,
        backgroundColor: scheme.surface,
        shape: const StadiumBorder(),
        side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelPadding: const EdgeInsets.only(left: 2, right: 6),
        labelStyle: TextStyle(
          fontSize: 15,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
