class NarrativeTextUtils {
  static const int defaultWpm = 220;

  /// Returns estimated reading time formatted (e.g. "1 min", "45 min", "1 h 15 min")
  static String estimateReadingTime(int wordCount, {int wordsPerMinute = defaultWpm}) {
    if (wordCount <= 0) return '0 min';
    final totalMinutes = (wordCount / wordsPerMinute).ceil();
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '$hours h';
    return '$hours h $mins min';
  }

  /// Automatically replaces dialogue prefixes (`--` or starting `- `) with Spanish literary em-dash `—` and capitalizes first letter
  static String formatDialogueDashes(String text) {
    if (text.isEmpty) return text;
    String result = text.replaceAllMapped(
      RegExp(r'(^|\n)--\s*([a-záéíóúüñ]?)'),
      (m) => '${m[1]}—${m[2] != null && m[2]!.isNotEmpty ? m[2]!.toUpperCase() : ''}',
    );
    result = result.replaceAllMapped(
      RegExp(r'(^|\n)-\s+([a-záéíóúüñ]?)'),
      (m) => '${m[1]}—${m[2] != null && m[2]!.isNotEmpty ? m[2]!.toUpperCase() : ''}',
    );
    return result;
  }

  /// Stop words in Spanish to exclude from repetition analysis
  static const Set<String> _stopWordsEs = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'a', 'al', 'en', 'para',
    'por', 'con', 'sin', 'sobre', 'tras', 'entre', 'hacia', 'desde', 'hasta', 'durante', 'mediante',
    'y', 'e', 'o', 'u', 'que', 'pero', 'mas', 'sino', 'aunque', 'porque', 'pues', 'como', 'si',
    'yo', 'tu', 'ella', 'usted', 'nosotros', 'vosotros', 'ellos', 'ellas', 'ustedes',
    'mi', 'su', 'mis', 'tus', 'sus', 'nuestro', 'nuestra', 'nuestros', 'nuestras',
    'este', 'esta', 'estos', 'estas', 'ese', 'esa', 'esos', 'esas', 'aquel', 'aquella',
    'es', 'son', 'era', 'eran', 'fue', 'fueron', 'ha', 'han', 'habia', 'habian', 'ser', 'estar',
    'muy', 'tan', 'menos', 'ya', 'no', 'tambien', 'tampoco', 'donde', 'cuando', 'cual'
  };

  /// Analyzes most repeated words in text, ignoring common Spanish stop words
  static Map<String, int> analyzeWordFrequencies(
    String text, {
    int minLength = 4,
    int top = 20,
  }) {
    if (text.trim().isEmpty) return {};

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\wáéíóúüñ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= minLength && !_stopWordsEs.contains(w));

    final counts = <String, int>{};
    for (final w in words) {
      counts[w] = (counts[w] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <String, int>{};
    for (final entry in sorted.take(top)) {
      result[entry.key] = entry.value;
    }
    return result;
  }
}
