import 'dart:ui';

import '../../core/i18n/app_languages.dart';
import '../../core/i18n/entity_i18n.dart';
import 'place_translations.g.dart';

/// Translations for the places data — facilities, cafeterias, floor guides.
///
/// Two shapes, for two kinds of data:
///
/// * **Keyed by id** (facilities, cafeterias). These are documents with stable
///   ids, so their translations ride along in the `i18n` map on the entity,
///   exactly like the guides and the academic calendar. The generated table
///   here is what the mock repository lays over its Korean/English data.
/// * **Keyed by the Korean text** (menu lines, room names, floor labels). These
///   have no id: a cafeteria rewrites its menu every day, and a room name is a
///   string inside a building document. A translation attached by position
///   would end up on a different dish the next morning; attached to the text
///   itself, it simply stops matching when the text changes, and the Korean
///   shows — which is also what the door sign and the menu board say.
///
/// Everything falls back requested language → English → Korean, so an
/// untranslated line never becomes blank and never shows an internal key.

/// The `i18n` overlay for one facility, or none.
EntityI18n facilityOverlay(String id) => facilityI18n[id] ?? noI18n;

/// The `i18n` overlay for one cafeteria, or none.
EntityI18n cafeteriaOverlay(String id) => cafeteriaI18n[id] ?? noI18n;

/// The English written for [id] in the translation file, for the fields the
/// entity stores as plain English. Empty when there is none.
Map<String, Object?> facilityEnglish(String id) =>
    facilityI18n[id]?['en'] ?? const {};

Map<String, Object?> cafeteriaEnglish(String id) =>
    cafeteriaI18n[id]?['en'] ?? const {};

String _keyed(Map<String, Map<String, String>> table, String ko, Locale l) {
  final source = ko.trim();
  if (source.isEmpty) return ko;
  final row = table[source];
  if (row == null) return ko;
  for (final code in languageFallback(l.languageCode)) {
    if (code == 'ko') break;
    final v = row[code];
    if (v != null && v.trim().isNotEmpty) return v;
  }
  return ko;
}

/// One menu line ("제육볶음") in [l].
///
/// Only the name is translated. Nothing here infers ingredients, allergens or
/// whether a dish is halal — a menu line is a name, not a recipe, and guessing
/// would be worse than showing the Korean.
String menuItemText(String ko, Locale l) => _keyed(menuItemI18n, ko, l);

/// A room name that identifies a particular tenant or person rather than a
/// kind of space: `(주)…` companies, `(사)`/`(재)` bodies, and offices named
/// after the professor who sits in them.
bool isProperRoomName(String ko) =>
    ko.contains('(주)') ||
    ko.contains('(사)') ||
    ko.contains('(재)') ||
    // Any office named after the person in it, however the label is prefixed:
    // 교수연구실(이상호), 교원연구실(하태영), LINC+사업단 부단장실/교수연구실(김우생)
    // (감사 05/040 NIT-2).
    RegExp(r'연구실\([^)]*[가-힣][^)]*\)\s*$').hasMatch(ko.trim());

/// One room name from the floor guide in [l].
///
/// A student standing in a corridor is matching what the app says against a
/// Korean door sign, so names that identify a tenant or a person keep their
/// Korean whatever the reader's language — a translated company name cannot be
/// found on any door. Kinds of space (lecture room, corridor, storage) do get
/// translated: nobody looks for those by their letters.
///
/// Search is separate: [roomSearchForms] carries every language, and the
/// classroom screen matches against it, so a company shown in Korean is still
/// found by its Vietnamese name.
String roomText(String ko, Locale l) {
  // Only names this round actually asked for are shown translated. The table
  // also carries rows that are out of scope — kept so search can match them —
  // and those must not reach the screen: the door still says the Korean
  // (감사 05/042 SF-2).
  if (!roomNamesInScope.contains(ko.trim())) return ko;
  if (!isProperRoomName(ko)) return _keyed(roomNameI18n, ko, l);

  // A name that identifies a person or a tenant: the translation is only an
  // improvement if it still carries that name as the door sign spells it.
  // `教授研究室(이승훈)` does — the kind of room is translated and the person is
  // left alone — so it is better than bare Korean (감사 05/040 NIT-1).
  // `Phòng nghiên cứu GS Lee Sang-ho` does not: nobody can match that against
  // a sign reading 교수연구실(이상호), so the Korean stays.
  final candidate = _keyed(roomNameI18n, ko, l);
  final proper = RegExp(r'\(([^)]*[가-힣][^)]*)\)').firstMatch(ko.trim());
  if (proper != null && candidate.contains(proper.group(1)!)) return candidate;
  return ko;
}

/// A floor label ("B1F", "옥탑F") in [l].
String floorLabelText(String ko, Locale l) => _keyed(floorLabelI18n, ko, l);

/// Every written form of a room name — used by search, so that typing either
/// the Korean on the sign or the name the app is showing finds the room.
///
/// This is where the out-of-scope rows earn their keep: a tenant's name shows
/// in Korean but is still findable in the reader's own language.
List<String> roomSearchForms(String ko) {
  final row = roomNameI18n[ko.trim()];
  return <String>{ko, if (row != null) ...row.values}.toList();
}
