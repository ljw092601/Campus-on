import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Facility categories — exactly the 6 from UX doc §8 (emergency is NOT here;
/// it is an admin-guide category).
enum FacilityCategory {
  building,
  classroom,
  dining,
  library,
  amenity,
  etc;

  static FacilityCategory fromId(String id) => FacilityCategory.values
      .firstWhere((e) => e.name == id, orElse: () => FacilityCategory.etc);

  IconData get icon {
    switch (this) {
      case FacilityCategory.building:
        return Symbols.apartment;
      case FacilityCategory.classroom:
        return Symbols.school;
      case FacilityCategory.dining:
        return Symbols.restaurant;
      case FacilityCategory.library:
        return Symbols.local_library;
      case FacilityCategory.amenity:
        return Symbols.local_cafe;
      case FacilityCategory.etc:
        return Symbols.push_pin;
    }
  }
}

/// The three physically separate Dong-A campuses. Facilities carry this so the
/// map can filter/center per campus (they are km apart — one viewport can't
/// hold all three legibly).
enum Campus {
  seunghak,
  gudeok,
  bumin;

  static Campus? fromId(String? id) {
    if (id == null) return null;
    for (final c in Campus.values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// A single campus facility (UX doc §8 Facility schema — fields kept verbatim).
@immutable
class Facility {
  const Facility({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.category,
    required this.lat,
    required this.lng,
    this.campus,
    this.buildingCode,
    this.hasFloorInfo = false,
    this.addressKo,
    this.addressEn,
    this.buildingKo,
    this.buildingEn,
    this.hoursKo,
    this.hoursEn,
    this.phone,
    this.descriptionKo,
    this.descriptionEn,
    this.imageUrl,
    this.updatedAt,
  });

  final String id;
  final String nameKo;
  final String nameEn;
  final FacilityCategory category;
  final double lat;
  final double lng;

  /// Which campus the facility belongs to; null for legacy/unassigned data.
  final Campus? campus;

  /// Official campus-map building code (S01/G03/B04…); null for facilities
  /// that aren't buildings or have no code on the campus map.
  final String? buildingCode;

  /// Whether a `building_floors` document exists for this facility (buildings
  /// listed as "층별 정보 미등록" on the campus map have none).
  final bool hasFloorInfo;

  final String? addressKo;
  final String? addressEn;
  final String? buildingKo;
  final String? buildingEn;
  final String? hoursKo;
  final String? hoursEn;
  final String? phone;
  final String? descriptionKo;
  final String? descriptionEn;
  final String? imageUrl;
  final DateTime? updatedAt;

  /// Names and official building codes share the same search normalization.
  bool matchesSearch(String query) {
    String normalized(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final q = normalized(query);
    return q.isNotEmpty &&
        [nameKo, nameEn, buildingCode ?? '']
            .any((value) => normalized(value).contains(q));
  }

  /// Locale-aware name with fallback to the other language (UX doc §5).
  String name(Locale l) => _pick(l, nameKo, nameEn) ?? id;
  String? address(Locale l) => _pick(l, addressKo, addressEn);
  String? building(Locale l) => _pick(l, buildingKo, buildingEn);
  String? hours(Locale l) => _pick(l, hoursKo, hoursEn);
  String? description(Locale l) => _pick(l, descriptionKo, descriptionEn);

  static String? _pick(Locale l, String? ko, String? en) {
    final wantKo = l.languageCode == 'ko';
    final primary = wantKo ? ko : en;
    final secondary = wantKo ? en : ko;
    if (primary != null && primary.trim().isNotEmpty) return primary;
    if (secondary != null && secondary.trim().isNotEmpty) return secondary;
    return null;
  }

  /// Required fields (`id`, names, `lat`/`lng`, `category`) are cast strictly
  /// — a facility without a position or name is unusable and must be
  /// rejected. Optional fields are read leniently (audit L-23): a `phone`
  /// typed as a number or an `hours_ko` left as a map by an admin edit
  /// degrades to `null` instead of dropping the whole facility from the map.
  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: j['id'] as String,
        nameKo: (j['name_ko'] ?? '') as String,
        nameEn: (j['name_en'] ?? '') as String,
        category: FacilityCategory.fromId((j['category'] ?? 'etc') as String),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        campus: Campus.fromId(_optString(j['campus'])),
        buildingCode: _optString(j['buildingCode']),
        hasFloorInfo: j['hasFloorInfo'] == true,
        addressKo: _optString(j['address_ko']),
        addressEn: _optString(j['address_en']),
        buildingKo: _optString(j['building_ko']),
        buildingEn: _optString(j['building_en']),
        hoursKo: _optString(j['hours_ko']),
        hoursEn: _optString(j['hours_en']),
        phone: _optString(j['phone']),
        descriptionKo: _optString(j['description_ko']),
        descriptionEn: _optString(j['description_en']),
        imageUrl: _optString(j['imageUrl']),
        updatedAt: j['updatedAt'] == null
            ? null
            : DateTime.tryParse(j['updatedAt'].toString()),
      );

  /// Lenient optional-string read: anything that is not a `String` is
  /// treated as absent.
  static String? _optString(Object? v) => v is String ? v : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ko': nameKo,
        'name_en': nameEn,
        'category': category.name,
        'lat': lat,
        'lng': lng,
        'campus': campus?.name,
        'buildingCode': buildingCode,
        'hasFloorInfo': hasFloorInfo,
        'address_ko': addressKo,
        'address_en': addressEn,
        'building_ko': buildingKo,
        'building_en': buildingEn,
        'hours_ko': hoursKo,
        'hours_en': hoursEn,
        'phone': phone,
        'description_ko': descriptionKo,
        'description_en': descriptionEn,
        'imageUrl': imageUrl,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
