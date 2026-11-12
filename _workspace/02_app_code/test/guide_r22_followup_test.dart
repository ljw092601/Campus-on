import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// r22 (2026-10-30/31) follow-up verification. Pins what the round added so it
/// cannot quietly fall away: the new sections are reachable by the words a
/// student would type (B 03/119 F-1 — search covers titles, aliases, detail
/// titles and summaries only, so each new topic needs an alias), and the
/// corrected facts keep their official limits.
void main() {
  List<String> ids(String q) =>
      searchGuideItems(MockData.guideItems, q).map((g) => g.id).toList();

  AdminGuideItem byId(String id) =>
      MockData.guideItems.firstWhere((g) => g.id == id);

  group('검색 — 새 내용에 닿는다 (네 언어)', () {
    const reach = {
      '1600-0051': 'counseling',
      '스터디부산허브': 'counseling',
      'Study Busan Hub': 'counseling',
      '거점병원': 'hospital-guide',
      'hub hospitals': 'hospital-guide',
      '定点医院': 'hospital-guide',
      'bệnh viện đầu mối': 'hospital-guide',
      '휴학 출국': 'academic-status-and-visa',
      'leave of absence departure': 'academic-status-and-visa',
      '休学 出国': 'academic-status-and-visa',
      'bảo lưu xuất cảnh': 'academic-status-and-visa',
    };
    reach.forEach((q, id) {
      test('「$q」 → $id', () {
        expect(ids(q), contains(id));
      });
    });
  });

  test('해외 소포: 휴대폰 개통 링크를 걸지 않는다(공식 인증 수단에 통신사 인증 없음)', () {
    final g = byId('overseas-parcels-and-customs');
    expect(g.links.map((l) => l.url), isNot(contains('/guide/item/mobile-plan')));
  });

  // 감사 05/073 R-3·R-4 → 074 R-4 (r22 근거 정리에서 미고정 발견): 도용 신고 뒤
  // 조치는 관세청 FAQ 원문대로 권고형이고 사용정지도 선택지에 있다 / 외국인에게
  // 열리는지 확인하지 못한 간편인증 사업자 이름은 적지 않는다.
  test('해외 소포: 도용 뒤 조치는 권고형(사용정지 포함), 간편인증 사업자 예시 없음', () {
    final g = byId('overseas-parcels-and-customs');
    // 감사 05/076 R-1: all three options, not only suspension.
    // 감사 05/077 R-1: 「해지」 alone also matches 「재발급과 해지 뒤 신규 발급」
    // later in the step, so the cancel option is pinned in its own slot.
    for (final option in const ['사용정지', '부호변경(재발급)', '해지 중 하나']) {
      expect(g.stepsKo[6], contains(option), reason: option);
    }
    expect(g.stepsKo[6], contains('안내하고'));
    expect(g.stepsKo[6], isNot(contains('해지하거나 부호를 바꿔(재발급) 써야')));
    for (final option in const [
      'advises suspending',
      'changing it (reissue)',
      'cancelling it',
    ]) {
      expect(g.stepsEn[6], contains(option), reason: option);
    }
    // 감사 05/076 R-2: no provider name anywhere in the guide, not only in
    // the checklist.
    final all = [
      g.titleKo, g.titleEn, g.summaryKo, g.summaryEn,
      g.overviewKo, g.overviewEn, g.checklistNoteKo, g.checklistNoteEn,
      ...g.checklistKo, ...g.checklistEn, ...g.stepsKo, ...g.stepsEn,
      ...g.tipsKo, ...g.tipsEn,
      for (final s in [...g.topSections, ...g.sections]) ...[
        s.titleKo, s.titleEn, s.bodyKo, s.bodyEn, s.noticeKo, s.noticeEn,
        s.footnoteKo, s.footnoteEn, ...s.stepsKo, ...s.stepsEn,
        for (final n in s.notes) ...[n.titleKo, n.titleEn, ...n.linesKo, ...n.linesEn],
        for (final l in s.links) '${l.labelKo}${l.labelEn}${l.descriptionKo ?? ''}${l.descriptionEn ?? ''}',
      ],
      for (final l in g.links) '${l.labelKo}${l.labelEn}${l.descriptionKo ?? ''}${l.descriptionEn ?? ''}',
    ].whereType<String>().join(' ');
    for (final banned in const ['네이버', '카카오', '금융기관 등', 'Naver', 'Kakao']) {
      expect(all.contains(banned), isFalse, reason: banned);
    }
  });

  test('해외 소포: 유효기간은 예고가 아니라 현행 포털 안내로 적는다', () {
    final g = byId('overseas-parcels-and-customs');
    final ko = [
      for (final s in g.sections)
        for (final n in s.notes) ...n.linesKo,
    ].join('\n');
    expect(ko, contains('2027'));
    expect(ko, isNot(contains('예고했습니다')));
  });
}
