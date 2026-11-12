import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// r23 (2026-10-31) user-selected additions. Search covers titles, aliases,
/// detail titles and summaries only, so each new topic is pinned to the guide
/// that owns it by the words a student would type (B 03/126 — `1345` reached
/// nothing before the counseling alias was added).
void main() {
  List<String> ids(String q) =>
      searchGuideItems(MockData.guideItems, q).map((g) => g.id).toList();

  group('검색 — r23 새 내용이 맨 위에 온다 (네 언어)', () {
    const first = {
      '1345': 'counseling',
      '마을변호사': 'counseling',
      'village lawyer': 'counseling',
      '学位论文': 'graduate-degree-guide',
      '학위논문': 'graduate-degree-guide',
      'thesis': 'graduate-degree-guide',
      // B 03/127 R-4: 베트남어 질의(성조 있음·없음)도 고정한다.
      'luật sư cộng đồng': 'counseling',
      'luat su cong dong': 'counseling',
      'luận án': 'graduate-degree-guide',
    };
    first.forEach((q, id) {
      test(q, () {
        final r = ids(q);
        expect(r, isNotEmpty, reason: q);
        expect(r.first, id, reason: '$q → $r');
      });
    });
  });

  test('1345 는 상담 가이드 하나만 찾는다(긴급 연락처에는 다시 들어오지 않는다)', () {
    expect(ids('1345'), ['counseling']);
  });

  test('신규 3건은 제목으로 찾힌다 (ko·en)', () {
    for (final id in const [
      'graduate-degree-guide',
      'driving-and-e-scooters',
      'disaster-preparedness',
    ]) {
      final g = MockData.guideItems.firstWhere((g) => g.id == id);
      expect(ids(g.titleKo), contains(id), reason: g.titleKo);
      expect(ids(g.titleEn), contains(id), reason: g.titleEn);
    }
  });
}
