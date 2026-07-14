import '../../domain/entities/admin_guide.dart';
import '../../domain/entities/facility.dart';
import '../../l10n/gen/app_localizations.dart';

/// Maps facility category enums to localized labels (data-label mapping kept in
/// one place per UX doc §5).
extension FacilityCategoryLabel on FacilityCategory {
  String label(AppLocalizations l) {
    switch (this) {
      case FacilityCategory.building:
        return l.facility_category_building;
      case FacilityCategory.classroom:
        return l.facility_category_classroom;
      case FacilityCategory.dining:
        return l.facility_category_dining;
      case FacilityCategory.library:
        return l.facility_category_library;
      case FacilityCategory.amenity:
        return l.facility_category_amenity;
      case FacilityCategory.etc:
        return l.facility_category_etc;
    }
  }
}

/// Maps admin-guide category enums to localized labels + one-line summaries
/// (S1 home grid + S5 category list).
extension GuideCategoryLabel on GuideCategory {
  String label(AppLocalizations l) {
    switch (this) {
      case GuideCategory.immigration:
        return l.guide_category_immigration;
      case GuideCategory.housing:
        return l.guide_category_housing;
      case GuideCategory.living:
        return l.guide_category_living;
      case GuideCategory.health:
        return l.guide_category_health;
      case GuideCategory.school:
        return l.guide_category_school;
      case GuideCategory.emergency:
        return l.guide_category_emergency;
    }
  }

  String summary(AppLocalizations l) {
    switch (this) {
      case GuideCategory.immigration:
        return l.guide_categorySummary_immigration;
      case GuideCategory.housing:
        return l.guide_categorySummary_housing;
      case GuideCategory.living:
        return l.guide_categorySummary_living;
      case GuideCategory.health:
        return l.guide_categorySummary_health;
      case GuideCategory.school:
        return l.guide_categorySummary_school;
      case GuideCategory.emergency:
        return l.guide_categorySummary_emergency;
    }
  }
}
