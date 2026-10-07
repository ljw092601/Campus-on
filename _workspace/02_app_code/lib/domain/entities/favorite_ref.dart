import 'package:flutter/material.dart';

enum FavoriteType { facility, guide }

/// Ids that were renamed after users may have saved them as favorites.
/// Keyed by favorite type → (old id → current id). Extend when a facility or
/// guide id changes (e.g. 공과대학4호관 `p4` → `s12`, commit 2cc24e3).
const Map<FavoriteType, Map<String, String>> legacyFavoriteIdMap = {
  FavoriteType.facility: {'p4': 's12'},
};

/// Current id for [type]/[id], or [id] itself when nothing was renamed.
String resolveLegacyFavoriteId(FavoriteType type, String id) =>
    legacyFavoriteIdMap[type]?[id] ?? id;

/// Local-only favorite reference (UX doc §8 — device storage, no server).
@immutable
class FavoriteRef {
  const FavoriteRef({
    required this.type,
    required this.id,
    required this.savedAt,
  });

  final FavoriteType type;
  final String id;
  final DateTime savedAt;

  /// Stable key for a Set/local store: "facility:123".
  String get key => '${type.name}:$id';

  factory FavoriteRef.fromJson(Map<String, dynamic> j) {
    final type = switch (j['type']) {
      'guide' => FavoriteType.guide,
      'facility' => FavoriteType.facility,
      _ => throw const FormatException('Unknown favorite type'),
    };
    final id = j['id'];
    final date =
        j['savedAt'] is String ? DateTime.tryParse(j['savedAt']) : null;
    if (id is! String || id.trim().isEmpty || date == null) {
      throw const FormatException('Invalid favorite entry');
    }
    return FavoriteRef(type: type, id: id, savedAt: date);
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'savedAt': savedAt.toIso8601String(),
      };
}
