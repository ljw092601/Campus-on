import 'package:campus_on/data/mock/mock_data.dart';
import 'package:campus_on/domain/entities/admin_guide.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lists that are shown on screen must have the same number of lines in Korean
/// and in English, because the English length is what every other language
/// falls back to: if English is short of a line, readers of Chinese and
/// Vietnamese lose it too, while Korean readers still see it (감사 05/035 NIT-3).
///
/// `search_aliases` is deliberately excluded — it never appears on screen and
/// each language is free to carry a different number of aliases.

void main() {
  /// Every displayed ko/en list pair in a guide, labelled by where it lives.
  Map<String, (List<String>, List<String>)> pairs(AdminGuideItem g) {
    final out = <String, (List<String>, List<String>)>{
      'checklist': (g.checklistKo, g.checklistEn),
      'checklist_optional': (g.checklistOptionalKo, g.checklistOptionalEn),
      'steps': (g.stepsKo, g.stepsEn),
      'tips': (g.tipsKo, g.tipsEn),
    };
    void addSections(String label, List<GuideSection> sections) {
      for (var i = 0; i < sections.length; i++) {
        final s = sections[i];
        out['$label[$i].steps'] = (s.stepsKo, s.stepsEn);
        for (var j = 0; j < s.notes.length; j++) {
          out['$label[$i].notes[$j].lines'] =
              (s.notes[j].linesKo, s.notes[j].linesEn);
        }
      }
    }

    addSections('top_sections', g.topSections);
    addSections('sections', g.sections);
    return out;
  }

  test('every displayed list has as many lines in English as in Korean', () {
    final mismatches = <String>[];
    for (final g in MockData.guideItems) {
      pairs(g).forEach((where, lists) {
        final (ko, en) = lists;
        // An empty English list means "not translated", which falls back as a
        // whole; the problem is a list that is present but short.
        if (en.isEmpty || ko.isEmpty) return;
        if (ko.length != en.length) {
          mismatches.add('${g.id}/$where: ko ${ko.length} vs en ${en.length}');
        }
      });
    }
    expect(mismatches, isEmpty,
        reason: 'English is the fallback for Chinese and Vietnamese, so a '
            'short English list hides lines from them:\n${mismatches.join('\n')}');
  });
}
