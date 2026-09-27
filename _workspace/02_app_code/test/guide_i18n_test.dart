import 'dart:ui';

import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/data/i18n/guide_translation_overlay.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// Four-language support: how a language is chosen, what shows when a field is
/// not translated yet, and that Chinese/Vietnamese text is searchable.
///
/// The fixtures here are a hand-written overlay, so these tests keep passing
/// whatever the translators have delivered so far.

const _ko = Locale('ko');
const _en = Locale('en');
const _zh = Locale('zh');
const _vi = Locale('vi');

AdminGuideItem _item({Map<String, Object?> tree = const {}, String lang = 'zh'}) {
  const base = AdminGuideItem(
    id: 'demo',
    categoryId: GuideCategory.living,
    titleKo: '은행 계좌 개설',
    titleEn: 'Open a Bank Account',
    summaryKo: '신분증을 준비하세요',
    summaryEn: 'Bring your ID',
    checklistKo: ['여권', '외국인등록증'],
    checklistEn: ['Passport', 'Residence Card'],
    searchAliasesKo: ['통장'],
    searchAliasesEn: ['passbook'],
    sections: [
      GuideSection(
        titleKo: '수수료',
        titleEn: 'Fees',
        bodyKo: '은행마다 다릅니다',
        bodyEn: 'It differs by bank',
        notes: [
          GuideNote(
              titleKo: '확인할 것',
              titleEn: 'What to check',
              linesKo: ['수수료 10만원'],
              linesEn: ['KRW 100,000 fee']),
        ],
      ),
    ],
    phrases: [GuidePhrase(ko: '계좌를 만들고 싶습니다.', en: 'I would like to open an account.')],
    links: [
      GuideLink(
          labelKo: '하이코리아',
          labelEn: 'HiKorea',
          url: 'https://www.hikorea.go.kr/',
          descriptionKo: '전자민원',
          descriptionEn: 'E-application'),
    ],
    status: GuideStatus.published,
  );
  return applyGuideTranslations([base], byLanguage: {
    lang: {'demo': tree}
  }).single;
}

void main() {
  group('language table', () {
    test('ships four languages, in menu order', () {
      expect(appLanguageCodes, ['ko', 'en', 'zh', 'vi']);
      expect(supportedAppLocales.map((l) => l.languageCode).toList(),
          appLanguageCodes);
      expect(appLanguageNames,
          {'ko': '한국어', 'en': 'English', 'zh': '简体中文', 'vi': 'Tiếng Việt'});
    });

    test('falls back requested → English → Korean', () {
      expect(languageFallback('zh'), ['zh', 'en', 'ko']);
      expect(languageFallback('vi'), ['vi', 'en', 'ko']);
      expect(languageFallback('ko'), ['ko', 'en']);
      expect(languageFallback('en'), ['en', 'ko']);
      // An unknown code is treated as English rather than crashing.
      expect(languageFallback('ja'), ['en', 'ko']);
      expect(isSupportedLanguage('zh'), isTrue);
      expect(isSupportedLanguage('ja'), isFalse);
      expect(isSupportedLanguage(null), isFalse);
    });
  });

  group('guide text in four languages', () {
    test('untranslated guide shows English, never a blank or a key', () {
      final g = _item();
      expect(g.title(_zh), 'Open a Bank Account');
      expect(g.summary(_vi), 'Bring your ID');
      expect(g.checklist(_zh), ['Passport', 'Residence Card']);
      expect(g.sections.single.title(_vi), 'Fees');
      expect(g.sections.single.notes.single.lines(_zh), ['KRW 100,000 fee']);
      expect(g.links.single.label(_zh), 'HiKorea');
      expect(g.phrases.single.meaning(_vi), 'I would like to open an account.');
    });

    test('translated fields win, missing ones fall back per field', () {
      final g = _item(tree: {
        'title': '开设银行账户',
        'checklist': ['护照', '外国人登录证'],
        'sections': [
          {
            'title': '手续费',
            'notes': [
              {'lines': ['手续费 10万韩元']}
            ],
          }
        ],
        'links': [
          {'label': 'HiKorea(韩国出入境)'}
        ],
        'phrases': [
          {'text': '我想开一个账户。'}
        ],
      });
      expect(g.title(_zh), '开设银行账户');
      expect(g.checklist(_zh), ['护照', '外国人登录证']);
      expect(g.sections.single.title(_zh), '手续费');
      // body was not translated → English, not blank.
      expect(g.sections.single.body(_zh), 'It differs by bank');
      expect(g.sections.single.notes.single.lines(_zh), ['手续费 10万韩元']);
      // The note title was not translated either.
      expect(g.sections.single.notes.single.title(_zh), 'What to check');
      expect(g.links.single.label(_zh), 'HiKorea(韩国出入境)');
      expect(g.links.single.description(_zh), 'E-application');
      expect(g.phrases.single.meaning(_zh), '我想开一个账户。');
      // Korean line of a phrase is what the user shows at the counter — kept.
      expect(g.phrases.single.ko, '계좌를 만들고 싶습니다.');
      // Korean and English readers are unaffected by the overlay.
      expect(g.title(_ko), '은행 계좌 개설');
      expect(g.title(_en), 'Open a Bank Account');
      expect(g.checklist(_en), ['Passport', 'Residence Card']);
    });

    test('an empty translation is treated as missing', () {
      final g = _item(tree: {'title': '   ', 'summary': ''});
      expect(g.title(_zh), 'Open a Bank Account');
      expect(g.summary(_zh), 'Bring your ID');
    });

    test('Firestore documents carry the same overlay (i18n map)', () {
      final doc = AdminGuideItem.fromJson(const {
        'id': 'demo',
        'categoryId': 'living',
        'title_ko': '은행 계좌 개설',
        'title_en': 'Open a Bank Account',
        'status': 'published',
        'i18n': {
          'vi': {
            'title': 'Mở tài khoản ngân hàng',
            'search_aliases': ['mở tài khoản'],
          },
          // Languages the app does not ship are ignored.
          'ja': {'title': '銀行口座の開設'},
        },
      });
      expect(doc.title(_vi), 'Mở tài khoản ngân hàng');
      expect(doc.title(_zh), 'Open a Bank Account');
      expect(doc.title(_ko), '은행 계좌 개설');
      expect(doc.i18n.containsKey('ja'), isFalse);
      // A document written before this change still loads.
      final legacy = AdminGuideItem.fromJson(const {
        'id': 'old',
        'categoryId': 'living',
        'title_ko': '옛 문서',
        'title_en': 'Old document',
        'status': 'published',
      });
      expect(legacy.i18n, isEmpty);
      expect(legacy.title(_vi), 'Old document');
    });
  });

  group('search across languages', () {
    List<String> ids(Iterable<AdminGuideItem> r) => r.map((g) => g.id).toList();

    final zhItem = _item(tree: {
      'title': '开设银行账户',
      'search_aliases': ['银行卡', '开户'],
    });
    final viItem = _item(
        lang: 'vi',
        tree: {
          'title': 'Mở tài khoản ngân hàng',
          'search_aliases': ['học phí', 'đăng ký'],
        });

    test('Chinese title and alias find the guide', () {
      expect(ids(searchGuideItems([zhItem], '开户')), ['demo']);
      expect(ids(searchGuideItems([zhItem], '开设银行账户')), ['demo']);
      expect(ids(searchGuideItems([zhItem], '银行卡')), ['demo']);
    });

    test('Vietnamese matches with or without tone marks, and đ/d', () {
      expect(ids(searchGuideItems([viItem], 'học phí')), ['demo']);
      expect(ids(searchGuideItems([viItem], 'hoc phi')), ['demo']);
      expect(ids(searchGuideItems([viItem], 'đăng ký')), ['demo']);
      expect(ids(searchGuideItems([viItem], 'dang ky')), ['demo']);
      expect(ids(searchGuideItems([viItem], 'tai khoan')), ['demo']);
    });

    test('Korean and English search is unchanged', () {
      expect(ids(searchGuideItems([zhItem], '통장')), ['demo']);
      expect(ids(searchGuideItems([zhItem], 'passbook')), ['demo']);
      expect(ids(searchGuideItems([zhItem], '은행')), ['demo']);
      // Ranking of the shipped catalogue keeps working.
      final real = MockData.guideItems;
      expect(ids(searchGuideItems(real, '졸업')).first, 'graduation-requirements');
      expect(ids(searchGuideItems(real, '등록금')).first, 'tuition-payment');
      expect(searchGuideItems(real, 'd'), isEmpty);
    });
  });
}
