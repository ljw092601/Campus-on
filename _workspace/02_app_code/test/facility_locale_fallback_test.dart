import 'dart:ui';

import 'package:campus_on/domain/entities/facility.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facilities, cafeteria menus and floor guides have Korean and English text
/// only. Chinese and Vietnamese readers see English, then Korean — and never
/// an internal id.

Facility _f({String ko = '', String en = ''}) => Facility(
      id: 'b04',
      category: FacilityCategory.amenity,
      nameKo: ko,
      nameEn: en,
      addressKo: ko.isEmpty ? null : '부산 사하구',
      addressEn: en.isEmpty ? null : 'Saha-gu, Busan',
      lat: 0,
      lng: 0,
    );

void main() {
  const zh = Locale('zh');
  const vi = Locale('vi');

  test('Chinese and Vietnamese fall back to English', () {
    final f = _f(ko: '학생회관', en: 'Student Union');
    expect(f.name(zh), 'Student Union');
    expect(f.name(vi), 'Student Union');
    expect(f.address(zh), 'Saha-gu, Busan');
    expect(f.name(const Locale('ko')), '학생회관');
  });

  test('Korean is used when there is no English', () {
    final f = _f(ko: '학생회관');
    expect(f.name(zh), '학생회관');
    expect(f.name(vi), '학생회관');
  });

  test('an unnamed facility never shows its internal id', () {
    final f = _f();
    for (final l in const [Locale('ko'), Locale('en'), zh, vi]) {
      expect(f.name(l), isNot(contains('b04')), reason: l.languageCode);
    }
  });
}
