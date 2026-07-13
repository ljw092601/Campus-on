import 'package:flutter/material.dart';

import '../../domain/entities/facility.dart';
import '../../domain/entities/admin_guide.dart';

/// Category accent colors (UX doc §4.1) exposed as a [ThemeExtension].
///
/// Colors are paired with icons + labels everywhere (never color-only) to meet
/// the A11y "information not conveyed by color alone" requirement.
@immutable
class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors({
    required this.building,
    required this.classroom,
    required this.dining,
    required this.library,
    required this.amenity,
    required this.etc,
    required this.immigration,
    required this.housing,
    required this.living,
    required this.health,
    required this.school,
    required this.emergency,
  });

  // Facility categories (6).
  final Color building;
  final Color classroom;
  final Color dining;
  final Color library;
  final Color amenity;
  final Color etc;

  // Admin guide categories (6).
  final Color immigration;
  final Color housing;
  final Color living;
  final Color health;
  final Color school;
  final Color emergency;

  /// Values are identical in light/dark per UX doc (single accent per category).
  static const CategoryColors standard = CategoryColors(
    building: Color(0xFF5B6BC0),
    classroom: Color(0xFF00897B),
    dining: Color(0xFFEF6C00),
    library: Color(0xFF6A1B9A),
    amenity: Color(0xFF00838F),
    etc: Color(0xFF607D8B),
    immigration: Color(0xFF1565C0),
    housing: Color(0xFF5B6BC0),
    living: Color(0xFF00838F),
    health: Color(0xFF2E7D32),
    school: Color(0xFF6A1B9A),
    emergency: Color(0xFFC62828),
  );

  Color forFacility(FacilityCategory c) {
    switch (c) {
      case FacilityCategory.building:
        return building;
      case FacilityCategory.classroom:
        return classroom;
      case FacilityCategory.dining:
        return dining;
      case FacilityCategory.library:
        return library;
      case FacilityCategory.amenity:
        return amenity;
      case FacilityCategory.etc:
        return etc;
    }
  }

  Color forGuide(GuideCategory c) {
    switch (c) {
      case GuideCategory.immigration:
        return immigration;
      case GuideCategory.housing:
        return housing;
      case GuideCategory.living:
        return living;
      case GuideCategory.health:
        return health;
      case GuideCategory.school:
        return school;
      case GuideCategory.emergency:
        return emergency;
    }
  }

  @override
  CategoryColors copyWith() => this;

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) => this;
}
