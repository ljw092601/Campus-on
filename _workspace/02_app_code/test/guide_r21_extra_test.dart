import 'package:campus_on/data/mock/guide_items_extra.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// r21 (2026-10-30): the guide the lead selected with independent review —
/// receiving parcels from abroad (customs code, duty-free limits). Pins its
/// place under 생활, that its search words reach it first, that the guides it
/// points to exist, and that zh·vi carry their own title instead of falling
/// back to English.
void main() {
  const id = 'overseas-parcels-and-customs';

  AdminGuideItem guide() => MockData.guideItems.firstWhere((g) => g.id == id);

  List<String> ranked(String q) =>
      searchGuideItems(MockData.guideItems, q).map((g) => g.id).toList();

  Iterable<String> urlsOf(AdminGuideItem g) => [
        ...g.links.map((l) => l.url),
        for (final s in [...g.topSections, ...g.sections]) ...[
          ...s.links.map((l) => l.url),
        ],
      ];

  test('생활 분류로 등록돼 있고 게시 상태다', () {
    expect(ExtraGuides.items.map((g) => g.id), [id]);
    expect(guide().categoryId, GuideCategory.living);
    expect(guide().status, GuideStatus.published);
    expect(guide().hasNoContent, isFalse);
  });

  for (final q in ['통관', '개인통관고유부호', '해외직구', 'customs code']) {
    test('「$q」 → 1위', () {
      expect(ranked(q).first, id);
    });
  }

  test('가리키는 가이드가 모두 카탈로그에 있다', () {
    final ids = MockData.guideItems.map((g) => g.id).toSet();
    for (final u in urlsOf(guide()).where((u) => u.startsWith('/guide/item/'))) {
      expect(ids, contains(u.substring('/guide/item/'.length)), reason: u);
    }
  });

  test('zh·vi 제목이 영어로 떨어지지 않는다', () {
    final g = guide();
    for (final l in const [Locale('zh'), Locale('vi')]) {
      expect(g.title(l).trim(), isNotEmpty, reason: '$l');
      expect(g.title(l), isNot(g.titleEn), reason: '$l');
    }
  });
}
