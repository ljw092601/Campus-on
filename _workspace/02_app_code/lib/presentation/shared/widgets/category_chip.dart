import 'package:flutter/material.dart';

/// Reusable category chip (UX doc §4.5). Always shows icon + label (never
/// color-only) and keeps a ≥48dp touch target.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        avatar: Icon(icon, size: 18, color: selected ? scheme.onPrimary : color),
        label: Text(label, overflow: TextOverflow.ellipsis),
        selected: selected,
        showCheckmark: false,
        selectedColor: color,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
