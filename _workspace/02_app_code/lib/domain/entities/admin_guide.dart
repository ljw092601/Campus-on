import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Admin guide categories — the 6 from UX doc §8 (includes emergency).
/// Full guide screens (S5–S7) land in week 3; the enum + light model are
/// defined now so search (S8) and deep links can reference them.
enum GuideCategory {
  immigration,
  housing,
  living,
  health,
  school,
  emergency;

  static GuideCategory fromId(String id) => GuideCategory.values
      .firstWhere((e) => e.name == id, orElse: () => GuideCategory.immigration);

  IconData get icon {
    switch (this) {
      case GuideCategory.immigration:
        return Symbols.badge;
      case GuideCategory.housing:
        return Symbols.home;
      case GuideCategory.living:
        return Symbols.account_balance;
      case GuideCategory.health:
        return Symbols.local_hospital;
      case GuideCategory.school:
        return Symbols.school;
      case GuideCategory.emergency:
        return Symbols.sos;
    }
  }
}

enum GuideStatus { published, comingSoon }

/// Minimal guide item — enough for the S8 search index + deep-link contract.
/// Full sectioned content (overview/checklist/steps/links) is fleshed out in
/// week 3 and lives on the same schema (UX doc §8 AdminGuideItem).
@immutable
class AdminGuideItem {
  const AdminGuideItem({
    required this.id,
    required this.categoryId,
    required this.titleKo,
    required this.titleEn,
    this.summaryKo,
    this.summaryEn,
    this.relatedFacilityIds = const [],
    this.status = GuideStatus.comingSoon,
  });

  final String id;
  final GuideCategory categoryId;
  final String titleKo;
  final String titleEn;
  final String? summaryKo;
  final String? summaryEn;

  /// Deep-link target: `/map?focus=<ids joined by ','>` (UX doc §3).
  final List<String> relatedFacilityIds;
  final GuideStatus status;

  String title(Locale l) =>
      (l.languageCode == 'ko' ? titleKo : titleEn).trim().isNotEmpty
          ? (l.languageCode == 'ko' ? titleKo : titleEn)
          : (l.languageCode == 'ko' ? titleEn : titleKo);

  String? summary(Locale l) {
    final s = l.languageCode == 'ko' ? summaryKo : summaryEn;
    return (s != null && s.trim().isNotEmpty) ? s : null;
  }

  factory AdminGuideItem.fromJson(Map<String, dynamic> j) => AdminGuideItem(
        id: j['id'] as String,
        categoryId:
            GuideCategory.fromId((j['categoryId'] ?? 'immigration') as String),
        titleKo: (j['title_ko'] ?? '') as String,
        titleEn: (j['title_en'] ?? '') as String,
        summaryKo: j['summary_ko'] as String?,
        summaryEn: j['summary_en'] as String?,
        relatedFacilityIds:
            (j['relatedFacilityIds'] as List?)?.cast<String>() ?? const [],
        status: (j['status'] == 'published')
            ? GuideStatus.published
            : GuideStatus.comingSoon,
      );
}
