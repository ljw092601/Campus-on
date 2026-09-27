import 'dart:convert';
import 'dart:io';

import 'package:campus_on/app.dart';
import 'package:campus_on/core/router/app_router.dart';
import 'package:campus_on/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_on/core/i18n/app_languages.dart';
import 'package:campus_on/data/i18n/place_text.dart';
import 'package:campus_on/data/i18n/place_translations.g.dart';
import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:campus_on/data/repositories/mock_facility_repository.dart';
import 'package:campus_on/domain/entities/dining_menu.dart';
import 'package:campus_on/domain/entities/facility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facilities, cafeterias and the floor guide used to be Korean (some English)
/// whatever language the reader chose — the three screens a student uses most
/// often. These pin both halves: the translations that are in, and the
/// behaviour when one is missing.
void main() {
  const ko = Locale('ko');
  const en = Locale('en');
  const zh = Locale('zh');
  const vi = Locale('vi');

  group('facilities', () {
    Facility byId(String id) => MockData.facilities.firstWhere((f) => f.id == id);

    test('names read in the chosen language', () {
      final f = byId('s01');
      expect(f.name(ko), f.nameKo);
      expect(f.name(en), f.nameEn);
      expect(f.name(zh), isNot(f.nameKo));
      expect(f.name(vi), isNot(f.nameKo));
      for (final l in const [ko, en, zh, vi]) {
        expect(f.name(l).trim(), isNotEmpty);
        expect(f.name(l), isNot('—'), reason: 'never the placeholder dash');
        expect(f.name(l), isNot(contains(f.id)), reason: 'never the internal id');
      }
    });

    test('every facility is translated, bar the one brand name', () {
      // s22 is called 'L2M Platform' on its own sign in every language; the
      // translators left it, which is right. Anything else showing English
      // means a translation is missing.
      const brandNames = {'s22'};
      final untranslated = <String>{};
      for (final f in MockData.facilities) {
        for (final l in const [zh, vi]) {
          if (f.name(l) == f.nameEn) untranslated.add(f.id);
        }
      }
      expect(untranslated, brandNames,
          reason: 'facilities still showing English where Chinese or '
              'Vietnamese was expected');
    });

    test('an untranslated field falls back to English, then Korean', () {
      const plain = Facility(
        id: 'x99',
        nameKo: '한국어 이름',
        nameEn: 'English name',
        category: FacilityCategory.etc,
        lat: 0,
        lng: 0,
      );
      expect(plain.name(zh), 'English name');
      expect(plain.name(vi), 'English name');
      const koOnly = Facility(
        id: 'x98',
        nameKo: '한국어 이름',
        nameEn: '',
        category: FacilityCategory.etc,
        lat: 0,
        lng: 0,
      );
      expect(koOnly.name(zh), '한국어 이름', reason: 'never a blank line');
    });

    test('a document with no i18n serialises exactly as before', () {
      const plain = Facility(
        id: 'x99',
        nameKo: '한국어',
        nameEn: 'English',
        category: FacilityCategory.etc,
        lat: 1.5,
        lng: 2.5,
      );
      expect(plain.toJson().containsKey('i18n'), isFalse);
      final back = Facility.fromJson(plain.toJson());
      expect(back.name(zh), 'English');
      expect(back.i18n, isEmpty);
    });

    test('translations survive a round trip through JSON', () {
      final f = byId('s01');
      final back = Facility.fromJson(f.toJson());
      for (final l in const [ko, en, zh, vi]) {
        expect(back.name(l), f.name(l));
      }
    });

    test('a wrongly-shaped i18n map is ignored, not shown', () {
      final broken = Facility.fromJson(const {
        'id': 'x97',
        'name_ko': '한국어',
        'name_en': 'English',
        'category': 'etc',
        'lat': 0.0,
        'lng': 0.0,
        'i18n': {'zh': 42, 'vi': <String, Object?>{'name': 7}},
      });
      expect(broken.name(zh), 'English');
      expect(broken.name(vi), 'English');
    });

    test('search finds a facility by the name the reader is shown', () async {
      final repo = MockFacilityRepository(latency: Duration.zero);
      final f = byId('s01');
      for (final l in const [zh, vi]) {
        final shown = f.name(l);
        final part = shown.length > 4 ? shown.substring(0, 4) : shown;
        final hits = await repo.search(part);
        expect(hits.map((h) => h.id), contains('s01'),
            reason: 'typing "$part" (what ${l.languageCode} readers see) '
                'must find it');
      }
      // The Korean and English routes still work.
      expect((await repo.search(f.nameKo.substring(0, 3))).map((h) => h.id),
          contains('s01'));
    });
  });

  group('cafeterias', () {
    test('name and hours read in the chosen language, times untouched', () async {
      final menus = await MockDiningRepository().getMenus(DateTime(2026, 9, 7));
      final c = menus.first;
      expect(c.name(ko), c.nameKo);
      expect(c.name(zh), isNot(c.nameKo));
      final digits = RegExp(r'\d{2}:\d{2}');
      final koTimes = digits.allMatches(c.hours(ko) ?? '').map((m) => m[0]).toList();
      expect(koTimes, isNotEmpty);
      for (final l in const [en, zh, vi]) {
        final times = digits.allMatches(c.hours(l) ?? '').map((m) => m[0]).toList();
        expect(times, koTimes,
            reason: 'opening hours must carry the same times in '
                '${l.languageCode}, in the same order');
      }
      // Times alone would pass on a Korean sentence, so check the words too
      // (감사 05/040 NIT-4).
      expect(c.hours(ko), contains('중식'));
      expect(c.hours(en), contains('Lunch'));
      expect(c.hours(zh), contains('午餐'));
      expect(c.hours(vi)!.toLowerCase(), contains('trưa'));
    });

    test('a cafeteria round-trips, and a broken i18n map is ignored', () async {
      final menus = await MockDiningRepository().getMenus(DateTime(2026, 9, 7));
      final c = menus.first;
      final back = CafeteriaMenu.fromJson(c.toJson());
      for (final l in const [ko, en, zh, vi]) {
        expect(back.name(l), c.name(l));
        expect(back.hours(l), c.hours(l));
      }
      final broken = CafeteriaMenu.fromJson(const {
        'id': 'x',
        'name_ko': '한국어 식당',
        'name_en': 'English cafeteria',
        'campus': 'seunghak',
        'meals': <Object?>[],
        'i18n': {'zh': 42},
      });
      expect(broken.name(zh), 'English cafeteria');
      const plain = CafeteriaMenu(
        id: 'y',
        nameKo: '한국어',
        nameEn: 'English',
        campus: Campus.seunghak,
        meals: [],
      );
      expect(plain.toJson().containsKey('i18n'), isFalse);
    });

    test('closed, unpublished and open stay three different things', () async {
      // Translation must not blur the distinction the design keeps.
      final menus = await MockDiningRepository().getMenus(DateTime(2026, 9, 7));
      for (final c in menus) {
        expect(c.status, isNotNull);
      }
      expect(DiningAvailability.values,
          containsAll([DiningAvailability.open, DiningAvailability.closed,
            DiningAvailability.unpublished]));
    });
  });

  group('menu lines, rooms and floor labels are keyed by their Korean text', () {
    test('a known dish is translated, an unknown one keeps its Korean', () {
      expect(menuItemText('제육볶음', zh), isNot('제육볶음'));
      expect(menuItemText('제육볶음', vi), isNot('제육볶음'));
      // Tomorrow's menu brings a dish nobody has translated yet.
      expect(menuItemText('새로운메뉴', zh), '새로운메뉴');
      expect(menuItemText('', zh), '');
    });

    test('a changed source line does not inherit the old translation', () {
      // This is why the key is the text and not a position: if the cafeteria
      // rewrites line 2, line 2's old translation must not stick to the new
      // dish.
      const original = '제육볶음';
      const edited = '제육볶음(매운맛)';
      expect(menuItemText(original, zh), isNot(original));
      expect(menuItemText(edited, zh), edited,
          reason: 'the edited line falls back to Korean rather than showing '
              'the translation of the dish it replaced');
    });

    test('generic rooms are translated; proper nouns keep the sign text', () {
      expect(roomText('강의실', zh), isNot('강의실'));
      expect(roomText('강의실', vi), isNot('강의실'));
      expect(roomText('복도및홀', en), isNot('복도및홀'));
      // Tenant companies and named offices are not in the table on purpose.
      expect(roomText('(주)나노와', zh), '(주)나노와');
      expect(roomText('교수연구실(이상호)', vi), '교수연구실(이상호)');
      // A room that is not in this round's scope shows its Korean.
      expect(roomText('한번만나오는이상한방이름', zh), '한번만나오는이상한방이름');
    });

    test('floor labels are translated and keep their number', () {
      expect(floorLabelText('1F', zh), isNot('1F'));
      expect(floorLabelText('1F', zh), contains('1'));
      expect(floorLabelText('B2F', vi), contains('2'));
      expect(floorLabelText('1F', en), '1F');
      expect(floorLabelText('옥탑F', en), isNot('옥탑F'));
    });

    test('search forms include every written form of a room name', () {
      expect(roomSearchForms('강의실'), contains('강의실'));
      expect(roomSearchForms('강의실').length, greaterThan(1));
      // A company keeps its own name, and now keeps it in every language:
      // translating it invented a name that is on no door (조사 04/032,
      // A 02/059). So it has exactly one search form, the Korean one, and
      // that form finds it.
      expect(roomSearchForms('(주)나노와'), ['(주)나노와']);
      expect(roomSearchForms('(주)나노와').toSet().length,
          roomSearchForms('(주)나노와').length,
          reason: 'no duplicates');
    });
  });

  group('the shipped data and the seeds agree', () {
    test('facility and cafeteria seeds carry the translations', () {
      final facilities = jsonDecode(
          File('tool/firestore_seed/facilities.seed.json').readAsStringSync());
      final f = (facilities['s01'] as Map).cast<String, dynamic>();
      expect(f['i18n'], isNotNull, reason: 'the seed must carry i18n');
      expect(((f['i18n'] as Map)['zh'] as Map)['name'],
          MockData.facilities.firstWhere((x) => x.id == 's01').name(zh));

      final cafeterias = jsonDecode(
          File('tool/firestore_seed/cafeterias.seed.json').readAsStringSync());
      final c = (cafeterias['seunghak-student'] as Map).cast<String, dynamic>();
      expect(c['i18n'], isNotNull);
      expect(((c['i18n'] as Map)['vi'] as Map)['name'], isNotEmpty);
    });

    test('translation files, source and the app agree', () {
      // Editing one side only must fail here rather than ship half-translated.
      final src = jsonDecode(
          File('tool/i18n/place_source.json').readAsStringSync());
      final srcFacilities = (src['facilities'] as Map).cast<String, dynamic>();
      expect(srcFacilities.keys.toSet(),
          MockData.facilities.map((f) => f.id).toSet());

      for (final lang in const ['zh', 'vi']) {
        final doc = jsonDecode(
            File('tool/i18n/place_$lang.json').readAsStringSync());
        final names = (doc['facilities'] as Map).cast<String, dynamic>();
        for (final f in MockData.facilities) {
          expect(f.name(Locale(lang)), (names[f.id] as Map)['name'],
              reason: '${f.id}: the app and place_$lang.json disagree — '
                  'regenerate with python tool/i18n/i18n_tool.py place-gen');
        }
      }
    });

    test('every generated table matches its translation file, key for key', () {
      // Comparing one room name left 200 rooms, ~34 menu lines and 19 floor
      // labels unguarded: a translator could edit the JSON, forget
      // `place-gen`, and the app would keep showing the old text with every
      // test green (감사 05/040 SF-3).
      for (final lang in const ['en', 'zh', 'vi']) {
        final doc = jsonDecode(
            File('tool/i18n/place_$lang.json').readAsStringSync());
        final locale = Locale(lang);

        void compare(String section, Map<String, Map<String, String>> table,
            String Function(String, Locale) lookup) {
          // Only what is filled: a translation file carries a blank line for
          // every key still waiting, and the generated table holds the ones
          // that have text.
          final want = {
            for (final e in (doc[section] as Map).cast<String, dynamic>().entries)
              if (e.value.toString().trim().isNotEmpty) e.key: e.value,
          };
          expect(want.keys.where((k) => !table.containsKey(k)), isEmpty,
              reason: '$section: place_$lang.json has text the generated table '
                  'does not — run python tool/i18n/i18n_tool.py place-gen');
          // …and the other direction: a row left in the table after its key
          // was removed from the source would otherwise live on forever
          // (감사 05/042 NIT-2).
          final all = (doc[section] as Map).cast<String, dynamic>();
          expect(table.keys.where((k) => !all.containsKey(k)), isEmpty,
              reason: '$section: the generated table holds keys that '
                  'place_$lang.json no longer has');
          for (final e in want.entries) {
            expect(table[e.key]?[lang], e.value,
                reason: '$section["${e.key}"] differs from place_$lang.json');
            if (lang != 'en' || section != 'rooms') continue;
            // The English table is what search offers for a Korean-only name.
            expect(lookup(e.key, locale), isNotEmpty);
          }
        }

        compare('menu_items', menuItemI18n, menuItemText);
        compare('floor_labels', floorLabelI18n, floorLabelText);
        compare('rooms', roomNameI18n, roomText);

        // facilities and cafeterias are keyed by id, including their English
        for (final section in const ['facilities', 'cafeterias']) {
          final table = section == 'facilities' ? facilityI18n : cafeteriaI18n;
          final want = (doc[section] as Map).cast<String, dynamic>();
          for (final e in want.entries) {
            final fields = (e.value as Map).cast<String, dynamic>();
            for (final f in fields.entries) {
              expect(table[e.key]?[lang]?[f.key], f.value,
                  reason: '$section.${e.key}.${f.key} differs from '
                      'place_$lang.json');
            }
          }
        }
      }
    });

    test('ids, coordinates and phone numbers are untouched by translation', () {
      final src = jsonDecode(
          File('tool/i18n/place_source.json').readAsStringSync());
      final srcFacilities = (src['facilities'] as Map).cast<String, dynamic>();
      for (final f in MockData.facilities) {
        final row = (srcFacilities[f.id] as Map).cast<String, dynamic>();
        expect(f.nameKo, row['name_ko'], reason: '${f.id} Korean name');
        expect(f.nameEn, row['name_en'], reason: '${f.id} English name');
        expect(f.category.name, row['category'], reason: '${f.id} category');
      }
    });
  });

  test('every supported language is covered by the helpers', () {
    // If a fifth language is added, these tables have to grow with it.
    // 'Not empty' is not enough: every lookup falls back to the Korean, so an
    // empty table would pass that (감사 05/040 NIT, 05/042 NIT-3). For the
    // other languages the result has to *differ* from the Korean.
    for (final code in appLanguageCodes) {
      final l = Locale(code);
      expect(roomText('강의실', l).trim(), isNotEmpty);
      expect(menuItemText('제육볶음', l).trim(), isNotEmpty);
      expect(floorLabelText('1F', l).trim(), isNotEmpty);
      if (code == 'ko') continue;
      expect(roomText('강의실', l), isNot('강의실'), reason: '$code room');
      expect(menuItemText('제육볶음', l), isNot('제육볶음'), reason: '$code menu');
    }
  });

  group('menu translations do not invent ingredients', () {
    // 조사 04/028 caught two of mine: 불고기 became 'Bulgogi (marinated beef)'
    // and 부대찌개 'Budae jjigae (sausage stew)'. The menu line does not say
    // what is in the dish, and a student avoiding pork or beef could be misled
    // on a day the kitchen used something else.
    //
    // Each claim is paired with the Korean words that would license it.
    const claims = {
      'beef': ['소고기', '쇠고기', '우육'],
      'pork': ['돼지', '제육', '포크', '돈까스', '돈가스'],
      'sausage': ['소시지', '비엔나'],
      'chicken': ['닭', '치킨'],
      'seafood': ['해물', '해산물'],
      'shrimp': ['새우'],
      'peanut': ['땅콩'],
      'spicy': ['매운', '매콤', '고추', '김치', '제육'],
      'halal': ['할랄'],
      'vegan': ['비건'],
      'vegetarian': ['채식'],
    };

    test('English menu names claim nothing the Korean does not say', () {
      final doc = jsonDecode(File('tool/i18n/place_en.json').readAsStringSync());
      final menu = (doc['menu_items'] as Map).cast<String, dynamic>();
      final offenders = <String>[];
      menu.forEach((ko, en) {
        final text = en.toString().toLowerCase();
        claims.forEach((claim, licences) {
          if (!text.contains(claim)) return;
          if (licences.any(ko.contains)) return;
          offenders.add('$ko -> "$en" claims "$claim"');
        });
      });
      expect(offenders, isEmpty,
          reason: 'a menu line is a name, not a recipe — these add something '
              'the Korean does not say');
    });

    test('no menu name grows an explanatory clause about contents', () {
      // A gloss for a dish name is fine (Bibimbap); a parenthetical listing
      // what is inside is not.
      final doc = jsonDecode(File('tool/i18n/place_en.json').readAsStringSync());
      final menu = (doc['menu_items'] as Map).cast<String, dynamic>();
      for (final entry in menu.entries) {
        final en = entry.value.toString().toLowerCase();
        for (final word in const ['contains', 'made with', 'with meat']) {
          expect(en.contains(word), isFalse,
              reason: '${entry.key} -> "${entry.value}"');
        }
      }
    });
  });

  group('English written in the translation file reaches the English screen', () {
    // s01 had an English description in place_en.json and nowhere else: the
    // entity's descriptionEn was null, so the screen fell back to Korean and
    // the seed wrote null for every other client too.
    const english = 'Includes a main auditorium, departmental practice rooms, '
        'a cafeteria and club rooms.';

    test('the entity carries it', () {
      final f = MockData.facilities.firstWhere((x) => x.id == 's01');
      expect(f.descriptionEn, english);
      expect(f.description(en), english);
      expect(f.description(ko), isNot(english));
      expect(f.description(zh), isNot(f.descriptionKo),
          reason: 'Chinese has its own, and would otherwise show Korean');
    });

    test('the seed carries it, for every other client', () {
      final seed = jsonDecode(
          File('tool/firestore_seed/facilities.seed.json').readAsStringSync());
      expect((seed['s01'] as Map)['description_en'], english);
    });

    test('written English always wins over the translation file', () {
      const already = Facility(
        id: 's01',
        nameKo: '한국어',
        nameEn: 'Written English',
        category: FacilityCategory.building,
        lat: 0,
        lng: 0,
        descriptionEn: 'Written description',
      );
      final filled = already.withEnglish(facilityEnglish('s01'));
      expect(filled.nameEn, 'Written English');
      expect(filled.descriptionEn, 'Written description');
    });

    testWidgets('the English screen shows it', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CampusOnApp(),
      ));
      await tester.pumpAndSettle();
      AppRouter.router.go('/map/facility/s01');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.textContaining('main auditorium'), findsWidgets,
          reason: 'the English description must be on the English screen');
      expect(find.textContaining('대강당'), findsNothing,
          reason: 'and the Korean one must not be what an English reader gets');
    });
  });
}
