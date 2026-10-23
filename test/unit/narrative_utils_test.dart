import 'package:flutter_test/flutter_test.dart';
import 'package:novel_writer/utils/narrative_text_utils.dart';
import 'package:novel_writer/utils/diff_utils.dart';

void main() {
  group('NarrativeTextUtils Tests', () {
    test('estimateReadingTime calculates expected minutes', () {
      expect(NarrativeTextUtils.estimateReadingTime(0), '0 min');
      expect(NarrativeTextUtils.estimateReadingTime(100), '1 min');
      expect(NarrativeTextUtils.estimateReadingTime(220), '1 min');
      expect(NarrativeTextUtils.estimateReadingTime(1100), '5 min');
      expect(NarrativeTextUtils.estimateReadingTime(13200), '1 h');
      expect(NarrativeTextUtils.estimateReadingTime(13420), '1 h 1 min');
    });

    test('formatDialogueDashes converts leading double hyphens into em-dashes and capitalizes first letter', () {
      const input = '--hola, dijo él.\n--hola a ti también.';
      final formatted = NarrativeTextUtils.formatDialogueDashes(input);
      expect(formatted, '—Hola, dijo él.\n—Hola a ti también.');
    });

    test('analyzeWordFrequencies filters Spanish stop words and counts frequencies', () {
      const text = 'El castillo era un viejo castillo rodeado de sombras y misterio en el viejo bosque.';
      final freqs = NarrativeTextUtils.analyzeWordFrequencies(text, minLength: 4);

      expect(freqs.containsKey('castillo'), isTrue);
      expect(freqs['castillo'], 2);
      expect(freqs.containsKey('viejo'), isTrue);
      expect(freqs['viejo'], 2);
      // Stop words like 'el', 'era', 'un', 'de', 'en' should be excluded
      expect(freqs.containsKey('era'), isFalse);
      expect(freqs.containsKey('sombras'), isTrue);
    });
  });

  group('DiffUtils Tests', () {
    test('computeDiff correctly detects unchanged text', () {
      final diff = DiffUtils.computeDiff('Hola mundo', 'Hola mundo');
      expect(diff.length, 1);
      expect(diff.first.type, DiffType.unchanged);
      expect(diff.first.text, 'Hola mundo');
    });

    test('computeDiff detects additions', () {
      final diff = DiffUtils.computeDiff('Hola', 'Hola mundo');
      final additions = diff.where((c) => c.type == DiffType.insertion).toList();
      expect(additions.isNotEmpty, isTrue);
      expect(additions.any((c) => c.text.contains('mundo')), isTrue);
    });

    test('computeDiff detects deletions', () {
      final diff = DiffUtils.computeDiff('Hola valiente mundo', 'Hola mundo');
      final deletions = diff.where((c) => c.type == DiffType.deletion).toList();
      expect(deletions.isNotEmpty, isTrue);
      expect(deletions.any((c) => c.text.contains('valiente')), isTrue);
    });
  });
}
