import 'package:campus_on/app.dart';
import 'package:campus_on/data/mock/guide_items_expansion.dart';
import 'package:campus_on/data/mock/guide_items_safety.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-09 guide expansion (18 → up to 28). Pins which new guides actually
/// shipped, catalogue-wide integrity (ids, in-app links), KO/EN parity for the
/// new items, and the rules each new guide restates from its official source.
///
/// A passing run means the app data is consistent with what was written — it
/// is not evidence that the rules are still current; the sources and check
/// dates live in each item's comment and in the lead report.

/// Guides implemented and published so far, in list order. Drafts that are
/// still missing a core source are not in the app and not listed here.
const _shipped = [
  'part-time-work',
  'academic-status-and-visa',
  'academic-probation',
  'address-and-registration-changes',
  'd10-job-seeking',
  'tuition-payment',
  'residence-card-reissue',
  'departure-checklist',
  'graduation-requirements',
  'rental-deposit-protection',
  'status-change-d4-to-d2',
  'class-attendance-and-exams',
];

Future<ProviderScope> _app() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const CampusOnApp(),
  );
}

AdminGuideItem _item(String id) =>
    MockData.guideItems.firstWhere((g) => g.id == id);

Iterable<GuideLink> _allLinks(AdminGuideItem g) => [
      ...g.links,
      for (final s in [...g.topSections, ...g.sections]) ...s.links,
    ];

String _text(AdminGuideItem g, {required bool ko}) => <String?>[
      ko ? g.titleKo : g.titleEn,
      ko ? g.detailTitleKo : g.detailTitleEn,
      ko ? g.summaryKo : g.summaryEn,
      ko ? g.overviewKo : g.overviewEn,
      ...(ko ? g.checklistKo : g.checklistEn),
      ...(ko ? g.checklistOptionalKo : g.checklistOptionalEn),
      ko ? g.checklistNoteKo : g.checklistNoteEn,
      ...(ko ? g.stepsKo : g.stepsEn),
      ...(ko ? g.tipsKo : g.tipsEn),
      for (final s in [...g.topSections, ...g.sections]) ...[
        ko ? s.titleKo : s.titleEn,
        ko ? s.bodyKo : s.bodyEn,
        ...(ko ? s.stepsKo : s.stepsEn),
        for (final n in s.notes) ...[
          ko ? n.titleKo : n.titleEn,
          ...(ko ? n.linesKo : n.linesEn),
        ],
        ko ? s.noticeKo : s.noticeEn,
        ko ? s.footnoteKo : s.footnoteEn,
      ],
      for (final l in _allLinks(g)) ...[
        ko ? l.labelKo : l.labelEn,
        ko ? l.descriptionKo : l.descriptionEn,
      ],
    ].whereType<String>().join('\n');

void _expectPair(String? ko, String? en, String what) {
  expect((ko ?? '').trim().isEmpty, (en ?? '').trim().isEmpty,
      reason: '$what: KO/EN presence differs');
}

void main() {
  group('catalogue integrity', () {
    test('expansion ships exactly the implemented guides, after the 18', () {
      expect(ExpansionGuides.items.map((g) => g.id), _shipped);
      // The 2026-09-26 safety batch is appended after the expansion, so the
      // expansion's own slice is bounded on both sides now.
      expect(
          MockData.guideItems
              .skip(18)
              .take(_shipped.length)
              .map((g) => g.id),
          _shipped);
    });

    test('the safety batch is appended last, and only once', () {
      const safety = [
        'moving-and-utilities',
        'waste-and-recycling',
        'consumer-disputes',
        'financial-scam-response',
      ];
      expect(SafetyGuides.items.map((g) => g.id), safety);
      expect(MockData.guideItems.skip(18 + _shipped.length).map((g) => g.id),
          safety);
    });

    test('ids are unique across the whole catalogue', () {
      final ids = MockData.guideItems.map((g) => g.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('existing guides link to the new guide that owns the next step', () {
      const backLinks = {
        'dormitory': 'address-and-registration-changes',
        'off-campus-housing': 'rental-deposit-protection',
        'stay-extension': 'address-and-registration-changes',
        'visa-types': 'part-time-work',
        'course-registration': 'graduation-requirements',
        'certificate-issue': 'departure-checklist',
        'health-insurance': 'departure-checklist',
        'incident-response': 'residence-card-reissue',
      };
      backLinks.forEach((from, to) {
        expect(_allLinks(_item(from)).map((l) => l.url),
            contains('/guide/item/$to'),
            reason: '$from → $to');
      });
    });

    test('every in-app guide link points at a published guide', () {
      final published = {
        for (final g in MockData.guideItems)
          if (g.status == GuideStatus.published) g.id,
      };
      for (final g in MockData.guideItems) {
        for (final l in _allLinks(g)) {
          if (!l.url.startsWith('/guide/item/')) continue;
          final target = l.url.substring('/guide/item/'.length);
          expect(published, contains(target), reason: '${g.id} → ${l.url}');
        }
      }
    });
  });

  group('new guides: KO/EN parity and icons', () {
    for (final id in _shipped) {
      test(id, () {
        final g = _item(id);
        expect(g.status, GuideStatus.published);
        expect(g.hasNoContent, isFalse);
        _expectPair(g.titleKo, g.titleEn, 'title');
        expect(g.titleKo.trim(), isNotEmpty);
        _expectPair(g.detailTitleKo, g.detailTitleEn, 'detailTitle');
        _expectPair(g.summaryKo, g.summaryEn, 'summary');
        expect((g.summaryKo ?? '').trim(), isNotEmpty);
        _expectPair(g.overviewKo, g.overviewEn, 'overview');
        expect((g.overviewKo ?? '').trim(), isNotEmpty);
        expect(g.checklistKo.length, g.checklistEn.length, reason: 'checklist');
        expect(g.checklistOptionalKo.length, g.checklistOptionalEn.length,
            reason: 'optional checklist');
        _expectPair(g.checklistOptionalTitleKo, g.checklistOptionalTitleEn,
            'optional checklist title');
        _expectPair(g.checklistNoteKo, g.checklistNoteEn, 'checklist note');
        expect(g.stepsKo.length, g.stepsEn.length, reason: 'steps');
        expect(g.stepsKo, isNotEmpty);
        expect(g.tipsKo.length, g.tipsEn.length, reason: 'tips');
        expect(guideIconFromName(g.iconName), isNotNull, reason: 'item icon');

        for (final s in [...g.topSections, ...g.sections]) {
          final where = 'section ${s.titleKo}';
          _expectPair(s.titleKo, s.titleEn, where);
          _expectPair(s.bodyKo, s.bodyEn, '$where body');
          _expectPair(s.noticeKo, s.noticeEn, '$where notice');
          _expectPair(s.footnoteKo, s.footnoteEn, '$where footnote');
          expect(s.stepsKo.length, s.stepsEn.length, reason: '$where steps');
          if (s.iconName != null) {
            expect(guideIconFromName(s.iconName), isNotNull, reason: where);
          }
          if (s.noticeIconName != null) {
            expect(guideIconFromName(s.noticeIconName), isNotNull,
                reason: '$where notice icon');
          }
          for (final n in s.notes) {
            _expectPair(n.titleKo, n.titleEn, '$where note');
            expect(n.linesKo.length, n.linesEn.length,
                reason: '$where note ${n.titleKo}');
          }
        }
        for (final l in _allLinks(g)) {
          _expectPair(l.labelKo, l.labelEn, 'link ${l.url}');
          _expectPair(l.descriptionKo, l.descriptionEn, 'link ${l.url}');
          if (l.iconName != null) {
            expect(guideIconFromName(l.iconName), isNotNull,
                reason: 'link icon ${l.url}');
          }
        }
      });
    }
  });

  group('part-time-work restates the 2026-09 HiKorea manual', () {
    final g = _item('part-time-work');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('permission comes first; school confirmation is not permission', () {
      expect(ko, contains('학교 확인서는 허가가 아닙니다'));
      expect(en, contains('confirmation is not the permission'));
      expect(g.categoryId, GuideCategory.immigration);
    });

    test('eligibility: D-2 sub-types at once, D-4 / D-2-8 after 6 months', () {
      expect(ko, contains('D-2-1~D-2-4, D-2-6, D-2-7'));
      expect(ko, contains('6개월이 지나야'));
      expect(en, contains('D-2-1 to D-2-4, D-2-6 and D-2-7'));
      expect(en, contains('6 months have passed'));
      expect(ko, contains('C학점(2.0) 미만'));
      expect(en, contains('below C (2.0)'));
      // Thesis-stage students: 30 h cap, no unlimited weekends (05/026 S-2).
      expect(ko, contains('주당 30시간까지이고 주말·공휴일·방학 무제한 규정은 적용되지'));
      expect(en, contains('only up to 30 hours a week'));
    });

    test("hours follow the '23.7 table plus the 5-hour bonus", () {
      expect(ko, contains('전문학사·학사 주당 10시간, 석·박사 주당 15시간'));
      expect(ko, contains('전문학사·학사 25시간, 석·박사 30시간'));
      expect(ko, contains('전문학사·학사 30시간, 석·박사 35시간'));
      expect(en, contains('25 weekday hours'));
      expect(en, contains('30 for associate and bachelor’s, 35 for'));
      // The old figures still printed on the manual's confirmation form
      // (학부 20 · 인증대학 25) must not come back.
      expect(ko, isNot(contains('주당 20시간 이내')));
      // D-4 hours are sourced to Study in Korea and not flattened into one
      // weekly total (B 03/028 SF-03); the permit decides the exact range.
      expect(ko, contains('본인의 시간 범위는 허가서에서 확인하세요'));
      expect(en, contains('Check your exact limit on your permit'));
      // D-4 row shows one limit for weekends too (05/026 N-2, table colspan).
      expect(ko, contains('어학연수 행은 주말·방학에도 같은 한도로 표시돼 있습니다'));
      // English-track students are not told they need Korean (SF-01).
      expect(ko, isNot(contains('공통으로 일정 수준의 한국어 능력')));
      expect(en, isNot(contains('Everyone needs a set level of Korean')));
      expect(ko, contains('영어트랙은 인정되는 영어 기준'));
    });

    test('period, workplaces, change of employer and sanctions', () {
      expect(ko, contains('최장 1년'));
      expect(ko, contains('2곳까지'));
      expect(ko, contains('최장 6개월, 1곳만'));
      expect(en, contains('at most 2 workplaces'));
      // Manual (new permission) and HiKorea e-application (change report)
      // word the workplace change differently; both are shown, not merged.
      expect(ko, contains('사전에 새로이 시간제 취업허가를 받아야 함'));
      expect(ko, contains('시간제취업 업체변경 신고'));
      expect(en, contains('workplace change report'));
      // Sanctions are possibilities decided case by case, not certainties.
      expect(ko, contains('두 번째 적발되면 강제퇴거될 수 있습니다'));
      expect(en, contains('second offence can lead to deportation'));
      // The fee is shown as a conflict between sources, not asserted.
      expect(ko, isNot(contains('수수료는 면제입니다')));
      expect(ko, contains('2만원으로 적고 있어 서로 다르니'));
      // Dong-A's own page differs from the manual — flagged, not hidden.
      expect(ko, contains('「제조업 불가」'));
    });

    test('links: HiKorea, manual notice, labour helpline, in-app guides', () {
      final urls = _allLinks(g).map((l) => l.url).toList();
      expect(urls, contains('https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=2189'));
      expect(urls, contains('https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=2190'));
      expect(urls.any((u) => u.contains('NTCCTT_SEQ=1062')), isTrue);
      expect(urls, contains('tel:1350'));
      expect(urls, containsAll(['/guide/item/oia-visit', '/guide/item/visa-types']));
    });
  });

  group('academic-status-and-visa keeps school and immigration apart', () {
    final g = _item('academic-status-and-visa');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('school reports within 15 days; immigration decides the stay', () {
      expect(g.categoryId, GuideCategory.school);
      expect(ko, contains('15일 안에 출입국'));
      expect(ko, contains('제19조의4'));
      expect(ko, contains('학교가 승인했다고 체류가 그대로 보장되는 것은 아닙니다'));
      expect(en, contains('University approval does not guarantee your stay'));
      // The manual's extension restriction for personal-reason leave.
      expect(ko, contains('체류기간 연장을 제한'));
      expect(en, contains('extensions are restricted'));
      // No blanket answer on staying in Korea during leave.
      expect(ko, contains('일반적으로 정한 공식 안내는 찾지 못했습니다'));
      for (final banned in const [
        '휴학하면 비자가 취소',
        '휴학해도 비자는 유지',
        '반드시 출국해야',
        '제적 사유는 8가지',
      ]) {
        expect(ko, isNot(contains(banned)), reason: banned);
      }
    });

    test('Dong-A leave, carry-over, return, withdrawal and refunds', () {
      expect(ko, contains('최대 8학기(5년제는 10학기), 한 번에 최대 2학기'));
      expect(ko, contains('첫 학기에는 일반휴학이 허용되지 않습니다'));
      expect(ko, contains('30일까지 휴학: 전액 이월'));
      expect(ko, contains('90일이 지난 뒤 휴학: 이월하지 않음'));
      expect(ko, contains('미복학제적'));
      // MN125's swapped semester/month wording is not repeated (SF-02).
      expect(ko, isNot(contains('1학기는 8월')));
      expect(en, isNot(contains('August for spring')));
      expect(ko, contains('해당 학기 학사공지에서 확인'));
      expect(ko, contains('30일까지 6분의 5'));
      expect(en, contains('five sixths up to day 30'));
      expect(ko, contains('재입국허가가 면제될 수 있습니다'));
      expect(en, contains('may be exempt from a re-entry permit'));
    });
  });

  group('academic-probation restates Dong-A MN134 / MN135', () {
    final g = _item('academic-probation');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('warning threshold, notice, credit limit and dismissal', () {
      expect(g.categoryId, GuideCategory.school);
      expect(ko, contains('평점평균이 1.5 미만이거나, 9학점 이상을 F'));
      expect(en, contains('GPA below 1.5, or 9 or more credits graded F'));
      expect(ko, contains('평생지도교수와 상담해야'));
      expect(ko, contains('3학점 제한'));
      expect(ko, contains('통산 3회: 성적불량으로 제적'));
      expect(en, contains('3rd in total: dismissal'));
    });

    test('repeating a year, and grades vs stay without repeating rules', () {
      expect(ko, contains('평점평균 1.2 미만'));
      expect(ko, contains('2.7 미만(간호학과 2.3 미만)'));
      expect(ko, contains('유급 통산 2회(희망유급 제외)'));
      expect(ko, contains('C학점(2.0) 미만이면 허가가 제한될 수'));
      final urls = _allLinks(g).map((l) => l.url);
      expect(urls, containsAll(const [
        '/guide/item/stay-extension',
        '/guide/item/academic-status-and-visa',
        '/guide/item/course-registration',
      ]));
    });
  });

  group('address-and-registration-changes separates art. 36 from art. 35', () {
    final g = _item('address-and-registration-changes');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('two reports: start day, office and sanction differ', () {
      expect(g.categoryId, GuideCategory.immigration);
      expect(ko, contains('새 주소로 전입한 날부터 15일 이내'));
      expect(ko, contains('변경된 날부터 15일 이내'));
      expect(ko, contains('100만원 이하의 벌금 대상(출입국관리법 제98조)'));
      expect(ko, contains('100만원 이하의 과태료 대상(제100조)'));
      // Adjustments never exceed the statutory cap (B 03/029 S-01).
      expect(ko, contains('법률상 상한(100만원)을 넘을 수 없습니다'));
      expect(en, contains('cannot exceed the statutory cap'));
      expect(ko, contains('읍·면·동 주민센터'));
      expect(en, contains('within 15 days of moving in'));
      expect(en, contains('an administrative fine of up to ₩1 million'));
      // Dong-A's 14-day wording is flagged, never adopted as the rule.
      expect(ko, contains('「변경일로 14일 이내」'));
      expect(ko, isNot(contains('14일 이내에 신고해야')));
    });

    test('passport online vs personal details in person; no portal myth', () {
      expect(ko, contains('이름·생년월일·성별이 하나라도 바뀌었다면 반드시'));
      expect(en, contains('you must visit the immigration office'));
      expect(ko, contains('업무일 기준 3일 이내'));
      expect(ko, contains('출입국 신고는 따로 하세요'));
      final urls = _allLinks(g).map((l) => l.url);
      expect(urls, contains('https://www.hikorea.go.kr/cvlappl/cvlapplInfoR.pt?CAT_SEQ=1807'));
      expect(urls, containsAll(const ['/guide/item/off-campus-housing', '/guide/item/dormitory']));
    });
  });

  group('d10-job-seeking follows the 2026-09 D-10 chapter', () {
    final g = _item('d10-job-seeking');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('exemption is for the first change only; points test otherwise', () {
      expect(g.categoryId, GuideCategory.immigration);
      expect(ko, contains('처음으로 D-10-1로 바꾸는 경우'));
      expect(ko, contains('연장할 때는 점수제를 적용합니다'));
      expect(ko, contains('190점 중 기본항목 20점 이상이고 총점 60점 이상'));
      expect(ko, contains('학위증만 인정'));
      expect(en, contains('extensions use the points test'));
      expect(ko, contains('단순 노무 일자리를 찾기 위한 자격이 아닙니다'));
    });

    test('stay caps, part-time exception and open questions', () {
      expect(ko, contains('누적 상한은 최대 3년'));
      expect(ko, contains('「6개월씩 최대 2년」'));
      // Manufacturing needs KIIP 4+, TOPIK alone does not count; agriculture
      // has no language requirement (B 03/029 B-01).
      expect(ko, contains('농업은 어학 요건이 없지만'));
      expect(ko, contains('TOPIK 성적만으로는 제조업 허가 대상이 되지 않습니다'));
      expect(en, contains('TOPIK alone does not qualify you for manufacturing'));
      expect(ko, isNot(contains('TOPIK 4급 이상) 등 요건을 갖춘 사람에게 제조업')));
      expect(ko, contains('15일 안에 외국인등록사항 변경신고'));
      // Fee and pre-conferral application are flagged, not asserted.
      expect(ko, contains('119,000원'));
      expect(ko, contains('학위 수여 전에 졸업예정 서류로 신청할 수 있는지'));
      for (final banned in const [
        '누구나 D-10을 받을 수',
        'D-10이면 아르바이트를 할 수 있습니다',
        '수수료는 10만원입니다',
      ]) {
        expect(ko, isNot(contains(banned)), reason: banned);
      }
      expect(_allLinks(g).map((l) => l.url), contains('/guide/item/part-time-work'));
    });
  });

  group('tuition-payment restates MN159 without semester-specific dates', () {
    final g = _item('tuition-payment');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('period, banks, bill path, confirmation next day', () {
      expect(g.categoryId, GuideCategory.school);
      expect(ko, contains('1학기는 2월 말, 2학기는 8월 말'));
      expect(ko, contains('부산은행·농협은행'));
      expect(ko, contains('등록장학 › 등록금고지서 발급'));
      expect(ko, contains('납부한 다음 날부터'));
      expect(ko, contains('미등록제적'));
      expect(en, contains('BNK Busan Bank or NongHyup Bank'));
      // A ₩0 bill is not assumed to need no registration step (B 03/030 SF-01).
      expect(ko, contains('납부액이 0원이라면'));
      expect(en, contains('If your bill is ₩0'));
    });

    test('dated or unconfirmed payment terms are labelled, not asserted', () {
      expect(ko, contains('직전 학기 공지(2025-2학기) 기준'));
      expect(ko, contains('해외 송금이나 카드 납부 조건을 적은 학교 공식 안내는 찾지 못했습니다'));
      expect(ko, contains('부산은행(가상계좌 가능)으로만'));
      for (final banned in const [
        '카드로 낼 수 있습니다',
        '해외에서 송금하면 됩니다',
        '24시간',
        '휴학하면 등록금을 돌려받',
      ]) {
        expect(ko, isNot(contains(banned)), reason: banned);
      }
      // No 2026-2 regular registration dates were confirmed, so none appear.
      expect(ko, isNot(contains('8.1.')));
    });
  });

  group('residence-card-reissue owns the procedure, not the first response', () {
    final g = _item('residence-card-reissue');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('grounds, documents, fee and no invented deadline', () {
      expect(g.categoryId, GuideCategory.immigration);
      expect(ko, contains('성명·성별·생년월일·국적이 바뀌어 변경신고를 한 경우'));
      expect(ko, contains('수수료 35,000원'));
      // Photo size is a national form rule, not office-specific (B 03/030 SF-02).
      expect(ko, contains('3.5×4.5cm 정면 사진'));
      expect(en, isNot(contains('office-specific')));
      expect(ko, contains('수수료 면제 대상자(정부초청장학생 등)도'));
      expect(ko, contains('재발급 신청 기한이 적혀 있지 않습니다'));
      expect(en, contains('sets no deadline for applying'));
      for (final banned in const ['14일 이내에 신청', '반드시 벌금', '온라인으로 전 과정']) {
        expect(ko, isNot(contains(banned)), reason: banned);
      }
    });

    test('incident-response links here, and this guide links back', () {
      expect(_allLinks(g).map((l) => l.url), contains('/guide/item/incident-response'));
      expect(
        _allLinks(_item('incident-response')).map((l) => l.url),
        contains('/guide/item/residence-card-reissue'),
      );
    });
  });

  group('departure-checklist splits trips from leaving for good', () {
    final g = _item('departure-checklist');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('card return, re-entry exemption and conditional refunds', () {
      expect(g.categoryId, GuideCategory.immigration);
      expect(ko, contains('반납하는 것이 원칙입니다'));
      // Card-return exceptions follow art. 37 wording, not a blanket rule
      // (감사 05/026 S-1).
      expect(ko, contains('반납하지 않는 경우가 있습니다'));
      expect(ko, isNot(contains('반납하지 않아도 됩니다')));
      expect(en, contains('you may not have to hand in your Residence Card'));
      expect(ko, contains('유학(D-2)·일반연수(D-4) 체류자는'));
      // Reachable from other new guides (S-4).
      final incoming = MockData.guideItems
          .where((x) => x.id != g.id)
          .where((x) => _allLinks(x).any((l) => l.url == '/guide/item/departure-checklist'))
          .map((x) => x.id)
          .toSet();
      expect(incoming, containsAll(const [
        'd10-job-seeking',
        'academic-status-and-visa',
        'residence-card-reissue',
      ]));
      expect(ko, contains('재입국허가가 면제될 수 있습니다'));
      expect(ko, contains('재입국 면제는 체류기간을 늘려 주지 않습니다'));
      expect(ko, contains('1개월 이상 해외에 머물면 출국 다음 날 자격이 끝남'));
      expect(ko, contains('국민연금 반환일시금은 모든 외국인에게 주지 않습니다'));
      expect(en, contains('may be exempt from a re-entry permit'));
      for (final banned in const [
        '무조건 반납',
        '누구나 1년 안에',
        '반드시 해지해야 합니다',
        '모두 환급',
      ]) {
        expect(ko, isNot(contains(banned)), reason: banned);
      }
      expect(_allLinks(g).map((l) => l.url), containsAll(const [
        '/guide/item/health-insurance',
        '/guide/item/d10-job-seeking',
      ]));
    });
  });

  group('graduation-requirements restates MN137 / MN139 as a check routine', () {
    final g = _item('graduation-requirements');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('audit path, GPA floor, international-track rules', () {
      expect(g.categoryId, GuideCategory.school);
      expect(ko, contains('학업성적 사정표'));
      // GPA floor keeps the pre-2009 exception; foreign rules are scoped to
      // the international track (B 03/031 SF-01, SF-02).
      expect(ko, contains('원칙적으로 2.0 이상'));
      expect(ko, contains('2008학년도 이전 신입생은 학교 안내의 1.5 기준'));
      expect(ko, isNot(contains('외국인 학생은 TOPIK 4급 이상 취득과')));
      expect(en, isNot(contains('international students also need TOPIK')));
      expect(ko, contains('2011학년도 이후 외국인 특별전형 입학생(편입 포함)'));
      expect(ko, contains('2017학년도 이후 외국인 특별전형 입학생(편입 제외)'));
      expect(ko, contains('TOPIK 5급 이상과 학과 졸업시험'));
      expect(en, contains('must generally be 2.0 or higher'));
      // Required-course counts stay in course-registration (sources differ).
      expect(ko, isNot(contains('9과목 26학점')));
      expect(ko, isNot(contains('6과목 16학점')));
    });

    test('deferral conditions and fee; completion is not graduation', () {
      expect(ko, contains('총 2회(1년)'));
      expect(ko, contains('정규학기 등록금의 5.5%'));
      expect(ko, contains('졸업학점이나 영역별 학점이 부족하면 신청할 수 없습니다'));
      // Thesis-not-passed completers may apply (B 03/031 B-01).
      expect(ko, contains('졸업논문을 통과하지 못한 수료예정자도 신청할 수 있지만'));
      expect(en, contains('not passed the graduation thesis, you may still apply'));
      expect(ko, isNot(contains('졸업요건을 모두 채운 학생이 신청하는 제도')));
      // Deferral status effects (감사 05/027 S-1).
      expect(ko, contains('재학증명서가 발급되지 않고'));
      expect(ko, contains('승인 뒤에는 취소할 수 없습니다'));
      expect(en, contains('an approved deferral cannot be cancelled'));
      expect(ko, contains('수료는 졸업이 아니며'));
      expect(ko, isNot(contains('총 졸업학점만 채우면 자동')));
    });
  });

  group('rental-deposit-protection adds to off-campus-housing, no guarantees', () {
    final g = _item('rental-deposit-protection');
    final ko = _text(g, ko: true);
    final en = _text(g, ko: false);

    test('opposability, fixed date, return guarantee, end-of-lease rules', () {
      expect(g.categoryId, GuideCategory.housing);
      expect(ko, contains('그다음 날부터 제3자에게'));
      expect(ko, contains('체류지 변경신고가 주민등록과 전입신고를'));
      expect(ko, contains('전액 회수를 보장한다는 뜻은 아닙니다'));
      expect(ko, contains('1건 600원'));
      expect(ko, contains('「개인, 법인, 외국인도 보증가입이 가능」'));
      expect(ko, contains('계약이 끝나기 2개월 전까지'));
      expect(ko, contains('3개월이 지나면 효력'));
      expect(ko, contains('임차권등기명령'));
      // Lease reporting gives an automatic fixed date (감사 05/027 S-2).
      expect(ko, contains('계약 체결일부터 30일 안에 신고'));
      expect(en, contains('a fixed date is given automatically'));
      // 5% cap is general (art. 7) and the renewal right has its own window
      // (B 03/032 SF-01, SF-02).
      expect(ko, contains('증액청구는 원칙적으로 약정액의 5%'));
      expect(ko, contains('6개월 전부터 2개월 전까지 1회'));
      expect(en, contains('within 1 year of the contract or the last increase'));
      expect(ko, isNot(contains('(계약갱신요구권 행사 시)')));
      expect(en, contains('does not guarantee you get it all back'));
      for (final banned in const [
        '보증금은 안전합니다',
        '외국인은 확정일자를 받을 수 없',
        '80%를 넘으면 사기',
        '자동으로 보증금을 돌려받',
        '원래 계약기간만큼 연장',
      ]) {
        expect(ko, isNot(contains(banned)), reason: banned);
      }
      expect(_allLinks(g).map((l) => l.url), containsAll(const [
        '/guide/item/off-campus-housing',
        '/guide/item/address-and-registration-changes',
        'tel:132',
      ]));
    });
  });

  group('30-guide batch: D-4 to D-2 and attendance/exams', () {
    test('status-change-d4-to-d2 shows source differences, no invented deadline', () {
      final g = _item('status-change-d4-to-d2');
      final ko = _text(g, ko: true);
      final en = _text(g, ko: false);
      expect(g.categoryId, GuideCategory.immigration);
      expect(ko, contains('학위과정 수업을 시작하기 전에'));
      expect(ko, contains('구체적인 마감일이 따로 적혀 있지 않지만'));
      expect(ko, contains('처리시간이 접수일부터 1개월 이내'));
      expect(en, contains('up to 1 month from receipt'));
      expect(ko, contains('본인 명의가 아니면 거주·숙소제공확인서와 계약자 신분증 앞·뒷면 사본 추가'));
      expect(en, contains('if the lease is not in your name'));
      expect(ko, contains('119,000원'));
      expect(ko, contains('13만원 표기는 현행 법정 금액과 다릅니다'));
      expect(ko, contains('3.5×4.5cm 정면 사진'));
      expect(en, contains('taken within the last 6'));
      expect(en, contains('KRW 100,000 for the change of status'));
      expect(ko, isNot(contains('동아대 국제교류과 안내: 13만원')));
      expect(ko, contains('1,600만원 이상(본교 어학연수생은 800만원)'));
      expect(ko, contains('통지서 발급일부터 14일 이내'));
      expect(en, contains('14 days of the date the notice is issued'));
      expect(en, contains('does not say whether a part-time work permit'));
      for (final b in const ['수수료는 13만원입니다', '무조건 허가', '반드시 ○월']) {
        expect(ko, isNot(contains(b)), reason: b);
      }
    });

    test('class-attendance-and-exams keeps the rules and flags the conflicts', () {
      final g = _item('class-attendance-and-exams');
      final ko = _text(g, ko: true);
      final en = _text(g, ko: false);
      expect(g.categoryId, GuideCategory.school);
      expect(ko, contains('3분의 1을 초과해 결석하면 해당 과목 성적은 F 또는 NP'));
      expect(ko, contains('통산 무단결석이 4주 이상'));
      expect(ko, contains('「사유 발생 전후 2주 이내(휴일 포함)」'));
      expect(ko, contains('「사유 발생일로부터 2주 이내」'));
      // Employment/start-up exception (B 03/033 B-01); exam ID for
      // international students (감사 05/029 S-1).
      expect(ko, contains('공결취소원과 관련 서류를 내야'));
      expect(ko, contains('외국인등록증이나 여권을 가져가세요'));
      expect(ko, isNot(contains('학생증·외국인등록증·여권 등')));
      expect(en, contains('submit the cancellation form'));
      expect(en, contains('Bring your Residence Card or passport'));
      for (final b in const [
        'but not once it is approved',
        'student ID, Residence Card, passport and so on',
      ]) {
        expect(en, isNot(contains(b)), reason: b);
      }
      expect(ko, isNot(contains('승인된 공결은 취소할 수 없습니다')));
      expect(ko, contains('학사안내(가능)와 2026-2학기 공지(대면 수업만)가 달라'));
      expect(ko, contains('담당 교수에게 직접 이의신청'));
      expect(en, contains('sets no rule for a missed exam'));
      for (final b in const ['시험도 다시 볼 수 있습니다', '결석이 4번이면 F', '학사관리과에 이의신청']) {
        expect(ko, isNot(contains(b)), reason: b);
      }
    });

    test('both are reachable and searchable', () {
      expect(_allLinks(_item('academic-probation')).map((l) => l.url),
          contains('/guide/item/class-attendance-and-exams'));
      expect(_allLinks(_item('part-time-work')).map((l) => l.url),
          contains('/guide/item/status-change-d4-to-d2'));
      expect(searchGuideItems(MockData.guideItems, '공결').map((g) => g.id),
          contains('class-attendance-and-exams'));
      expect(searchGuideItems(MockData.guideItems, '비자 변경').map((g) => g.id),
          contains('status-change-d4-to-d2'));
      expect(MockData.guideItems, hasLength(34),
          reason: '30 + the four added after the 2026-09-26 gap review');
    });
  });

  testWidgets('part-time-work: find it in the list, read it, follow a link',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Immigration & Stay'));
    await tester.pumpAndSettle();

    expect(find.text('Part-time Work Permission'), findsOneWidget);
    await tester.tap(find.text('Part-time Work Permission'));
    await tester.pumpAndSettle();

    expect(find.text('Getting Permission for Part-time Work'), findsOneWidget);
    expect(find.text('Can I apply?'), findsOneWidget);
    expect(find.text('What to prepare'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);

    final link = find.text('Guide — International Affairs Office');
    await tester.scrollUntilVisible(link, 400);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();
    // `/guide/item/oia-visit` opens in-app: its own first section is there.
    expect(find.text('What can I ask about?'), findsOneWidget);
    // Drain the related-location lookup (mock repo delay).
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });
}
