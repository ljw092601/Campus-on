import 'dart:ui';

import 'app_languages.dart';

/// Per-language text for an entity whose Korean and English are written as
/// plain fields: language code → field key → String or List&lt;String&gt;.
///
/// Chinese and Vietnamese arrive this way — from a generated mock overlay, or
/// from the `i18n` map on a Firestore document — so the Korean and English
/// literals stay exactly as they were written, and a document that predates
/// translation keeps working untouched.
typedef EntityI18n = Map<String, Map<String, Object?>>;

const EntityI18n noI18n = {};

/// Parses the `i18n` map of a Firestore document (or a mock overlay).
///
/// Every shape that is not what we expect is ignored rather than thrown on: a
/// single hand-edited document (`i18n: 42`, or a language holding a string
/// instead of a map) used to raise a TypeError, and since the repositories only
/// catch FirebaseException that one document could take down a whole collection
/// — the guide list, its categories and search (B 03/054 B-01).
EntityI18n entityI18nFromJson(dynamic v) {
  if (v is! Map) return noI18n;
  final m = v.cast<String, dynamic>();
  if (m.isEmpty) return noI18n;
  final out = <String, Map<String, Object?>>{};
  for (final e in m.entries) {
    if (!isSupportedLanguage(e.key) || e.key == 'ko' || e.key == 'en') continue;
    if (e.value is! Map) continue;
    final fields = (e.value as Map).cast<String, dynamic>();
    final kept = <String, Object?>{};
    for (final f in fields.entries) {
      final val = f.value;
      if (val is String) {
        kept[f.key] = val;
      } else if (val is List && val.every((x) => x is String)) {
        kept[f.key] = val.cast<String>();
      }
      // Anything else (a number, a nested map, a list with a map in it) comes
      // from a hand-edited or out-of-date document. Dropping the field falls
      // back to English/Korean instead of printing `{a: 1}` on screen
      // (감사 05/034 S-6).
    }
    if (kept.isNotEmpty) out[e.key] = kept;
  }
  return out.isEmpty ? noI18n : out;
}

/// Text for [l], falling back requested language → English → Korean, so an
/// untranslated field shows the English (or Korean) sentence rather than a
/// blank line.
String pickI18nText(String ko, String en, Locale l,
    [EntityI18n i18n = noI18n, String? key]) {
  for (final code in languageFallback(l.languageCode)) {
    final String s;
    switch (code) {
      case 'ko':
        s = ko;
      case 'en':
        s = en;
      default:
        s = key == null ? '' : (i18n[code]?[key] as String? ?? '');
    }
    if (s.trim().isNotEmpty) return s;
  }
  return '';
}

/// Serialises an [EntityI18n] back out, dropping it entirely when empty so a
/// document that has no translations looks exactly as it did before this field
/// existed.
Map<String, dynamic>? entityI18nToJson(EntityI18n i18n) {
  if (i18n.isEmpty) return null;
  final out = <String, dynamic>{};
  for (final e in i18n.entries) {
    // Same filter as the parser: a map built in memory with a `ko` key (or a
    // language we do not ship) must not serialise into something that reads
    // back differently (B 03/063 N-01).
    if (!isSupportedLanguage(e.key) || e.key == 'ko' || e.key == 'en') continue;
    final fields = <String, dynamic>{};
    for (final f in e.value.entries) {
      final v = f.value;
      if (v is String && v.trim().isNotEmpty) {
        fields[f.key] = v;
      } else if (v is List<String> && v.isNotEmpty) {
        fields[f.key] = v;
      }
    }
    if (fields.isNotEmpty) out[e.key] = fields;
  }
  return out.isEmpty ? null : out;
}
