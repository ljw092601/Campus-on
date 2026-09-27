import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/firestore/firestore_guide_repository.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/data/repositories/mock_guide_repository.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/domain/repositories/guide_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guide search (04/008 follow-up): everyday words must reach the guide that
/// owns the task, the same way on the mock and Firestore paths, and documents
/// without the new alias fields must keep working.

/// Words from 04/008 (title-only search found nothing for the first ten) plus
/// English equivalents, each with a guide it must surface.
const _cases = <String, String>{
  '비자 연장': 'stay-extension',
  '알바': 'part-time-work',
  '이사': 'address-and-registration-changes',
  '여권': 'address-and-registration-changes',
  '분실': 'residence-card-reissue',
  '재학증명서': 'certificate-issue',
  '원룸': 'off-campus-housing',
  '유심': 'mobile-plan',
  '약국': 'hospital-guide',
  '경찰': 'incident-response',
  '보증금': 'rental-deposit-protection',
  '휴학': 'academic-status-and-visa',
  '등록금': 'tuition-payment',
  '졸업': 'graduation-requirements',
  '출국': 'departure-checklist',
  '구직': 'd10-job-seeking',
  'part-time job': 'part-time-work',
  'lost card': 'residence-card-reissue',
  'moving': 'address-and-registration-changes',
  'tuition': 'tuition-payment',
  'pharmacy': 'hospital-guide',
  'visa extension': 'stay-extension',
  'D4': 'status-change-d4-to-d2',
  'd10': 'd10-job-seeking',
  '장학금': 'oia-visit',
  'scholarship': 'oia-visit',
  'lost passport': 'incident-response',
  'D-4 D-2': 'status-change-d4-to-d2',
};

List<String> _ids(Iterable<AdminGuideItem> r) => r.map((g) => g.id).toList();

void main() {
  test('everyday words find the owning guide (mock data)', () {
    _cases.forEach((q, id) {
      expect(_ids(searchGuideItems(MockData.guideItems, q)), contains(id),
          reason: q);
    });
  });

  test('mock repository uses the shared search', () async {
    final repo = MockGuideRepository(latency: Duration.zero);
    for (final e in _cases.entries) {
      expect(_ids(await repo.search(e.key)), contains(e.value), reason: e.key);
    }
    expect(await repo.search('   '), isEmpty);
  });

  test('Firestore documents (exported seed) search the same as the mock', () {
    final seed = jsonDecode(
            File('tool/firestore_seed/guide_items.seed.json').readAsStringSync())
        as Map<String, dynamic>;
    // Firestore hands documents back ordered by id, not catalogue order.
    final raw = [
      for (final e in seed.entries)
        {...(e.value as Map).cast<String, dynamic>(), 'id': e.key},
    ]..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    final docs = orderByCatalogue(raw, (d) => d[guideSortOrderField])
        .map(AdminGuideItem.fromJson)
        .toList();
    expect(_ids(docs), _ids(MockData.guideItems));
    for (final q in [..._cases.keys, '체류', 'ARC', '가이드', '졸업', '비자']) {
      expect(_ids(searchGuideItems(docs, q)),
          _ids(searchGuideItems(MockData.guideItems, q)),
          reason: q);
    }
    for (final c in GuideCategory.values) {
      expect(_ids(orderGuideItems(docs.where((g) => g.categoryId == c))),
          _ids(orderGuideItems(
              MockData.guideItems.where((g) => g.categoryId == c))),
          reason: c.name);
    }
  });

  test('documents without sort_order keep their order after ordered ones', () {
    final docs = [
      {'id': 'b'},
      {'id': 'a', guideSortOrderField: 1},
      {'id': 'c'},
      {'id': 'd', guideSortOrderField: 0},
    ];
    expect(orderByCatalogue(docs, (d) => d[guideSortOrderField])
        .map((d) => d['id']), ['d', 'a', 'b', 'c']);
  });

  test('old documents without aliases still load and match titles', () {
    final old = AdminGuideItem.fromJson(const {
      'id': 'legacy',
      'categoryId': 'living',
      'title_ko': '은행 계좌 개설',
      'title_en': 'Open a Bank Account',
      'status': 'published',
    });
    expect(old.searchAliasesKo, isEmpty);
    expect(old.searchAliasesEn, isEmpty);
    expect(_ids(searchGuideItems([old], '계좌 개설')), ['legacy']);
    expect(_ids(searchGuideItems([old], 'bank')), ['legacy']);
    expect(searchGuideItems([old], '알바'), isEmpty);

    final withAliases = AdminGuideItem.fromJson(const {
      'id': 'aliased',
      'categoryId': 'living',
      'title_ko': '은행 계좌 개설',
      'title_en': 'Open a Bank Account',
      'search_aliases_ko': ['통장'],
      'search_aliases_en': ['passbook'],
    });
    expect(_ids(searchGuideItems([withAliases], '통장')), ['aliased']);
    expect(_ids(searchGuideItems([withAliases], 'PASSBOOK')), ['aliased']);
  });

  test('title hits rank before alias or summary hits; spacing is ignored', () {
    final r = _ids(searchGuideItems(MockData.guideItems, '등록금'));
    expect(r.first, 'tuition-payment');
    expect(_ids(searchGuideItems(MockData.guideItems, '비자연장')),
        contains('stay-extension'));
    // Existing title searches keep working.
    expect(_ids(searchGuideItems(MockData.guideItems, '수강신청')).first,
        'course-registration');
    expect(_ids(searchGuideItems(MockData.guideItems, 'Bank')).first,
        'bank-account');
  });

  test('an exact alias or title ranks before other title hits (05/029 N-6)', () {
    // d10-job-seeking's title starts with 「졸업」, but graduation-requirements
    // has 「졸업」 as an alias — the exact match comes first.
    final grad = _ids(searchGuideItems(MockData.guideItems, '졸업'));
    expect(grad.first, 'graduation-requirements');
    expect(grad, contains('d10-job-seeking'));
    // A general word stays with the guide whose title owns it (감사 05/030 NIT-2).
    expect(_ids(searchGuideItems(MockData.guideItems, '신고')).first,
        'address-and-registration-changes');
    expect(_ids(searchGuideItems(MockData.guideItems, '신고')),
        contains('incident-response'));
    final passport = _ids(searchGuideItems(MockData.guideItems, '여권 분실'));
    expect(passport.first, 'incident-response');
    // One Latin letter no longer lists most of the catalogue (B 03/034 SF-03),
    // and typographic dashes are ignored like hyphens.
    expect(searchGuideItems(MockData.guideItems, 'd'), isEmpty);
    expect(searchGuideItems(MockData.guideItems, '4'), isEmpty);
    expect(_ids(searchGuideItems(MockData.guideItems, 'D–10')),
        contains('d10-job-seeking'));
    // Hyphens inside multi-word queries are ignored like in single words.
    expect(_ids(searchGuideItems(MockData.guideItems, 'd-4 d-2')),
        contains('status-change-d4-to-d2'));
  });
}
