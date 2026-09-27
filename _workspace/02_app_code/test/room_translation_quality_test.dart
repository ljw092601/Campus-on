import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A filled cell is not automatically a translation.
///
/// 조사 04/030 caught the first shape: 730 Vietnamese room names that were
/// still the Korean, counted as done because the cell was not empty. Two more
/// shapes surfaced on 2026-09-27, both in Vietnamese room names:
///
///   glued     a substring replacement ran over the Korean instead of
///             translating it, leaving the scripts stuck together:
///             `건설tòa nhà리phòng trưởng trụ sở`
///   respaced  the same Korean with the spaces moved: `A/B` → `A / B`
///
/// Both read as gibberish on the floor guide, and both passed every check we
/// had. This is the check that fails on them.
///
/// Korean inside brackets is a different thing and stays: `Club room (또소리)`
/// keeps the club's own name, which is what the door says.
final _glued = RegExp(r'(?<=[가-힣])[A-Za-zÀ-ỹ]|[A-Za-zÀ-ỹ](?=[가-힣])');

String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '');

/// Korean words that name a kind of space. These are the part a translation is
/// for, so finding one inside a translated value means the translation stopped
/// halfway. Names — of shops, sponsors, nursery classes, people — are not here
/// and are allowed to stay.
const _spaceWords = [
  '강의실', '실습실', '세미나실', '회의실', '휴게실', '연구실', '실험실', '창고',
  '복도', '전기실', '기계실', '보일러실', '펌프실', '화장실', '탈의실', '주방',
  '식당', '매점', '자료실', '열람실', '사무실', '행정실', '경비실', '방송실',
  '준비실', '대기실', '숙직실', '탕비실', '세탁실', '전산실', '서버실', '통신실',
  '전시실', '상담실', '인쇄실', '복사점', '학생회실', '교육실', '지원실',
];

/// Rooms that carry someone's name, which no language may translate away.
///
/// `isProperRoomName` only recognises `연구실(이름)`, so a lab written
/// `…실험실(이름)` — or with the name in Latin letters — is classified as an
/// ordinary space and goes to the translators (감사 05/042 NIT-6, 05/044
/// NIT-5). Widening the rule is the riskier fix: brackets in this data hold
/// `(VR)`, `(Core)`, `(T.O.N)` and other non-names, and pulling those out of
/// scope would leave real rooms in Korean. So the names are pinned here
/// instead: translate one away and this fails.
const _personRooms = [
  '분자약리학실험실(이상민)',
  '생리학실험실2(손민국)',
  '식품분석실험실(이준구)',
  '식품효소공학실험실(황이택)',
  '컴퓨터그래픽스실험실(박영진)',
  '플라즈마실험실(정태훈)',
  '플라즈마 O.E.S실험실(정태훈)',
  '에너지재료 연구실/교수연구실(Maulana Achmad Yanuar)',
];

/// An English word left standing in a Vietnamese room name.
///
/// The mass substitution that damaged the Vietnamese room names replaced Korean
/// words one at a time, and where it had no Vietnamese word it left the English
/// one: `Phòng tiên tiến vật liệu physics`, `Phòng Concrete structures thí
/// nghiệm chuẩn bị`, `Phòng họp phòng/judges`, `Văn phòng Mỹ thuật/crafts
/// khoa`. 61 values were still in that state on 2026-09-27, and every check we
/// had passed them: the value has no Korean in it, it is not the key respaced,
/// and it is not empty. This is the check that fails on them.
///
/// The words are listed rather than detected, because Vietnamese writes plenty
/// of ASCII: `sinh`, `khoa`, `trung`, `thao` are Vietnamese, and `judo`,
/// `nano`, `laser`, `plasma`, `virus`, `polyme` are loanwords it uses.
const _englishWords = [
  'learning', 'module', 'communication', 'crafts', 'aging', 'regulatory',
  'first', 'newborn', 'sorting', 'clerk', 'prosecutor', 'prep', 'dance',
  'physics', 'catalytic', 'neural', 'translational', 'evaluation', 'property',
  'welding', 'casting', 'machining', 'chemicals', 'retrieval', 'evolution',
  'literacy', 'psychiatric', 'seed', 'handling', 'intro', 'microwave',
  'capacitor', 'concrete', 'structures', 'quality', 'editorial', 'sociology',
  'circulation', 'desk', 'process', 'coastal', 'public', 'judges', 'instrument',
  'book', 'gallery', 'fluid', 'track', 'linear', 'device', 'delivery', 'media',
  'machine', 'room', 'hall', 'safety', 'central', 'government', 'capital',
  'provisional', 'character', 'internet', 'studio', 'debriefing', 'space',
  'make', 'smart', 'design', 'thinking', 'core', 'health', 'care', 'groupware',
  'tank', 'pump', 'inner', 'certification', 'conversion', 'electronics',
  'biomedical', 'laboratory', 'preparation', 'bio',
];

/// Loanwords Vietnamese does use, written the English way.
const _viLoanWords = {'groupware', 'internet', 'studio', 'learning'};

/// Rooms whose own name is English — the sign on the door is `STUDY ROOM`,
/// `Inspire Hall`, `Debriefing Room`. Translating those would be the error, so
/// the English in them is allowed and each one is written down here.
const _englishNamedRooms = {
  'BJ Instrument',
  'BOOK GALLERY',
  'Design Thinking Room',
  'Make space실',
  'Media for machine 연구실-서정일',
  'N-care 플랫폼',
  'SMART POWER 설계실',
  'STUDY ROOM 복도',
  'STUDY ROOM1~6',
  '里仁홀(LEEIN HALL)',
  '대학인문역량강화사업(CORE)블랙형창의인문드림센터/세미나실',
  '동아리방(Core)',
  '바이오-헬스 특성화실습실1/Smart Health-care Lab',
  '바이오-헬스 특성화실습준비실1/Smart Health-care Lab',
  '스마트강의실(Inspire Hall)',
  '의학시뮬레이션센터(Debriefing Room)',
};

final _latinWord = RegExp(r'[A-Za-zÀ-ỹĐđ]+');

/// A Latin name written on the door, translated away.
///
/// `STUDY ROOM1~6` came back as `Phòng tự học 1~6` and
/// `…/Smart Health-care Lab` as `…/thông minh sức khỏe-chăm sóc`: the room is
/// findable by the sign in every other language, and in Vietnamese the sign
/// was gone (A 02/068 §5). The rule is the mirror of the kept-Korean one — a
/// Latin word the key carries has to survive into the value.
///
/// Two places expand or shorten the name instead of dropping it, which is not
/// the same defect, so each is written down with its reason.
const _latinNameKept = {
  '차세대LSI LAB': 'LAB', // `Phòng thí nghiệm … LSI`: LAB became the local word
  'AI/MLSW실습실': 'MLSW', // spelled out as `ML software` / `ML软件`
};

final _latinName = RegExp(r'[A-Za-z]{3,}');

/// One Korean word swapped for a different organisation.
///
/// 학회실 is the room of a department's academic society; 학생회실 is the room
/// of the student council. They are different rooms and this data holds both —
/// and Chinese and Vietnamese put the student council's name on thirteen of the
/// society rooms, so `전자공학과학회실` and `전자공학과학생회실` came out with
/// the same name (감사 05/051). English had all fifteen right, which is why
/// English is the reference the other two are read against.
///
/// Every check we had passed these values: the word order is fine, nothing is
/// glued, nothing is left in Korean. Only the choice of word is wrong.
const _studentCouncil = {'zh': '学生会', 'vi': 'hội sinh viên'};

/// Rooms that really are the student council's, written without the word
/// 학생회 in the key.
const _studentCouncilRooms = {'학생자치회/DALS 편집실'};

/// Compound names Vietnamese reversed, taken from the sweep that found them
/// (조사 04/037). `hải quân kiến trúc` reads as navy architecture and
/// `đại dương thực vật` as ocean plants: the words are right and the order
/// makes them a different thing.
/// Matched with the tone marks removed, so `Đất môi trường` cannot come back
/// as `Dat moi truong`.
const _reversedCompounds = [
  'Quốc tế du lịch', 'Quốc tế thương mại', 'Công nghiệp thiết kế',
  'Thời trang thiết kế', 'Pháp văn hóa', 'Nhật Bản nghiên cứu',
  'Trung Quốc nghiên cứu', 'Trẻ em nghiên cứu', 'đời sống khoa học',
  'hải quân kiến trúc', 'đại dương thực vật', 'Khí quyển môi trường',
  'Đất môi trường', 'Tiên tiến vật liệu', 'Hữu cơ vật liệu',
  'năng lượng hệ thống', 'Chức năng vật liệu', 'Năng lượng vật liệu',
  'năng lượng kỹ thuật', 'quy trình vật liệu', 'điện tử vật liệu',
  'phức hợp hệ thống', 'nhúng hệ thống', 'Địa chấn kết cấu',
  'giảng dạy vật liệu', 'thiết bị phân tích',
];

/// Tone marks off, đ folded, lower case — the shape the rule compares.
String _fold(String s) {
  const marked = 'àáâãèéêìíòóôõùúýăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ';
  const plain = 'aaaaeeeiioooouuyadiuouaaaaaaaaaaaaaeeeeeeeeiiooooooooooooouuuuuuuuyyyy';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = marked.indexOf(ch);
    b.write(i < 0 ? ch : plain[i]);
  }
  return b.toString();
}

/// `A실/B실` is two rooms, and the Vietnamese has to name both.
///
/// The word-by-word substitution put one `Phòng` before the slash and left the
/// other half bare: `Phòng điện phòng/cơ sở vật chất`, `Phòng học Chunchugwan/
/// lớn`. Each half read alone is not a room (감사 05/052 §1-B). A closed list of
/// phrases kept missing these — this looks at the shape instead.
final _placeHead = RegExp(
    r'^(Văn phòng|Phòng|Sảnh|Kho|Xưởng|Nhà ăn|Nhà|Thư viện|Trung tâm|Viện|'
    r'Khoa|Ban|Bộ phận|Bếp|Hội trường|Quán|Cửa hàng|Giảng đường|Nền tảng|'
    r'Khu|Studio|STUDY|Design|BJ|BOOK|Make)\b',
    caseSensitive: false);

/// Korean suffixes that mark a half as naming a room of its own.
const _roomSuffix = ['실', '관', '센터', '연구소', '사무국', '주방', '본부'];

/// Keys where the two Korean halves are two names for one room, so Vietnamese
/// writes it once. English does the same.
const _twoRoomKeys = {
  '한국어문학과사무실/국어국문학과사무실',
  '한국어문학과학회실/국어국문학과학회실',
};

void main() {
  for (final lang in const ['en', 'zh', 'vi']) {
    final doc = jsonDecode(
        File('tool/i18n/place_$lang.json').readAsStringSync()) as Map;

    for (final section in const ['rooms', 'menu_items', 'floor_labels']) {
      final rows = (doc[section] as Map?)?.cast<String, dynamic>() ?? {};

      test('$lang $section: no Korean glued to Latin letters', () {
        final bad = <String>[];
        rows.forEach((ko, value) {
          final v = (value as String? ?? '').trim();
          // A kept sign name carries whatever the door carries, including
          // Korean next to Latin: `(주)대성FNT` is the company's own name.
          if (v.isEmpty || v == ko.trim()) return;
          if (_glued.hasMatch(v)) bad.add('$ko → $v');
        });
        expect(bad, isEmpty,
            reason: '${bad.length} value(s) have Korean and Latin stuck '
                'together — a replacement ran over the Korean instead of '
                'translating it');
      });

      test('$lang $section: no value that only respaces the Korean', () {
        final bad = <String>[];
        rows.forEach((ko, value) {
          final v = (value as String? ?? '').trim();
          if (v.isEmpty || v == ko.trim()) return; // honestly untranslated
          if (_squash(v) == _squash(ko)) bad.add('$ko → $v');
        });
        expect(bad, isEmpty,
            reason: '${bad.length} value(s) are the same Korean with the '
                'spacing changed, which the scope table would count as work');
      });
    }

    test('$lang rooms: the name on a person-named door survives', () {
      final rows = (doc['rooms'] as Map).cast<String, dynamic>();
      for (final ko in _personRooms) {
        final person = RegExp(r'\(([^)]+)\)\s*$').firstMatch(ko)!.group(1)!;
        final value = (rows[ko] as String? ?? '').trim();
        expect(value, isNotEmpty, reason: '$ko has no $lang value at all');
        expect(value, contains(person),
            reason: '$ko lost the name「$person」in $lang');
      }
    });

    // Korean left inside a value that is supposed to be a translation. The
    // glued-scripts rule above only sees Korean touching Latin letters, so
    // `건설楼管理室` or `Phòng 국제교류실` would walk straight through it
    // (B 03/078 SF-03).
    //
    // Not all Korean in a value is wrong: a shop, a sponsor, a nursery class
    // or a person keeps its own name in every language — `다우媒体中心`,
    // `Lớp 도담 (phòng giữ trẻ)`, `…-김현석`. What may never survive is a word
    // naming the *kind* of space, because that is the part being translated.
    test('$lang rooms: no untranslated space word left in a value', () {
      final rows = (doc['rooms'] as Map).cast<String, dynamic>();
      final bad = <String>[];
      rows.forEach((ko, value) {
        final v = (value as String? ?? '').trim();
        if (v.isEmpty || v == ko.trim()) return;
        for (final word in _spaceWords) {
          if (v.contains(word)) bad.add('$ko → $v (「$word」)');
        }
      });
      expect(bad, isEmpty,
          reason: '${bad.length} $lang value(s) still name the kind of space '
              'in Korean');
    });

    // Same rule, but for every room the classifier calls a kept name rather
    // than a hand-listed few: if a value was written at all, the Korean name
    // in brackets has to survive it. Rooms with no value are fine — the screen
    // shows the Korean, which is the point.
    if (_studentCouncil.containsKey(lang)) {
      test('$lang rooms: the student council does not take over another room',
          () {
        final rows = (doc['rooms'] as Map).cast<String, dynamic>();
        final word = _studentCouncil[lang]!;
        final bad = <String>[];
        rows.forEach((ko, value) {
          final v = (value as String? ?? '').trim();
          if (v.isEmpty || v == ko.trim()) return;
          if (ko.contains('학생회') || _studentCouncilRooms.contains(ko)) return;
          if (v.contains(word)) bad.add('$ko → $v');
        });
        expect(bad, isEmpty,
            reason: '${bad.length} $lang value(s) name the student council for '
                'a room whose Korean does not; 학회 is an academic society');
      });
    }

    test('$lang rooms: a Latin name on the door survives', () {
      final rows = (doc['rooms'] as Map).cast<String, dynamic>();
      final bad = <String>[];
      rows.forEach((ko, value) {
        final v = (value as String? ?? '').trim();
        if (v.isEmpty || v == ko.trim()) return;
        final lower = v.toLowerCase();
        for (final m in _latinName.allMatches(ko)) {
          final word = m.group(0)!;
          if (_latinNameKept[ko] == word) continue;
          if (!lower.contains(word.toLowerCase())) bad.add('$ko → $v (「$word」)');
        }
      });
      expect(bad, isEmpty,
          reason: '${bad.length} $lang value(s) dropped a Latin name the key '
              'carries; the sign on the door is what people look for');
    });

    test('$lang rooms: a kept name keeps its Korean in brackets', () {
      final classification = jsonDecode(
          File('tool/i18n/room_classification.json').readAsStringSync()) as Map;
      final kept = (classification['proper'] as Map).keys.cast<String>();
      final rows = (doc['rooms'] as Map).cast<String, dynamic>();
      final bracket = RegExp(r'\(([^)]*[가-힣][^)]*)\)');
      final bad = <String>[];
      for (final ko in kept) {
        final inner = bracket.firstMatch(ko)?.group(1);
        if (inner == null) continue;
        final value = (rows[ko] as String? ?? '').trim();
        if (value.isEmpty || value == ko.trim()) continue;
        if (!value.contains(inner)) bad.add('$ko → $value');
      }
      expect(bad, isEmpty,
          reason: '${bad.length} kept name(s) lost the Korean the door '
              'carries; either keep it or leave the room untranslated');
    });
  }

  test('vi rooms: no English word left standing in a Vietnamese value', () {
    final doc = jsonDecode(
        File('tool/i18n/place_vi.json').readAsStringSync()) as Map;
    final rows = (doc['rooms'] as Map).cast<String, dynamic>();
    final deny = _englishWords.toSet()..removeAll(_viLoanWords);
    final bad = <String>[];
    rows.forEach((ko, value) {
      final v = (value as String? ?? '').trim();
      if (v.isEmpty || v == ko.trim()) return;
      if (_englishNamedRooms.contains(ko)) return;
      final left = _latinWord
          .allMatches(v)
          .map((m) => m.group(0)!.toLowerCase())
          .where(deny.contains)
          .toSet();
      if (left.isNotEmpty) bad.add('$ko → $v (${left.join(", ")})');
    });
    expect(bad, isEmpty,
        reason: '${bad.length} Vietnamese value(s) still carry an English '
            'word the substitution left behind');
  });

  test('vi rooms: no compound name left in the Korean order', () {
    final doc = jsonDecode(
        File('tool/i18n/place_vi.json').readAsStringSync()) as Map;
    final rows = (doc['rooms'] as Map).cast<String, dynamic>();
    final bad = <String>[];
    rows.forEach((ko, value) {
      final v = (value as String? ?? '').trim();
      if (v.isEmpty || v == ko.trim()) return;
      for (final phrase in _reversedCompounds) {
        if (_fold(v).contains(_fold(phrase))) {
          bad.add('$ko → $v (「$phrase」)');
        }
      }
    });
    expect(bad, isEmpty,
        reason: '${bad.length} Vietnamese value(s) keep a compound name in the '
            'Korean word order, which names something else');
  });

  test('vi rooms: a department office is not written 「… khoa」', () {
    final doc = jsonDecode(
        File('tool/i18n/place_vi.json').readAsStringSync()) as Map;
    final rows = (doc['rooms'] as Map).cast<String, dynamic>();
    final trailing = RegExp(r'\bkhoa$');
    final bad = <String>[];
    rows.forEach((ko, value) {
      final v = (value as String? ?? '').trim();
      if (v.isEmpty || v == ko.trim()) return;
      if (!ko.endsWith('학과사무실')) return;
      if (trailing.hasMatch(v)) bad.add('$ko → $v');
    });
    expect(bad, isEmpty,
        reason: '${bad.length} value(s) leave 「khoa」 stranded at the end; '
            'Vietnamese writes `Văn phòng Khoa <name>`');
  });

  test('vi rooms: both halves of an 「A실/B실」 key name a room', () {
    final doc = jsonDecode(
        File('tool/i18n/place_vi.json').readAsStringSync()) as Map;
    final rows = (doc['rooms'] as Map).cast<String, dynamic>();
    final bad = <String>[];
    rows.forEach((ko, value) {
      final v = (value as String? ?? '').trim();
      if (v.isEmpty || v == ko.trim()) return;
      if (_twoRoomKeys.contains(ko)) return;
      final halves = ko.split('/');
      if (halves.length != 2) return;
      if (!halves.every((h) => _roomSuffix.any(h.trim().endsWith))) return;
      final vHalves = v.split('/').map((x) => x.trim()).toList();
      if (vHalves.length != 2 || !vHalves.every(_placeHead.hasMatch)) {
        bad.add('$ko → $v');
      }
    });
    expect(bad, isEmpty,
        reason: '${bad.length} value(s) split one room word across the slash, '
            'leaving a half that is not a room');
  });
}
