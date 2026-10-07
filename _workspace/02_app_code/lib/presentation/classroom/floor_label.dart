import '../../l10n/gen/app_localizations.dart';

final _canonicalFloor = RegExp(r'^(B?)(\d+)F$');

/// Display form of a canonical floor label ("3F" / "B1F" — the data key used
/// by `FloorInfo.floor`, `FloorPlan.floorLabel` and [floorLabelOf]):
/// "3층" / "지하 1층" in Korean, "3F" / "B1F" in English (L-31). Labels of any
/// other shape are shown as they are.
String localizedFloorLabel(AppLocalizations l, String label) {
  final m = _canonicalFloor.firstMatch(label);
  if (m == null) return label;
  final n = m.group(2)!;
  return m.group(1)!.isEmpty
      ? l.floorplan_floorLabel(n)
      : l.floorplan_basementLabel(n);
}
