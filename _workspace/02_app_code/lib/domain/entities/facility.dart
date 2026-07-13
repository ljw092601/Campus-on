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

  factory Facility.fromJson(Map<String, dynamic> j) => Facility(
        id: j['id'] as String,
        nameKo: (j['name_ko'] ?? '') as String,
        nameEn: (j['name_en'] ?? '') as String,
        category: FacilityCategory.fromId((j['category'] ?? 'etc') as String),
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ko': nameKo,
        'name_en': nameEn,
        'category': category.name,
        'lat': lat,
        'lng': lng,
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
