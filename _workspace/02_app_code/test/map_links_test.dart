import 'package:campus_on/presentation/shared/map_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapFocusLink', () {
    test('targets /map with focus and a t token', () {
      final uri = Uri.parse(mapFocusLink('s04'));
      expect(uri.path, '/map');
      expect(uri.queryParameters['focus'], 's04');
      expect(uri.queryParameters['t'], isNotEmpty);
      expect(uri.queryParameters.keys, unorderedEquals(['focus', 't']));
    });

    test('consecutive links to the same building get different t tokens', () {
      final tokens = List.generate(
          50, (_) => Uri.parse(mapFocusLink('s04')).queryParameters['t']);
      expect(tokens.toSet().length, tokens.length);
      // Strictly increasing → MapScreen._focusKeyOf always changes.
      for (var i = 1; i < tokens.length; i++) {
        expect(int.parse(tokens[i]!), greaterThan(int.parse(tokens[i - 1]!)));
      }
    });

    test('includes floor, room and plan when given (classroom contract)', () {
      final link = mapFocusLink('s04',
          floor: '03', room: '0306-1', plan: 'S04', path: '/classroom-search/result');
      expect(link, startsWith('/classroom-search/result?focus=s04&floor=03&room=0306-1&plan=S04&t='));
      final q = Uri.parse(link).queryParameters;
      expect(q['floor'], '03');
      expect(q['room'], '0306-1');
      expect(q['plan'], 'S04');
      expect(q['t'], isNotEmpty);
    });

    test('omits null or empty optional parameters', () {
      final q = Uri.parse(mapFocusLink('b04', floor: '', room: null, plan: ''))
          .queryParameters;
      expect(q.containsKey('floor'), isFalse);
      expect(q.containsKey('room'), isFalse);
      expect(q.containsKey('plan'), isFalse);
      expect(q['focus'], 'b04');
    });

    test('percent-encodes reserved characters in values', () {
      final link = mapFocusLink('x&y', room: '01 A#', plan: 'p=1');
      expect(link, isNot(contains('x&y')));
      expect(link, isNot(contains(' ')));
      expect(link, isNot(contains('#')));
      final q = Uri.parse(link).queryParameters;
      expect(q['focus'], 'x&y');
      expect(q['room'], '01 A#');
      expect(q['plan'], 'p=1');
    });

    test('keeps comma-separated multi-id focus readable', () {
      final link = mapFocusLink('s15,s19');
      expect(link, startsWith('/map?focus=s15,s19&t='));
      expect(Uri.parse(link).queryParameters['focus']!.split(','),
          ['s15', 's19']);
    });
  });

  test('newMapFocusToken is unique across rapid calls', () {
    final a = newMapFocusToken();
    final b = newMapFocusToken();
    expect(a, isNot(b));
  });

  group('withMapFocusToken', () {
    test('appends t to a seeded /map?focus link without one', () {
      final out = withMapFocusToken('/map?focus=s15,s19');
      expect(out, startsWith('/map?focus=s15,s19&t='));
      expect(withMapFocusToken('/map?focus=b04'),
          isNot(equals(withMapFocusToken('/map?focus=b04'))));
    });

    test('leaves non-map and already-tokened links untouched', () {
      expect(withMapFocusToken('/home/guide/visa'), '/home/guide/visa');
      expect(withMapFocusToken('/map'), '/map');
      expect(withMapFocusToken('/map?focus=s01&t=1'), '/map?focus=s01&t=1');
      expect(withMapFocusToken('https://x.y/map?focus=s01'),
          'https://x.y/map?focus=s01');
    });
  });
}
