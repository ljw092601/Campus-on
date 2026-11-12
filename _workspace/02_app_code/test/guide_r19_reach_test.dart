// r19 verification — "찾기 · 읽기 · 다음 행동" 세 가지를 앱이 실제로 쓰는 코드로
// 검증한다. 검색은 `searchGuideItems` 를 그대로 호출하고(재구현하지 않는다),
// 연결은 카탈로그의 링크를, 번역은 실제 오버레이가 적용된 엔티티를 본다.
//
// B 코덱스 03/109 의 지적 두 가지를 반영했다.
//   F-2: 첫 판은 `sections` / `topSections` / `notes` (필드)를 메서드처럼 호출해
//        컴파일되지 않았다. 지역화 접근자는 `title(l)`·`body(l)`·`notice(l)`·
//        `steps(l)`·`lines(l)`·`summary(l)` 뿐이고 배열은 필드다.
//   권고 1: 네 언어 주장이 영어 폴백으로 거짓 통과할 수 있었다. `_pickText` 는 한쪽이
//        비면 다른 언어로 떨어지므로, zh·vi 는 "비어 있지 않다"가 아니라
//        "ko 와도 en 과도 다르다"로 본다.
//
// zh·vi 검색과 zh·vi 제목 주장은 생성물 `guide_translations.g.dart` 에 의존한다.
// A 02/079 의 중국어가 들어오고 `i18n_tool.py gen` 이 성공한 뒤에 통과한다 —
// 그 전에는 실패하는 것이 맞다(미완성을 통과로 적지 않기 위한 장치다).
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:campus_on/domain/repositories/guide_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _ko = Locale('ko');
const _en = Locale('en');
const _zh = Locale('zh');
const _vi = Locale('vi');

List<AdminGuideItem> get _items => MockData.guideItems;

String _idsOf(List<AdminGuideItem> r) => r.map((g) => g.id).join(', ');

AdminGuideItem _byId(String id) => _items.firstWhere((g) => g.id == id);

/// 화면에서 차지하는 칸 수. CJK·전각 글자는 두 칸이다.
int _width(String s) => s.runes.fold(0, (n, r) {
      final wide = (r >= 0x1100 && r <= 0x115F) ||
          (r >= 0x2E80 && r <= 0xA4CF) ||
          (r >= 0xAC00 && r <= 0xD7A3) ||
          (r >= 0xF900 && r <= 0xFAFF) ||
          (r >= 0xFE30 && r <= 0xFE6F) ||
          (r >= 0xFF00 && r <= 0xFF60) ||
          (r >= 0xFFE0 && r <= 0xFFE6);
      return n + (wide ? 2 : 1);
    });

/// 목록 행의 요약이 두 줄에 담는 양.
///
/// **정정(감사 05/063).** 처음에는 56 을 썼다 — 감사 05/062 가 요약 칸을 196dp 로
/// 재면서 `trailing` 의 즐겨찾기 `IconButton` 48dp 를 빼먹었고, 나는 그 값을 그대로
/// 상수로 굳혔다. 감사가 위젯을 띄워 다시 재니 ListTile 254 − IconTile 44 −
/// IconButton 48 − 간격 16×2 = **요약 칸 130dp** 이고, 두 줄 용량은 56 이 아니라
/// **37.2폭**이다(1폭 6.75dp, ellipsis 9.03dp 차감). 내가 브라우저에서 200 % 로 보고
/// 적은 17~22폭도 감사의 17.9폭 계산과 맞는다 — 두 경로가 따로 같은 값에 닿았다.
///
/// **이 계약이 보장하는 것**: 320dp · **글자 100 %** 에서 목록 두 줄 안에 숫자가
/// 남는다는 **정적** 계약. 네 언어 × 35개를 자료 층에서 한꺼번에 본다.
///
/// **보장하지 않는 것**: 글자 배율 > 1(200 % 의 두 줄은 17.9폭뿐이다) · 비례 글꼴의
/// 실제 경계(Roboto 는 `i` 0.243em ~ `m` 0.876em) · 낱말 경계 줄바꿈 손실 · 숫자 뒤
/// 단위(`ngày`·「일 안에」)의 생존. 그것들은 **실제 브라우저 촬영**으로만 확인된다
/// (위젯 테스트의 시험 글꼴은 모든 글자가 같은 네모라 못 잡는다).
const _summaryTwoLineWidth = 36;

/// Every `/guide/item/<id>` target anywhere in a guide (top sections, sections
/// and the guide's own link list), which is what the screens actually render.
Set<String> _internalTargets(AdminGuideItem g) {
  const prefix = '/guide/item/';
  return {
    for (final l in [
      ...g.links,
      for (final s in [...g.topSections, ...g.sections]) ...s.links,
    ])
      if (l.url.startsWith(prefix)) l.url.substring(prefix.length),
  };
}

/// All Korean-authored prose of a guide, for loss checks.
String _koTextOf(AdminGuideItem g) => [
      g.titleKo,
      g.detailTitleKo ?? '',
      g.summaryKo ?? '',
      g.overviewKo ?? '',
      g.checklistNoteKo ?? '',
      ...g.checklistKo,
      ...g.stepsKo,
      ...g.tipsKo,
      for (final s in [...g.topSections, ...g.sections]) ...[
        s.titleKo,
        s.bodyKo ?? '',
        s.noticeKo ?? '',
        s.footnoteKo ?? '',
        ...s.stepsKo,
        for (final n in s.notes) ...[n.titleKo, ...n.linesKo],
      ],
      for (final l in g.links) ...[l.labelKo, l.descriptionKo ?? ''],
    ].join('\n');

void main() {
  group('찾기 — 앱이 쓰는 searchGuideItems 로 대표 검색어를 확인한다', () {
    // 한국어·영어: 생성물과 무관하게 원문 카탈로그만으로 판정된다.
    const koEnCases = <String, String>{
      '인권침해': 'counseling',
      // r23 D2 S1: 「성폭력」 별칭은 성 관련 전용 안내 정리로 지웠다(사용자 지시).
      '109': 'counseling',
      '자살': 'counseling',
      '쓰레기봉투': 'waste-and-recycling',
      '재활용': 'waste-and-recycling',
      '피해구제': 'consumer-disputes',
      '계좌지급정지': 'financial-scam-response',
      '계량기': 'moving-and-utilities',
      '입국': 'arrival-first-steps',
      '처음': 'arrival-first-steps',
      '순서': 'arrival-first-steps',
      'first steps': 'arrival-first-steps',
      'just arrived': 'arrival-first-steps',
      'suicide': 'counseling',
      'human rights': 'counseling',
      // 조사 04/052 결함 1·2 로 닫은 한국어·영어 구멍. 「경찰」은 요약·별칭 어디에도
      // 없어 한국어로도 0건이었다.
      '경찰': 'emergency-contacts',
      '구급차': 'emergency-contacts',
      '화재 신고': 'emergency-contacts',
      '경찰서': 'incident-response',
      '소비자 민원': 'consumer-disputes',
      '노동 분쟁': 'part-time-work',
      '체류지 신고': 'address-and-registration-changes',
      'police': 'emergency-contacts',
      'call an ambulance': 'emergency-contacts',
    };

    koEnCases.forEach((query, expectedId) {
      test('「$query」 → $expectedId', () {
        final results = searchGuideItems(_items, query);
        expect(results, isNotEmpty, reason: '「$query」 가 0건이다');
        expect(
          results.map((g) => g.id),
          contains(expectedId),
          reason: '「$query」 결과: ${_idsOf(results)}',
        );
      });
    });

    test('검색 결과를 누르면 상세로 갈 수 있다 — id 가 카탈로그에 실재한다', () {
      final ids = _items.map((g) => g.id).toSet();
      for (final q in koEnCases.keys) {
        for (final g in searchGuideItems(_items, q)) {
          expect(ids, contains(g.id));
        }
      }
    });
  });

  group('찾기 — 실제 중국어·베트남어 질의 (생성물 의존)', () {
    // 084 에서 0건이던 중국어 별칭과, 조사가 납품한 베트남어 별칭.
    const zhCases = <String, String>{
      '被骗': 'financial-scam-response',
      '冻结账户': 'financial-scam-response',
      '诈骗电话': 'financial-scam-response',
      '垃圾袋': 'waste-and-recycling',
      '入境': 'arrival-first-steps',
    };
    // 실제로 색인에 있는 말로 묻는다. 첫 판은 `bị lừa đảo` 처럼 별칭보다 긴 말을
    // 넣어 0건이 났다 — 별칭은 `lừa đảo` 다.
    //
    // `cảnh sát`(경찰)은 r19 에서 찾은 실제 검색 결함이었다. 색인은 제목·상세제목·
    // 요약·별칭만 보는데 `emergency-contacts` 의 ko 요약은 「112 · 119 긴급신고 안내」
    // 였고 ko 별칭에도 「경찰」이 없어 **한국어로도 「경찰」로 찾히지 않았다.**
    // 조사 04/051 이 vi 요약을, 04/052 가 ko·zh 요약과 네 언어 별칭을 닫았다 — 별칭은
    // 자리마다 같은 뜻으로 넣어야 해서 ko·en·zh·vi 를 같은 변경에서 늘렸다.
    const viCases = <String, String>{
      'lừa đảo': 'financial-scam-response',
      'đình chỉ thanh toán': 'financial-scam-response',
      'túi rác': 'waste-and-recycling',
      'nhập cảnh': 'arrival-first-steps',
      'cấp cứu': 'emergency-contacts',
      'cảnh sát': 'emergency-contacts',
    };

    zhCases.forEach((query, expectedId) {
      test('zh 「$query」 → $expectedId', () {
        final results = searchGuideItems(_items, query);
        expect(results.map((g) => g.id), contains(expectedId),
            reason: 'zh 「$query」 결과: ${_idsOf(results)} '
                '— A 02/079 중국어와 i18n_tool gen 이 선행 조건이다');
      });
    });

    viCases.forEach((query, expectedId) {
      test('vi 「$query」 → $expectedId', () {
        final results = searchGuideItems(_items, query);
        expect(results.map((g) => g.id), contains(expectedId),
            reason: 'vi 「$query」 결과: ${_idsOf(results)}');
      });
    });

    test('베트남어 성조를 지워도 같은 결과가 나온다', () {
      // 사용자가 성조 없이 치는 경우. `search_fold` 가 담당한다.
      expect(searchGuideItems(_items, 'nhap canh').map((g) => g.id),
          contains('arrival-first-steps'));
      expect(searchGuideItems(_items, 'cap cuu').map((g) => g.id),
          contains('emergency-contacts'));
    });
  });

  group('다음 행동 — 관련 가이드 링크가 끊긴 곳이 없다', () {
    late Map<String, Set<String>> inbound;

    setUp(() {
      inbound = {for (final g in _items) g.id: <String>{}};
      for (final g in _items) {
        for (final target in _internalTargets(g)) {
          expect(inbound.containsKey(target), isTrue,
              reason: '${g.id} → $target 는 없는 가이드를 가리킨다');
          if (target != g.id) inbound[target]!.add(g.id);
        }
      }
    });

    test('링크 대상이 모두 실재한다', () {
      expect(inbound.keys, hasLength(_items.length));
    });

    test('r19 에서 고친 네 가이드에 들어오는 링크가 생겼다', () {
      for (final id in [
        'waste-and-recycling',
        'moving-and-utilities',
        'consumer-disputes',
        'financial-scam-response',
      ]) {
        expect(inbound[id], isNotEmpty, reason: '$id 유입 0');
      }
    });

    test('금융사기 가이드는 고립되지 않은 출처에서 닿는다', () {
      // 084: 유일한 유입원이 그 자체로 고립된 consumer-disputes 였다.
      final sources = inbound['financial-scam-response']!;
      final reachable = sources.where((s) => inbound[s]!.isNotEmpty).toList();
      expect(reachable, isNotEmpty,
          reason: '유입원 $sources 가 모두 고립이면 사슬이 끊긴 것이다');
    });

    test('긴급 연락처가 다음 행동으로 내보낸다', () {
      final out = _internalTargets(_byId('emergency-contacts'));
      expect(out, containsAll(['incident-response', 'hospital-guide']));
    });

    test('도서관·교통카드에 맥락 있는 진입 경로가 있다', () {
      expect(inbound['library-guide'], isNotEmpty);
      expect(inbound['transit-card'], isNotEmpty);
    });
  });

  group('읽기 — 절차의 제목과 설명이 붙어 있지 않다 (네 언어)', () {
    const safety = [
      'moving-and-utilities',
      'waste-and-recycling',
      'consumer-disputes',
      'financial-scam-response',
    ];

    // 고친 방식이 곧 검사 기준이다: 제목과 설명 사이에 문장 구분이 들어갔다.
    // ko·en·vi 는 「. 」, zh 는 공백 없는 「。」 를 쓴다(A 02/079).
    // 첫 판은 `(다|요|니다)[가-힣]` 로 봤는데 「다음」·「다만」 같은 정상 낱말을
    // 붙은 절차로 잡는 오탐이 났다 — 그래서 구분자 유무로 바꿨다.
    const separators = {'ko': '. ', 'en': '. ', 'vi': '. ', 'zh': '。'};

    for (final locale in [_ko, _en, _zh, _vi]) {
      test('${locale.languageCode}: safety 4개의 절차에 문장 구분이 있다', () {
        final sep = separators[locale.languageCode]!;
        for (final id in safety) {
          final steps = _byId(id).steps(locale);
          expect(steps, isNotEmpty,
              reason: '$id (${locale.languageCode}) 절차 없음');
          for (final s in steps) {
            expect(s.contains(sep), isTrue,
                reason: '$id (${locale.languageCode}) 제목과 설명이 붙어 있다: $s');
            // 라틴 문자권에서 소문자 바로 뒤에 대문자가 붙는 것은 접합의 흔적이다.
            if (locale == _en) {
              expect(RegExp(r'[a-z][A-Z]').hasMatch(s), isFalse,
                  reason: '$id (en) 붙은 절차: $s');
            }
          }
        }
      });
    }
  });

  group('읽기 — 긴급 표현은 어느 언어에서도 읽을 한국어를 보여 준다', () {
    const korean = [
      '경찰이 필요합니다',
      '구급차를 보내주세요',
      '불이 났습니다',
      '사람이 다쳤습니다',
      '저는 동아대학교에 있습니다',
      '한국어를 잘 못합니다',
    ];

    GuideSection phraseSection() => _byId('emergency-contacts')
        .sections
        .firstWhere((s) => s.notes.length == korean.length);

    for (final locale in [_en, _zh, _vi]) {
      test('${locale.languageCode}: 6문장의 한국어가 화면에 남아 있다', () {
        final shown = phraseSection()
            .notes
            .expand((n) => n.lines(locale))
            .join(' | ');
        for (final k in korean) {
          expect(shown, contains(k),
              reason: '${locale.languageCode} 에서 「$k」 를 읽을 수 없다: $shown');
        }
      });

      test('${locale.languageCode}: 뜻도 함께 보인다 — 제목이 한국어도 영어도 아니다', () {
        for (final n in phraseSection().notes) {
          final t = n.title(locale).trim();
          expect(t, isNotEmpty);
          expect(korean.contains(t), isFalse,
              reason: '${locale.languageCode} 제목이 한국어라 뜻을 알 수 없다: $t');
          if (locale != _en) {
            // 영어 폴백으로 거짓 통과하지 않게: en 과 달라야 한다.
            expect(t, isNot(equals(n.title(_en).trim())),
                reason: '${locale.languageCode} 제목이 영어 폴백이다: $t');
          }
        }
      });
    }
  });

  group('A1 — 입국 길잡이가 요구대로 만들어졌다', () {
    late AdminGuideItem a1;
    setUp(() => a1 = _byId('arrival-first-steps'));

    test('published 다 — 기본값 comingSoon 으로 남으면 자리표시자가 나온다', () {
      // 첫 판은 `status` 를 빼먹어 기본값 comingSoon 이었다. 그 상태로는 상세 화면이
      // 내용 대신 자리표시자를 띄우고, `orderGuideItems` 가 published 와 coming-soon
      // 을 나눈 뒤 카탈로그 순서를 유지하므로 A1 이 입국·체류의 **맨 끝**으로 간다.
      expect(a1.status, GuideStatus.published);
      expect(a1.isComingSoon, isFalse);
      expect(a1.hasNoContent, isFalse);
    });

    test('입국·체류의 첫 번째다 — 앱이 쓰는 orderGuideItems 로 확인한다', () {
      final ordered = orderGuideItems(
          _items.where((g) => g.categoryId == GuideCategory.immigration));
      expect(ordered.first.id, 'arrival-first-steps');
      expect(ordered[1].id, 'arc-issue');
    });

    test('기존 가이드의 상세를 복사하지 않았다 — 절차는 5단계뿐', () {
      expect(a1.stepsKo, hasLength(5));
    });

    test('「2주」는 부정하는 문장 안에만 있고, 법정 기한은 90일이다', () {
      // 「도착 후 2주」 라는 말 자체는 그것이 기한이 아니라고 적는 notice 에만
      // 나와야 한다. 다른 어디에도 2주가 기한처럼 등장하면 안 된다.
      final notice = a1.topSections.first.noticeKo ?? '';
      expect(notice, contains('2주'));
      expect(notice, contains('없습니다'));
      final rest = _koTextOf(a1).replaceAll(notice, '');
      expect(rest.contains('2주'), isFalse,
          reason: 'notice 밖에서 2주가 기한처럼 쓰였다');
      expect(_koTextOf(a1), contains('90일'));
    });

    test('체류자격 차이를 구분한다 — D-4-1 의 6개월이 들어 있다', () {
      final all = _koTextOf(a1);
      expect(all, contains('D-4-1'));
      expect(all, contains('6개월'));
      expect(all, contains('D-2-6'));
    });

    test('필요한 가이드로 내보낸다', () {
      expect(
        _internalTargets(a1),
        containsAll([
          'arc-issue',
          'transit-card',
          'mobile-plan',
          'bank-account',
          'health-insurance',
        ]),
      );
    });

    // 조사 04/052 결함 3: 「여기 모은 절차 중 외국인등록만 기한이 있다」는 범위도
    // 여전히 넓었다. A1 은 살 곳 확보를 자기 단계로 포함하는데, 교외 임대차계약은
    // 금액 기준에 따라 계약일부터 30일 이내 신고 대상이다(「부동산 거래신고 등에
    // 관한 법률」 제6조의2). 그래서 비교 대상을 네 절차로 열거하고 임대차 신고를
    // 예외로 적는다.
    // 감사 05/062 F-1 로 요약은 짧게 바뀌었다. 요약은 이제 전체에 대한 주장을
    // 하지 않으므로(「외국인등록 90일 — 교통·통신·은행은 마감 없음」) 범위를 좁힐
    // 대상이 아니고, 대신 **잘려도 숫자가 남게** 앞에 있는지를 본다.
    // 감사 05/062 F-1 과 S-4: 폭은 네 언어 전부 재야 한다. 처음 판은 ko 60 ·
    // zh 61 · vi **160** 폭이었고, 목록 두 줄(320dp 에서 56~60폭)을 넘는 바람에
    // 끝에 있던 기한 숫자가 통째로 잘렸다. 320dp 레이아웃 검사는 이것을 잡지
    // 못한다 — 요약 잘림은 `maxLines: 2` + ellipsis 의 **설계된 동작**이라
    // 넘침이 아니고, `didExceedMaxLines` 는 제목에만 걸려 있다.
    test('네 언어 요약이 목록 두 줄에 들어가고 숫자가 앞에 있다', () {
      for (final locale in [_ko, _en, _zh, _vi]) {
        final s = a1.summary(locale)!;
        final code = locale.languageCode;
        expect(_width(s), lessThanOrEqualTo(60),
            reason: '$code 요약이 목록 두 줄을 넘는다 (${_width(s)}폭): $s');
        final at = s.indexOf('90');
        expect(at, greaterThanOrEqualTo(0), reason: '$code 요약에 90 이 없다: $s');
        expect(_width(s.substring(0, at)), lessThanOrEqualTo(30),
            reason: '$code 요약이 잘리면 기한 숫자가 먼저 사라진다: $s');
      }
      expect(a1.summaryKo, isNot(contains('여기 모은')));
    });

    test('유일성 주장의 범위가 비교 대상 네 절차로 한정돼 있다', () {
      final scoped = RegExp('외국인등록.{0,2}교통');
      for (final field in <String?>[
        a1.topSections.first.titleKo,
        a1.stepsKo[1],
        a1.tipsKo[0],
        a1.topSections.first.noticeKo,
      ]) {
        final t = field ?? '';
        expect(scoped.hasMatch(t), isTrue,
            reason: '유일성 주장에 비교 대상이 열거돼 있지 않다: $t');
      }
      // 범위를 밝히지 않는 옛 표현이 돌아오면 실패한다.
      expect(_koTextOf(a1).contains('여기 모은 절차 중 법정 기한'), isFalse);
    });

    test('임대차계약 신고기한을 빠뜨리지 않고 그 가이드로 보낸다', () {
      final t = _koTextOf(a1);
      expect(t, contains('30일'));
      expect(t, contains('임대차'));
      expect(_internalTargets(a1), contains('rental-deposit-protection'));
    });

    test('네 언어로 제목과 요약이 나온다 — zh·vi 는 폴백이 아니다', () {
      for (final locale in [_ko, _en, _zh, _vi]) {
        expect(a1.title(locale).trim(), isNotEmpty);
        expect(a1.summary(locale)?.trim() ?? '', isNotEmpty);
      }
      for (final locale in [_zh, _vi]) {
        expect(a1.title(locale).trim(),
            isNot(anyOf(equals(a1.titleKo.trim()), equals(a1.titleEn.trim()))),
            reason: '${locale.languageCode} 제목이 ko·en 폴백이다 '
                '— gen 이 선행 조건이다');
        expect(a1.summary(locale)?.trim(),
            isNot(anyOf(equals(a1.summaryKo?.trim()), equals(a1.summaryEn?.trim()))),
            reason: '${locale.languageCode} 요약이 ko·en 폴백이다');
      }
    });

    // 조사 04/048 2차: 「기한이 있는 것은 외국인등록 하나」가 가이드 범위를 넘어
    // 일반화돼 읽혔다. 범위를 적고, 신청 마감과 적용 시점을 구분한다.
    test('기한 서술이 이 가이드 범위를 넘어 일반화되지 않는다 (네 언어)', () {
      // 화면에 그대로 나가는 평문에 마크업이 남아 있지 않다.
      for (final t in [a1.overviewKo ?? '', a1.overviewEn ?? '']) {
        expect(t.contains('**'), isFalse, reason: '평문에 마크다운 `**` 가 남았다');
      }
      // 범위를 밝히는 말과 예외가 함께 있다.
      final ko = _koTextOf(a1);
      expect(ko, contains('15일'),
          reason: '체류지 변경신고의 별도 기한을 가리켜야 한다');
      expect(ko, contains('적용 시점'),
          reason: '건강보험은 신청 마감이 아니라 적용 시점이라는 구분이 있어야 한다');
      // 범위 없는 단정이 남아 있지 않다.
      for (final bad in [
        '기한이 있는 것은 외국인등록 하나',
        '법으로 정해진 것은 외국인등록의 90일뿐',
      ]) {
        expect(ko.contains(bad), isFalse, reason: '범위 없는 단정: $bad');
      }
    });

    // 감사 05/062 S-4 · B 03/113 S-3: 위 테스트는 이름이 「네 언어」인데 ko 만
    // 본다. 번역이 범위 없는 단정으로 되돌아가도 통과했다. zh·vi 에서도
    // 「마감이 있는 것은 외국인등록」이라는 문장 두 곳(overview · tips[0])이 비교
    // 대상 네 절차를 **그 자리에서** 열거하고, 별도 기한(30일·15일)과 건강보험의
    // 「적용 시점」 구분이 가이드 안에 있는지 본다. 어휘는 TERMS_ZH·TERMS_VI 와
    // 현재 번역에서 실측한 것이다.
    test('기한 서술의 범위 — zh·vi 도 네 절차를 열거하고 예외를 담는다', () {
      final scope = <Locale, List<String>>{
        _zh: ['外国人登录', '交通卡', '通信', '银行'],
        _vi: [
          'đăng ký người nước ngoài',
          'thẻ giao thông',
          'dịch vụ di động',
          'ngân hàng',
        ],
      };
      final extra = <Locale, List<String>>{
        _zh: ['30天', '15天', '适用时点'],
        _vi: ['30 ngày', '15 ngày', 'thời điểm'],
      };
      for (final locale in [_zh, _vi]) {
        final lc = locale.languageCode;
        for (final field in [a1.overview(locale) ?? '', a1.tips(locale).first]) {
          expect(field, isNot(contains(a1.tipsKo.first.substring(0, 6))),
              reason: '$lc 이 한국어 폴백이다');
          for (final term in scope[locale]!) {
            expect(field, contains(term),
                reason: '$lc 유일성 주장 옆에 비교 대상 「$term」이 없다: $field');
          }
        }
        final all = [
          a1.overview(locale) ?? '',
          a1.checklistNote(locale) ?? '',
          ...a1.tips(locale),
          for (final s in [...a1.topSections, ...a1.sections]) ...[
            s.body(locale) ?? '',
            s.notice(locale) ?? '',
            for (final n in s.notes) ...n.lines(locale),
          ],
        ].join('\n');
        for (final term in extra[locale]!) {
          expect(all, contains(term), reason: '$lc 에 「$term」이 없다');
        }
      }
    });
  });

  // B 코덱스 03/109 F-4: 34 → 35 는 숫자만 바꾸면 순서 회귀를 가린다.
  // 기존 34개의 선언 순서와 카테고리별 첫 항목을 계약으로 고정한다.
  group('정렬 계약 — A1 추가가 기존 순서를 흔들지 않았다', () {
    const a1Id = 'arrival-first-steps';

    // r21: 승인된 신규 2건과 리드 선정 1건이 safety 뒤에 붙어 38개가 됐다.
    // r19 의 35개 순서는 그대로여야 하므로 개수만 바꾸지 않고 끝 자리를 따로
    // 고정한다.
    const r21Ids = [
      'scholarships-and-topik',
      'campus-online-services',
      'overseas-parcels-and-customs',
    ];
    // r23: 사용자 선택 신규 3건이 r21 뒤에 붙었다.
    const r23Ids = [
      'graduate-degree-guide',
      'driving-and-e-scooters',
      'disaster-preparedness',
    ];

    test('카탈로그는 41개(r19 35 + r21 3 + r23 3)이고 A1 이 맨 앞이다', () {
      expect(_items, hasLength(41));
      expect(_items.first.id, a1Id);
    });

    test('A1 과 r21 3건 · r23 3건을 빼면 기존 34개가 남는다', () {
      expect(
          _items.where((g) =>
              g.id != a1Id && !r21Ids.contains(g.id) && !r23Ids.contains(g.id)),
          hasLength(34));
    });

    test('카테고리별 첫 항목은 immigration 만 바뀌었다', () {
      const baselineFirst = {
        GuideCategory.immigration: 'arc-issue',
        GuideCategory.school: 'course-registration',
        GuideCategory.housing: 'dormitory',
        GuideCategory.living: 'bank-account',
        GuideCategory.health: 'health-insurance',
        GuideCategory.emergency: 'emergency-contacts',
      };
      final withoutA1 = _items.where((g) => g.id != a1Id).toList();
      baselineFirst.forEach((category, expectedId) {
        final first = withoutA1.firstWhere((g) => g.categoryId == category);
        expect(first.id, expectedId,
            reason: '$category 의 첫 항목이 바뀌었다 (A1 제외 기준)');
      });
      final immigration =
          _items.where((g) => g.categoryId == GuideCategory.immigration);
      expect(immigration.first.id, a1Id);
      expect(immigration.elementAt(1).id, 'arc-issue');
    });

    test('r23 3건이 맨 끝, 그 앞에 r21 3건, 그 바로 앞에 safety 묶음 4개가 그대로 있다', () {
      expect(_items.sublist(_items.length - 3).map((g) => g.id), r23Ids);
      expect(_items.sublist(_items.length - 6, _items.length - 3).map((g) => g.id),
          r21Ids);
      expect(_items.sublist(_items.length - 10, _items.length - 6).map((g) => g.id), [
        'moving-and-utilities',
        'waste-and-recycling',
        'consumer-disputes',
        'financial-scam-response',
      ]);
    });

    test('id 가 중복되지 않는다', () {
      final ids = _items.map((g) => g.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('M1 — 옮긴 정보가 받는 쪽에 남아 있다', () {
    test('확정일자 기관 열거의 「공증인」이 보증금 가이드에 있다', () {
      expect(_koTextOf(_byId('rental-deposit-protection')), contains('공증인'));
    });

    test('임대차계약 신고 과태료가 보증금 가이드에 있다', () {
      final t = _koTextOf(_byId('rental-deposit-protection'));
      expect(t, contains('2025년 6월 1일'));
      expect(t, contains('과태료'));
    });

    test('제6조의2 법령 근거가 보증금 가이드에 있다', () {
      expect(_koTextOf(_byId('rental-deposit-protection')), contains('제6조의2'));
    });

    test('체류지 변경의 온라인 경로가 변경신고 가이드에 있다', () {
      final t = _koTextOf(_byId('address-and-registration-changes'));
      expect(t, contains('하이코리아 전자민원'));
      expect(t, contains('1345'));
    });

    test('15일·벌금 경고가 변경신고 가이드에서 notice 수준이다', () {
      final g = _byId('address-and-registration-changes');
      final notices = [...g.topSections, ...g.sections]
          .map((s) => s.noticeKo ?? '')
          .where((s) => s.isNotEmpty)
          .join(' ');
      expect(notices, contains('15일'));
      expect(notices, contains('100만원'));
    });

    test('교외주거 가이드는 「본인 신청」으로 단정하지 않는다', () {
      expect(_koTextOf(_byId('off-campus-housing')).contains('(본인 신청)'),
          isFalse);
    });

    // 조사 04/048 2차: 「사기 · 분쟁 예방」 4원칙과 「계약 전에 확인하세요」 3원칙은
    // 서로 다른 섹션이고 둘 다 보존돼야 한다.
    test('M2 — 계약 전 확인과 사기·분쟁 예방이 둘 다 남아 있다', () {
      final g = _byId('off-campus-housing');
      final t = _koTextOf(g);
      expect(t, contains('등기사항증명서'));
      expect(t, contains('위임'));
      final all = [...g.topSections, ...g.sections];
      final before = all.firstWhere((s) => s.titleKo == '계약 전에 확인하세요');
      // r24 후보 28: 세 원칙 뒤에 표준계약서 번역본 노트를 하나 붙였다(4번째).
      expect(before.notes, hasLength(4));
      expect(before.notes.last.titleKo, '🌐 번역본으로 조항 비교하기');
      final fraud = all.firstWhere((s) => s.titleKo == '사기 · 분쟁 예방');
      expect(fraud.notes, hasLength(4));
    });
  });

  // 084 D5: `course-registration` 은 34개 중 2위 분량(7,430자)이라 「기간 안에
  // 신청한다」는 핵심이 8개 절 중 7번째에 묻혀 있었다. 가이드를 쪼개지 않고 내부
  // 순서만 바꿨다. 순서가 계약인 이유는 번역이 `sections[N]` 색인으로 붙기
  // 때문이다 — ko 를 다시 섞으면서 zh·vi 색인을 같이 옮기지 않으면
  // `validate` 가 숫자만 보고 통과해 **다른 절의 번역이 조용히 붙는다.**
  group('D5 — 수강신청 내부 재배치가 유지된다', () {
    List<GuideSection> sectionsOf() => _byId('course-registration').sections;

    test('핵심 두 절이 맨 앞이다', () {
      final s = sectionsOf();
      expect(s[0].titleKo, '반드시 기간 안에 신청하세요');
      expect(s[1].titleKo, '외국인 유학생 필수이수교과목');
    });

    test('나머지 절의 순서와 개수가 그대로다', () {
      expect(sectionsOf().map((s) => s.titleKo).toList(), [
        '반드시 기간 안에 신청하세요',
        '외국인 유학생 필수이수교과목',
        '수업 내용을 미리 확인하세요',
        '수강신청 방법',
        '수강확정 · 탈락',
        '수강정정',
        '최종 수강신청 확인',
        '꼭 알아두세요',
        '학점이월제',
      ]);
    });

    // 감사 05/062 S-5: 학점이월제를 `topSections[2]` 에서 `sections` 맨 끝으로
    // 옮겼다. 위쪽에는 로그인·최대 학점 두 절만 남는다. 끝에 붙였으므로 앞 여덟
    // 절의 색인은 그대로다.
    test('S-5 — 학점이월제는 맨 끝, 위쪽은 두 절', () {
      final g = _byId('course-registration');
      expect(g.topSections.map((s) => s.titleKo).toList(),
          ['로그인 방법', '최대 수강신청 학점']);
      expect(g.sections.last.titleKo, '학점이월제');
      expect(g.sections.last.notes, hasLength(4));
    });

    // 색인이 어긋나면 여기서 「수업 내용을 미리 확인하세요」의 번역이 나온다.
    //
    // 감사 05/062 S-2: 앞 두 절만 고정하면 **나머지 여섯 절의 번역이 서로
    // 뒤바뀌어도 통과한다.** 그래서 여덟 자리를 전부 리터럴로 적는다.
    test('zh·vi 번역이 같이 옮겨졌다 — 아홉 자리 전부', () {
      const zh = [
        '一定要在期限内申请',
        '外国留学生必修课程',
        '请提前确认上课内容',
        '选课方法',
        '选课确定 · 落选',
        '选课更正',
        '最终选课确认',
        '一定要知道的事',
        '学分结转制',
      ];
      const vi = [
        'Phải đăng ký trong hạn',
        'Môn bắt buộc cho du học sinh',
        'Xem trước nội dung lớp',
        'Cách đăng ký',
        'Xác nhận · bị loại',
        'Chỉnh sửa đăng ký',
        'Kiểm tra đăng ký cuối',
        'Điều cần biết',
        'Chuyển tín chỉ chưa dùng',
      ];
      final s = sectionsOf();
      expect(s, hasLength(zh.length));
      for (var i = 0; i < s.length; i++) {
        expect(s[i].title(_zh), zh[i], reason: 'zh sections[$i]');
        expect(s[i].title(_vi), vi[i], reason: 'vi sections[$i]');
        expect(s[i].title(_zh), isNot(s[i].titleKo));
        expect(s[i].title(_vi), isNot(s[i].titleKo));
      }
    });
  });

  // 감사 05/062 F-1 은 A1 한 곳의 문제로 보였지만, A 02/082 가 같은 검사를 네
  // 언어 × 35개 가이드로 돌려 `address-and-registration-changes` 의 vi 에서 한
  // 건을 더 찾았다(87폭, 기한 `15` 가 문장 맨 끝). 그래서 한 곳을 고치는 대신
  // **계약으로 고정한다.**
  //
  // 요약이 60폭을 넘는 것 자체는 결함이 아니다 — 뒤가 잘려도 뜻이 남는 문장이
  // 있다(vi 에 60폭 초과가 12개 있다). 결함은 **기한·금액 숫자가 잘려 나가는
  // 것**이다. 그 숫자가 r19 가 드러내려던 정보이기 때문이다.
  group('읽기 — 목록 요약에서 숫자가 잘리지 않는다', () {
    final numbers = RegExp(r'\d+');

    for (final locale in [_ko, _en, _zh, _vi]) {
      test('${locale.languageCode} — 35개 요약의 숫자가 두 줄 안에 있다', () {
        final bad = <String>[];
        for (final g in _items) {
          final s = g.summary(locale) ?? '';
          for (final m in numbers.allMatches(s)) {
            if (_width(s.substring(0, m.end)) > _summaryTwoLineWidth) {
              bad.add('${g.id}: ${m.group(0)} @${_width(s.substring(0, m.end))}폭'
                  ' / 전체 ${_width(s)}폭 — $s');
            }
          }
        }
        expect(bad, isEmpty,
            reason: '${locale.languageCode} 요약에서 잘려 나가는 숫자:\n  '
                '${bad.join('\n  ')}');
      });
    }
  });

  group('읽기 — 화면에 나가는 평문에 마크다운이 없다', () {
    test('전체 카탈로그의 한국어 평문에 `**` 가 없다', () {
      for (final g in _items) {
        expect(_koTextOf(g).contains('**'), isFalse,
            reason: '${g.id} 의 평문에 `**` 가 있다');
      }
    });
  });

  // 감사 05/065 권고-5: 숫자 계약은 숫자만 본다. r20 은 「그 숫자의 조건·결과·행동」을
  // 두 줄 안에 두기로 했는데, 그 기준을 지키는 테스트가 없어 `academic-status-and-visa`
  // en 이 「…decide」에서 잘려 뜻이 뒤집힌 것을 아무 검사도 잡지 못했다. 그래서 다시
  // 쓴 요약 여섯 개에 대해 언어마다 **뜻을 쥔 낱말**이 앞 36폭 안에서 끝나는지 고정한다.
  //
  // 이 계약은 **어순**을 지킨다 — 렌더링은 보장하지 않는다(라틴 문자는 넓은 글자 때문에
  // 36폭보다 일찍 넘칠 수 있다, 감사 05/065 ②-2). 실제 잘림은 브라우저 촬영으로 본다.
  group('요약 핵심어 — 뜻을 쥔 낱말이 앞 36폭 안에 (네 언어)', () {
    final keys = <String, Map<Locale, String>>{
      'arc-issue': {_ko: '90일 초과', _en: 'Over 90 days', _zh: '超过90天', _vi: '>90 ngày'},
      'part-time-work': {
        _ko: '출입국 허가', _en: 'immigration', _zh: '出入境许可', _vi: 'Trước khi làm'
      },
      'academic-probation': {
        _ko: '3회면 제적', _en: 'dismissal', _zh: '除籍', _vi: 'buộc thôi học'
      },
      'status-change-d4-to-d2': {
        _ko: '수업 전', _en: 'before classes', _zh: '上课前', _vi: 'Trước khi học'
      },
      'academic-status-and-visa': {
        _ko: '따로', _en: 'separately', _zh: '分别', _vi: 'riêng'
      },
      'd10-job-seeking': {
        _ko: '점수제 면제',
        _en: 'skips the points test',
        _zh: '免除积分制',
        _vi: 'Miễn tính điểm'
      },
    };
    keys.forEach((id, byLocale) {
      test(id, () {
        final g = _byId(id);
        byLocale.forEach((locale, key) {
          final s = g.summary(locale) ?? '';
          final at = s.indexOf(key);
          expect(at, isNot(-1),
              reason: '$id ${locale.languageCode} 요약에 「$key」가 없다: $s');
          final end = _width(s.substring(0, at + key.length));
          expect(end, lessThanOrEqualTo(_summaryTwoLineWidth),
              reason: '$id ${locale.languageCode} 「$key」가 $end폭에서 끝난다 — '
                  '두 줄 밖이다: $s');
        });
      });
    });
  });
}
