import 'package:flutter/material.dart';

enum FavoriteType { facility, guide }

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

  factory FavoriteRef.fromJson(Map<String, dynamic> j) => FavoriteRef(
        type: j['type'] == 'guide' ? FavoriteType.guide : FavoriteType.facility,
        id: j['id'] as String,
        savedAt: DateTime.tryParse(j['savedAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'savedAt': savedAt.toIso8601String(),
      };
}
