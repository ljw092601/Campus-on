// Dumps the Korean/English source text of facilities, cafeterias and floor
// guides to tool/i18n/place_source.json, the way export_seed_test.dart dumps
// the Firestore seeds: reading the real repositories rather than a hand-kept
// copy, so a translator can never be handed a string the app does not show.
//
//   flutter test --no-pub tool/i18n/place_source_export_test.dart
//
// Room names are a long tail — 2,219 distinct names over 2,876 placements —
// so the file records every one with its placement count and marks the busiest
// ones as this round's translation scope. The rest keep their Korean, which is
// also what the building signs say.
import 'dart:convert';
import 'dart:io';

import 'package:campus_on/data/mock/building_data.g.dart';
import 'package:campus_on/data/repositories/mock_dining_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The room names this round asks for translations of: the ones
/// `tool/i18n/classify_rooms.py` calls a *kind of space*. Tenant companies,
/// named offices and brands are excluded there — their Korean is what the door
/// sign says — and anything the rules could not place is listed as unsure and
/// left alone.
const roomScopeFile = 'tool/i18n/room_classification.json';

void main() {
  test('export place source text for translation', () async {
    final facilities = <String, Map<String, dynamic>>{
      for (final f in BuildingData.facilities)
        f.id: {
          'name_ko': f.nameKo,
          'name_en': f.nameEn,
          if ((f.buildingKo ?? '').isNotEmpty) 'building_ko': f.buildingKo,
          if ((f.buildingEn ?? '').isNotEmpty) 'building_en': f.buildingEn,
          if ((f.hoursKo ?? '').isNotEmpty) 'hours_ko': f.hoursKo,
          if ((f.hoursEn ?? '').isNotEmpty) 'hours_en': f.hoursEn,
          if ((f.descriptionKo ?? '').isNotEmpty) 'description_ko': f.descriptionKo,
          if ((f.descriptionEn ?? '').isNotEmpty) 'description_en': f.descriptionEn,
          'category': f.category.name,
        },
    };

    // A weekday, so every meal slot is present.
    final menus = await MockDiningRepository().getMenus(DateTime(2026, 9, 7));
    final cafeterias = <String, Map<String, dynamic>>{
      for (final c in menus)
        c.id: {
          'name_ko': c.nameKo,
          'name_en': c.nameEn,
          if ((c.hoursKo ?? '').isNotEmpty) 'hours_ko': c.hoursKo,
          if ((c.hoursEn ?? '').isNotEmpty) 'hours_en': c.hoursEn,
        },
    };

    // Menu lines are keyed by their Korean text, not by position: the menu is
    // rewritten every day, and a translation that travelled with an index would
    // end up attached to a different dish.
    final menuItems = <String>{};
    for (final day in [
      for (var d = 0; d < 7; d++) DateTime(2026, 9, 7).add(Duration(days: d))
    ]) {
      for (final c in await MockDiningRepository().getMenus(day)) {
        for (final m in c.meals) {
          menuItems.addAll(m.items);
        }
      }
    }

    final roomCounts = <String, int>{};
    final floorLabels = <String>{};
    for (final b in BuildingData.floors) {
      for (final f in b.floors) {
        floorLabels.add(f.floor);
        for (final r in f.rooms) {
          roomCounts[r] = (roomCounts[r] ?? 0) + 1;
        }
      }
    }
    final classification = jsonDecode(File(roomScopeFile).readAsStringSync())
        as Map<String, dynamic>;
    final scopeNames = ((classification['scope_this_round']
            as Map<String, dynamic>)['names'] as Map<String, dynamic>)
        .keys
        .toSet();
    final placements = roomCounts.values.fold<int>(0, (a, b) => a + b);
    final scoped = roomCounts.entries
        .where((e) => scopeNames.contains(e.key))
        .toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    final scopedPlacements = scoped.fold<int>(0, (a, e) => a + e.value);

    final doc = <String, dynamic>{
      '_what': '시설·학식·층별 안내의 번역 원문(한국어·영어). 리드가 관리한다.',
      '_generated_by': 'flutter test --no-pub tool/i18n/place_source_export_test.dart',
      '_rules': [
        '금액·시간·전화번호·URL·좌표·시설 ID·건물 코드·호실 번호는 번역하지 않는다.',
        '메뉴·공간 이름은 한국어 원문을 키로 쓴다. 원문이 바뀌면 번역은 따라오지 않고 한국어로 표시된다.',
        '번역이 없으면 요청 언어 → 영어 → 한국어 순으로 보여 준다.',
      ],
      'facilities': facilities,
      'cafeterias': cafeterias,
      'menu_items': menuItems.toList()..sort(),
      'floor_labels': floorLabels.toList()..sort(),
      'rooms': {
        '_scope': 'generic room names (see tool/i18n/room_classification.json)',
        '_classification': (classification['totals'] as Map<String, dynamic>),
        '_distinct_total': roomCounts.length,
        '_placements_total': placements,
        '_placements_in_scope': scopedPlacements,
        'in_scope': {for (final e in scoped) e.key: e.value},
      },
    };

    File('tool/i18n/place_source.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(doc)}\n');

    expect(facilities, hasLength(48));
    expect(cafeterias, hasLength(3));
    expect(floorLabels, hasLength(19));
    expect(roomCounts.length, greaterThan(2000));
    // ignore: avoid_print
    print('facilities ${facilities.length} · cafeterias ${cafeterias.length} · '
        'menu items ${menuItems.length} · floor labels ${floorLabels.length} · '
        'rooms ${roomCounts.length} distinct / $placements placements, '
        'scope ${scoped.length} covers $scopedPlacements');
  });
}
