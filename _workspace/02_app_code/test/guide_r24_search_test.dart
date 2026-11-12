import 'package:campus_on/data/i18n/guide_translations.g.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// r24 (2026-11-01) user-selected additions 27·28·29·30·33·34 went into
/// existing guides, so the guide count stays at 41. Search covers titles,
/// aliases, detail titles and summaries only, so each topic is pinned to the
/// guide that holds its text by the words a student would type.
void main() {
  List<String> ids(String q) =>
      searchGuideItems(MockData.guideItems, q).map((g) => g.id).toList();

  test('가이드 개수는 41개 그대로다', () {
    expect(MockData.guideItems, hasLength(41));
  });

  group('검색 — r24 보강 내용의 가이드가 맨 위에 온다', () {
    const first = {
      // 27 고장 · 원상회복
      '고장': 'off-campus-housing',
      'repair': 'off-campus-housing',
      '원상복구': 'rental-deposit-protection',
      '보증금 공제': 'rental-deposit-protection',
      'move-out': 'rental-deposit-protection',
      // 28 표준계약서 번역본
      '표준계약서': 'off-campus-housing',
      'standard lease': 'off-campus-housing',
      // 29 엠세이퍼
      '엠세이퍼': 'mobile-plan',
      'msafer': 'mobile-plan',
      '명의도용': 'mobile-plan',
      // 30 스케일링
      '스케일링': 'health-insurance',
      'scaling': 'health-insurance',
      // 33 공동생활
      '층간소음': 'off-campus-housing',
      'noise': 'off-campus-housing',
      // 34 외국인등록 사실증명
      '사실증명': 'residence-card-reissue',
      '외국인등록 사실증명': 'residence-card-reissue',
      // zh (A 02/103)
      '洗牙': 'health-insurance',
      '标准合同': 'off-campus-housing',
      '层间噪音': 'off-campus-housing',
      '扣押金': 'rental-deposit-protection',
      '身份冒用': 'mobile-plan',
      '外国人登录事实证明': 'residence-card-reissue',
      // vi (조사 04/079) — 성조 있음 · 없음
      'cạo vôi răng': 'health-insurance',
      'cao voi rang': 'health-insurance',
      'hợp đồng mẫu': 'off-campus-housing',
      'tiếng ồn giữa các tầng': 'off-campus-housing',
      'khấu trừ tiền đặt cọc': 'rental-deposit-protection',
      'đánh cắp danh tính': 'mobile-plan',
      'giấy chứng nhận thông tin đăng ký người nước ngoài':
          'residence-card-reissue',
    };
    first.forEach((q, id) {
      test(q, () {
        final r = ids(q);
        expect(r, isNotEmpty, reason: q);
        expect(r.first, id, reason: '$q → $r');
      });
    });
  });

  // B 03/128 S-2: the vi no-smoking alias `cấm hút thuốc` folds to contain
  // `thuoc` (medicine) and `cam` (as in `thuốc cảm`, cold medicine), so those
  // queries put housing first until the hospital guide got exact-match slots.
  group('검색 — r24 별칭이 기존 의료 검색을 빼앗지 않는다', () {
    const first = {
      '약': 'hospital-guide',
      '감기약': 'hospital-guide',
      'thuốc': 'hospital-guide',
      'thuoc': 'hospital-guide',
      'thuốc cảm': 'hospital-guide',
      'thuoc cam': 'hospital-guide',
      'cấm hút thuốc': 'off-campus-housing',
      'cam hut thuoc': 'off-campus-housing',
      'sua chua': 'off-campus-housing',
      'don ra': 'rental-deposit-protection',
      'danh cap danh tinh': 'mobile-plan',
    };
    first.forEach((q, id) {
      test(q, () {
        final r = ids(q);
        expect(r, isNotEmpty, reason: q);
        expect(r.first, id, reason: '$q → $r');
      });
    });
  });

  // 감사 05/087 R-1: the user's limits for this round, pinned by key words
  // only so later rewording is still free.
  group('내용 — 사용자 지시의 한계가 남아 있다 (ko · en)', () {
    AdminGuideItem byId(String id) =>
        MockData.guideItems.firstWhere((g) => g.id == id);
    GuideNote note(String id, String titleKo) => [
          ...byId(id).topSections,
          ...byId(id).sections,
        ].expand((s) => s.notes).firstWhere((n) => n.titleKo == titleKo);
    String ko(GuideNote n) => n.linesKo.join('\n');
    String en(GuideNote n) => n.linesEn.join('\n');

    test('29 가입제한은 신규만이 아니라 번호이동 · 명의변경도 막고, 기기변경은 확인으로 둔다', () {
      final n = note('mobile-plan', '🚫 가입제한 서비스');
      expect(ko(n), allOf(contains('번호이동'), contains('명의변경'), contains('통신사마다')));
      expect(en(n), allOf(contains('number transfers'), contains('name holder'),
          contains('differ by carrier')));
      // 감사 05/088 R-1(a): 기기변경은 확정 차단 목록([0])에 다시 들어오지 않고
      // 통신사별 확인 줄([1])에만 있다(B 03/128 R-1 — 두 공식 페이지가 다르다).
      expect(n.linesKo[0].contains('기기'), isFalse);
      expect(n.linesEn[0].contains('device'), isFalse);
      expect(n.linesKo[1], contains('기기만 바꿀'));
      expect(n.linesEn[1], contains('device change'));
    });

    test('29 외국인 인증 조건과 온라인이 어려울 때의 경로가 있다', () {
      final id = note('mobile-plan', '🪪 외국인 본인확인');
      expect(ko(id), allOf(contains('외국인등록증'), contains('계좌')));
      expect(en(id), allOf(contains('Residence Card'), contains('account')));
      final off = note('mobile-plan', '🏬 온라인이 어렵다면');
      expect(ko(off), allOf(contains('지점'), contains('전화나 이메일로는')));
      expect(en(off), allOf(contains('branch'), contains('phone or email')));
    });

    test('30 스케일링은 무료가 아니고 금액 · 비율을 적지 않는다', () {
      final n = note('health-insurance', '치과 스케일링(치석제거)');
      expect(ko(n), contains('무료가 아니라'));
      expect(en(n), contains('not free'));
      expect(ko(n) + en(n), isNot(matches(RegExp(r'\d[\d,]*\s*원|₩|\d+\s*%'))));
    });

    test('33 공동생활에는 시간 · 소음 수치 · 과태료가 없다', () {
      final n = note('off-campus-housing', '🤝 함께 사는 건물에서');
      final t = ko(n) + en(n);
      for (final banned in ['데시벨', 'dB', '과태료', '벌금']) {
        expect(t.contains(banned), isFalse, reason: banned);
      }
      expect(t, isNot(matches(RegExp(r'\bfines?\b', caseSensitive: false))));
      expect(
          t,
          isNot(matches(RegExp(
              r'\d+\s*시|\d{1,2}:\d{2}|\d+\s*(?:a\.?m\.?|p\.?m\.?)(?![a-z])',
              caseSensitive: false))));
    });

    // r24 보완(외부 검토 1): the centre does not handle every noise the
    // first line lists (its FAQ excludes washing machines and voices), so the
    // line must not say it advises on any dispute — only to check first
    // whether the housing and the kind of noise are covered. Still 3 rules.
    test('33 이웃사이센터는 주택과 소음 종류가 대상인지 먼저 확인하라고만 한다', () {
      final n = note('off-campus-housing', '🤝 함께 사는 건물에서');
      expect(n.linesKo, hasLength(3));
      expect(n.linesKo[0], allOf(contains('줄여 주세요'), contains('1661-2642'),
          contains('거주 주택과 소음 종류가 상담 대상인지 먼저 확인')));
      expect(n.linesKo[0], isNot(contains('상담할 수 있습니다')));
      expect(n.linesEn[0], allOf(contains('keep down'),
          contains('type of housing and the kind of noise')));
      expect(n.linesEn[0], isNot(contains('gives advice')));
    });

    // 감사 05/090 R-2: the same three conditions in the zh · vi overlays.
    test('33 이웃사이센터 줄 — zh · vi 도 권고 유지 · 단정 없음 · 소음 종류 확인', () {
      List<String> strings(Object? v) => v is String
          ? [v]
          : v is Map
              ? v.values.expand(strings).toList()
              : v is List
                  ? v.expand(strings).toList()
                  : <String>[];
      const want = {
        'zh': ['减少', '噪音种类', '咨询对象'],
        'vi': ['hãy giảm', 'loại tiếng ồn', 'phạm vi tư vấn'],
      };
      const banned = {
        'zh': ['可以向', '纠纷'],
        'vi': ['có thể nhận tư vấn', 'tranh chấp'],
      };
      for (final lang in want.keys) {
        final hits = strings(guideTranslationsByLanguage[lang])
            .where((s) => s.contains('1661-2642'))
            .toList();
        expect(hits, hasLength(1), reason: lang);
        for (final w in want[lang]!) {
          expect(hits.single, contains(w), reason: '$lang $w');
        }
        for (final b in banned[lang]!) {
          expect(hits.single.contains(b), isFalse, reason: '$lang $b');
        }
      }
    });

    test('28 번역본 노트는 효력이나 「한국어만」을 말하지 않는다', () {
      final n = note('off-campus-housing', '🌐 번역본으로 조항 비교하기');
      final t = ko(n) + en(n);
      for (final banned in ['효력', '한국어만', '한국어 계약만', 'legal effect',
          'legally binding', 'only Korean', 'only in Korean']) {
        expect(t.contains(banned), isFalse, reason: banned);
      }
    });

    test('27 수리 부담은 일률적이지 않다고 말한다', () {
      final n = note('off-campus-housing', '🔧 사는 동안 고장이 나면');
      expect(ko(n), contains('일률적으로 정해져 있지 않으니'));
      expect(en(n), contains('no single rule'));
    });

    test('34 사실증명은 제출처 확인 줄을 유지하고 대리 신청 불가를 적는다', () {
      final n = note('residence-card-reissue', '카드가 없는 동안');
      expect(ko(n), allOf(contains('제출처마다'), contains('대리 신청 불가')));
      expect(en(n), allOf(contains('up to each of them'),
          contains("no applying on someone else's behalf")));
    });
  });
}
