import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/entity_i18n.dart';

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
    this.i18n = noI18n,
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

  /// Chinese and Vietnamese text, under the same keys the accessors use
  /// (`name`, `building`, `hours`, `description`). Absent on every document
  /// written before this existed.
  final EntityI18n i18n;

  /// Locale-aware name, falling back requested language → English → Korean.
  /// Never falls back to [id]: an internal key must not reach the screen.
  String name(Locale l) => _pick(l, nameKo, nameEn, 'name') ?? '—';
  String? address(Locale l) => _pick(l, addressKo, addressEn, 'address');
  String? building(Locale l) => _pick(l, buildingKo, buildingEn, 'building');
  String? hours(Locale l) => _pick(l, hoursKo, hoursEn, 'hours');
  String? description(Locale l) =>
      _pick(l, descriptionKo, descriptionEn, 'description');

  String? _pick(Locale l, String? ko, String? en, String key) {
    final t = pickI18nText(ko ?? '', en ?? '', l, i18n, key);
    return t.isEmpty ? null : t;
  }

  /// Every written form of this facility's name, for search: a student may type
  /// the Korean on the building sign or the name the app is showing them.
  List<String> get nameSearchForms => [
        nameKo,
        nameEn,
        for (final fields in i18n.values)
          if (fields['name'] is String) fields['name'] as String,
      ];

  /// The same facility with any of its English fields that are empty filled in
  /// from [en].
  ///
  /// English is a written field, not an overlay language, so text that only
  /// exists in the translation file would otherwise never be shown: the screen
  /// reads `descriptionEn`, and the seed writes it, both straight off the
  /// entity. Existing English always wins.
  Facility withEnglish(Map<String, Object?> en) {
    String? pick(String? current, String key) {
      if ((current ?? '').trim().isNotEmpty) return current;
      final v = en[key];
      return v is String && v.trim().isNotEmpty ? v : current;
    }

    return Facility(
      id: id,
      nameKo: nameKo,
      nameEn: pick(nameEn, 'name') ?? nameEn,
      category: category,
      lat: lat,
      lng: lng,
      campus: campus,
      buildingCode: buildingCode,
      hasFloorInfo: hasFloorInfo,
      addressKo: addressKo,
      addressEn: pick(addressEn, 'address'),
      buildingKo: buildingKo,
      buildingEn: pick(buildingEn, 'building'),
      hoursKo: hoursKo,
      hoursEn: pick(hoursEn, 'hours'),
      phone: phone,
      descriptionKo: descriptionKo,
      descriptionEn: pick(descriptionEn, 'description'),
      imageUrl: imageUrl,
      updatedAt: updatedAt,
      i18n: i18n,
    );
  }

  /// The same facility carrying [i18n] — used where the generated translations
  /// are laid over data that was written in Korean and English.
  Facility withI18n(EntityI18n i18n) => Facility(
        id: id,
        nameKo: nameKo,
        nameEn: nameEn,
        category: category,
        lat: lat,
        lng: lng,
        campus: campus,
        buildingCode: buildingCode,
        hasFloorInfo: hasFloorInfo,
        addressKo: addressKo,
        addressEn: addressEn,
        buildingKo: buildingKo,
        buildingEn: buildingEn,
        hoursKo: hoursKo,
        hoursEn: hoursEn,
        phone: phone,
        descriptionKo: descriptionKo,
        descriptionEn: descriptionEn,
        imageUrl: imageUrl,
        updatedAt: updatedAt,
        i18n: i18n,
      );

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: j['id'] as String,
        nameKo: (j['name_ko'] ?? '') as String,
        nameEn: (j['name_en'] ?? '') as String,
        category: FacilityCategory.fromId((j['category'] ?? 'etc') as String),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        campus: Campus.fromId(j['campus'] as String?),
        buildingCode: j['buildingCode'] as String?,
        hasFloorInfo: (j['hasFloorInfo'] as bool?) ?? false,
        addressKo: j['address_ko'] as String?,
        addressEn: j['address_en'] as String?,
        buildingKo: j['building_ko'] as String?,
        buildingEn: j['building_en'] as String?,
        hoursKo: j['hours_ko'] as String?,
        hoursEn: j['hours_en'] as String?,
        phone: j['phone'] as String?,
        descriptionKo: j['description_ko'] as String?,
        descriptionEn: j['description_en'] as String?,
        imageUrl: j['imageUrl'] as String?,
        updatedAt: j['updatedAt'] == null
            ? null
            : DateTime.tryParse(j['updatedAt'].toString()),
        i18n: entityI18nFromJson(j['i18n']),
      );

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
        if (entityI18nToJson(i18n) != null) 'i18n': entityI18nToJson(i18n),
      };
}
