import 'package:campus_on/data/mock/guide_items_support.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// r21 (2026-10-30): the two approved guides — scholarships and TOPIK support,
/// and the university's online services. Pins what the lead registered and
/// measured: both are in the catalogue under 학교, their search words reach
/// them in each language, every guide they point to exists, and none of their
/// links uses the `www.donga.ac.kr/kor/CMS/` addresses that return 404 since
/// the homepage redesign (lead re-check, 2026-10-30).
void main() {
  const scholarshipId = 'scholarships-and-topik';
  const onlineId = 'campus-online-services';

  AdminGuideItem byId(String id) =>
      MockData.guideItems.firstWhere((g) => g.id == id);

  List<String> ranked(String q) =>
      searchGuideItems(MockData.guideItems, q).map((g) => g.id).toList();

  Iterable<String> urlsOf(AdminGuideItem g) => [
        ...g.links.map((l) => l.url),
        for (final s in [...g.topSections, ...g.sections]) ...[
          ...s.links.map((l) => l.url),
        ],
      ];

  test('두 가이드가 학교 분류로 등록돼 있다', () {
    expect(SupportGuides.items.map((g) => g.id), [scholarshipId, onlineId]);
    for (final id in [scholarshipId, onlineId]) {
      final g = byId(id);
      expect(g.categoryId, GuideCategory.school, reason: id);
      expect(g.status, GuideStatus.published, reason: id);
      expect(g.hasNoContent, isFalse, reason: id);
    }
  });

  group('검색 — 새 가이드에 닿는다', () {
    // 「장학금」·scholarship·奖学金 은 oia-visit 별칭과 같은 0군이라 카탈로그
    // 순서대로 oia-visit 다음, 2위다. 순위를 바꾸려면 oia-visit 별칭 자리(zh·vi
    // 와 맞물림)나 검색 정렬을 건드려야 해서 r21 에서는 두지 않았다 — 후속 항목.
    for (final q in ['장학금', 'scholarship', '奖学金']) {
      test('「$q」 → 상위 2개 안', () {
        expect(ranked(q).take(2), contains(scholarshipId));
      });
    }
    for (final q in ['TOPIK 장학금', '응시료', 'TOPIK scholarship']) {
      test('「$q」 → 1위', () {
        expect(ranked(q).first, scholarshipId);
      });
    }
    for (final q in ['LMS', '학교 메일', '통합정보시스템', 'student portal']) {
      test('「$q」 → 1위', () {
        expect(ranked(q).first, onlineId);
      });
    }
  });

  test('가리키는 가이드가 모두 카탈로그에 있다', () {
    final ids = MockData.guideItems.map((g) => g.id).toSet();
    for (final g in SupportGuides.items) {
      for (final u in urlsOf(g).where((u) => u.startsWith('/guide/item/'))) {
        expect(ids, contains(u.substring('/guide/item/'.length)),
            reason: '${g.id} → $u');
      }
    }
  });

  test('404 가 된 옛 학교 주소를 쓰지 않는다', () {
    for (final g in SupportGuides.items) {
      for (final u in urlsOf(g)) {
        expect(u, isNot(contains('www.donga.ac.kr/kor/CMS/')),
            reason: '${g.id} → $u');
      }
    }
  });

  // zh·vi 가 빠지면 title() 은 영어로 떨어진다 — 비어 있지 않음만 보면 번역이
  // 없어도 통과하므로, 영어와 다른 자기 언어 제목이 있는지를 본다.
  test('네 언어 제목이 있고 zh·vi 는 영어로 떨어지지 않는다', () {
    // SupportGuides.items 는 번역을 입히기 전 원본이다 — 카탈로그에서 읽는다.
    for (final g in [byId(scholarshipId), byId(onlineId)]) {
      expect(g.title(const Locale('ko')).trim(), isNotEmpty, reason: g.id);
      expect(g.title(const Locale('en')).trim(), isNotEmpty, reason: g.id);
      for (final l in const [Locale('zh'), Locale('vi')]) {
        expect(g.title(l).trim(), isNotEmpty, reason: '${g.id} $l');
        expect(g.title(l), isNot(g.titleEn), reason: '${g.id} $l');
      }
    }
  });
}
