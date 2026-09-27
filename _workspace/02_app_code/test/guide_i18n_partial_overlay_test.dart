import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Firestore document may carry a translation that covers only part of a
/// guide, or that was hand-edited into the wrong shape. The reader of that
/// language must still see every line (감사 05/034 S-6), and must never be
/// shown a stringified map.
///
/// The app's own data cannot get into these states — `i18n_tool.py validate`
/// keeps list lengths equal — so these cases come in through Firestore.

AdminGuideItem _item(Map<String, Object?> i18n) => AdminGuideItem.fromJson({
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '외국인등록',
      'title_en': 'Residence card',
      'summary_ko': '요약',
      'summary_en': 'Summary',
      'checklist_ko': const ['하나', '둘', '셋', '넷', '다섯'],
      'checklist_en': const ['one', 'two', 'three', 'four', 'five'],
      'i18n': i18n,
    });

AdminGuideItem _item2(Object? i18n) => AdminGuideItem.fromJson({
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '외국인등록',
      'title_en': 'Residence card',
      'checklist_ko': const ['하나', '둘', '셋', '넷', '다섯'],
      'checklist_en': const ['one', 'two', 'three', 'four', 'five'],
      'i18n': i18n,
    });

const _zh = Locale('zh');

void main() {
  test('a list translated in full is used as it stands', () {
    final g = _item({
      'zh': const {'checklist': ['一', '二', '三', '四', '五']}
    });
    expect(g.checklist(_zh), ['一', '二', '三', '四', '五']);
  });

  test('a half-translated list keeps every line, filling from English', () {
    final g = _item({
      'zh': const {'checklist': ['一', '二']}
    });
    expect(g.checklist(_zh), ['一', '二', 'three', 'four', 'five']);
  });

  test('a blank line inside a translation falls back for that line only', () {
    final g = _item({
      'zh': const {'checklist': ['一', '  ', '三']}
    });
    expect(g.checklist(_zh), ['一', 'two', '三', 'four', 'five']);
  });

  test('English missing too, the line falls through to Korean', () {
    final g = AdminGuideItem.fromJson(const {
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '제목',
      'checklist_ko': ['하나', '둘'],
      'i18n': {
        'zh': {'checklist': ['一']}
      },
    });
    expect(g.checklist(_zh), ['一', '둘']);
  });

  test('a list holding anything but strings is dropped, not printed', () {
    final g = _item({
      'zh': const {
        'checklist': [
          {'a': 1},
          '二'
        ]
      }
    });
    expect(g.checklist(_zh), ['one', 'two', 'three', 'four', 'five']);
    expect(g.checklist(_zh).join(), isNot(contains('{a: 1}')));
  });

  test('a field of the wrong type is dropped, and the rest still applies', () {
    final g = _item({
      'zh': const {'title': 42, 'summary': '概要'}
    });
    expect(g.title(_zh), 'Residence card'); // fell back, not "42"
    expect(g.summary(_zh), '概要');
  });

  test('an unsupported language in the document is ignored', () {
    final g = _item({
      'ja': const {'title': 'タイトル'},
      'zh': const {'title': '外国人登录'},
    });
    expect(g.i18n.keys, ['zh']);
    expect(g.title(_zh), '外国人登录');
  });

  test('a translation with more lines than the source keeps only the source ones',
      () {
    // The written ko/en data decides how many lines there are, so a stray extra
    // line in a document cannot add itself to the screen (감사 05/035 NIT-3).
    final g = _item({
      'zh': const {
        'checklist': ['一', '二', '三', '四', '五', '六', '七']
      }
    });
    expect(g.checklist(_zh), ['一', '二', '三', '四', '五']);
  });

  // A container of the wrong shape must be ignored, not thrown on: one such
  // document used to break the whole guide list (B 03/054 B-01).
  for (final bad in <Object>[42, 'nope', ['zh'], true]) {
    test('an i18n root of the wrong type (${bad.runtimeType}) is ignored', () {
      final g = _item2(bad);
      expect(g.i18n, isEmpty);
      expect(g.title(_zh), 'Residence card');
      expect(g.checklist(_zh), ['one', 'two', 'three', 'four', 'five']);
    });
  }

  for (final bad in <Object>['Mở tài khoản', 7, ['a', 'b']]) {
    test('a language holding a ${bad.runtimeType} instead of a map is skipped', () {
      final g = _item({'zh': bad, 'vi': const {'title': 'Thẻ cư trú'}});
      expect(g.i18n.keys, ['vi']);
      expect(g.title(_zh), 'Residence card');
      expect(g.title(const Locale('vi')), 'Thẻ cư trú');
    });
  }

  // Malformed fields outside i18n used to throw as well, which — since the
  // repository only caught FirebaseException — emptied the whole guide list
  // (B 03/054 NEW-B-01).
  test('a list field holding a number gives an empty list, not a crash', () {
    final g = AdminGuideItem.fromJson(const {
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '제목',
      'checklist_ko': 42,
      'checklist_en': ['one'],
    });
    expect(g.checklistKo, isEmpty);
    expect(g.checklist(const Locale('en')), ['one']);
  });

  test('a list item that is not a string is dropped', () {
    final g = AdminGuideItem.fromJson(const {
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '제목',
      'checklist_ko': ['하나', {'bad': 1}, '둘'],
      'relatedFacilityIds': ['lib', {'bad': 1}],
    });
    expect(g.checklistKo, ['하나', '둘']);
    expect(g.relatedFacilityIds, ['lib']);
  });

  test('a child collection with a non-map item skips that item', () {
    final g = AdminGuideItem.fromJson(const {
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '제목',
      'sections': [
        42,
        {'title_ko': '섹션'},
      ],
      'links': [7, {'label_ko': '링크', 'url': 'https://example.com'}],
      'phrases': ['nope', {'ko': '한국어 문장'}],
    });
    expect(g.sections.length, 1);
    expect(g.sections.single.titleKo, '섹션');
    expect(g.links.length, 1);
    expect(g.phrases.length, 1);
  });

  test('a difficulty of the wrong type does not throw', () {
    final easy = AdminGuideItem.fromJson(const {
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '제목',
      'meta': {'difficulty': 'easy'},
    });
    expect(easy.difficulty, isNull);
    final two = AdminGuideItem.fromJson(const {
      'id': 'demo',
      'categoryId': 'immigration',
      'title_ko': '제목',
      'meta': {'difficulty': '2'},
    });
    expect(two.difficulty, 2);
  });
}
