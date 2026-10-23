enum DiffType { insertion, deletion, unchanged }

class DiffChunk {
  final DiffType type;
  final String text;

  const DiffChunk(this.type, this.text);
}

class DiffUtils {
  /// Simple Myers/LCS-based diff between oldText and newText by words/tokens
  static List<DiffChunk> computeDiff(String oldText, String newText) {
    if (oldText == newText) {
      return [DiffChunk(DiffType.unchanged, newText)];
    }
    if (oldText.isEmpty) {
      return [DiffChunk(DiffType.insertion, newText)];
    }
    if (newText.isEmpty) {
      return [DiffChunk(DiffType.deletion, oldText)];
    }

    final oldTokens = _tokenize(oldText);
    final newTokens = _tokenize(newText);

    final lcsMatrix = List.generate(
      oldTokens.length + 1,
      (_) => List<int>.filled(newTokens.length + 1, 0),
    );

    for (int i = 1; i <= oldTokens.length; i++) {
      for (int j = 1; j <= newTokens.length; j++) {
        if (oldTokens[i - 1] == newTokens[j - 1]) {
          lcsMatrix[i][j] = lcsMatrix[i - 1][j - 1] + 1;
        } else {
          final top = lcsMatrix[i - 1][j];
          final left = lcsMatrix[i][j - 1];
          lcsMatrix[i][j] = top > left ? top : left;
        }
      }
    }

    // Backtrack to build diff chunks
    final rawChunks = <DiffChunk>[];
    int i = oldTokens.length;
    int j = newTokens.length;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && oldTokens[i - 1] == newTokens[j - 1]) {
        rawChunks.add(DiffChunk(DiffType.unchanged, oldTokens[i - 1]));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || lcsMatrix[i][j - 1] >= lcsMatrix[i - 1][j])) {
        rawChunks.add(DiffChunk(DiffType.insertion, newTokens[j - 1]));
        j--;
      } else if (i > 0 && (j == 0 || lcsMatrix[i][j - 1] < lcsMatrix[i - 1][j])) {
        rawChunks.add(DiffChunk(DiffType.deletion, oldTokens[i - 1]));
        i--;
      }
    }

    final reversed = rawChunks.reversed.toList();
    return _coalesceChunks(reversed);
  }

  static List<String> _tokenize(String text) {
    final tokens = <String>[];
    final regex = RegExp(r'(\s+|[^\s]+)');
    for (final match in regex.allMatches(text)) {
      tokens.add(match.group(0)!);
    }
    return tokens;
  }

  static List<DiffChunk> _coalesceChunks(List<DiffChunk> chunks) {
    if (chunks.isEmpty) return [];
    final result = <DiffChunk>[];
    DiffType currentType = chunks.first.type;
    final sb = StringBuffer(chunks.first.text);

    for (int i = 1; i < chunks.length; i++) {
      if (chunks[i].type == currentType) {
        sb.write(chunks[i].text);
      } else {
        result.add(DiffChunk(currentType, sb.toString()));
        currentType = chunks[i].type;
        sb.clear();
        sb.write(chunks[i].text);
      }
    }
    result.add(DiffChunk(currentType, sb.toString()));
    return result;
  }
}
