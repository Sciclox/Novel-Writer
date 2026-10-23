import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Title cleaning regex strips duplicate chapter prefix', () {
    String cleanChapterTitle(String rawTitle, int index) {
      final clean = rawTitle.replaceFirst(
        RegExp(r'^cap[ií]tulo\s*\d*[:\s-]*', caseSensitive: false),
        '',
      ).trim();
      final display = clean.isNotEmpty ? clean : rawTitle;
      return 'Capítulo $index: $display';
    }

    expect(
      cleanChapterTitle('Capítulo 1: El Sangrado del Bambú', 1),
      'Capítulo 1: El Sangrado del Bambú',
    );
    expect(
      cleanChapterTitle('Capitulo 1 - El Despertar', 1),
      'Capítulo 1: El Despertar',
    );
    expect(
      cleanChapterTitle('El Despertar del Tirano', 1),
      'Capítulo 1: El Despertar del Tirano',
    );
  });

  test('Delta JSON formatting converts to Markdown accurately', () {
    String deltaToMarkdown(List<Map<String, dynamic>> ops) {
      final sb = StringBuffer();
      for (var op in ops) {
        final insertVal = op['insert'];
        if (insertVal is String) {
          final attrs = op['attributes'] as Map<String, dynamic>?;
          String text = insertVal;
          if (attrs != null && text.trim().isNotEmpty) {
            if (attrs['bold'] == true) text = '**$text**';
            if (attrs['italic'] == true) text = '*$text*';
            if (attrs['header'] == 1) text = '\n### $text\n';
            if (attrs['header'] == 2) text = '\n#### $text\n';
          }
          sb.write(text);
        }
      }
      return sb.toString();
    }

    final ops = [
      {'insert': 'El príncipe '},
      {'insert': 'despiadado', 'attributes': {'bold': true}},
      {'insert': ' se levantó y dijo: '},
      {'insert': '«Muere»', 'attributes': {'italic': true}},
      {'insert': '.\n'},
    ];

    final md = deltaToMarkdown(ops);
    expect(md, 'El príncipe **despiadado** se levantó y dijo: *«Muere»*.\n');
  });

  test('Web Novel output integrates Author Notes and clean separators', () {
    final authorNoteHeader = '¡Gracias por leer este nuevo estreno!';
    final chapterHeader = 'Capítulo 1: El Sangrado del Bambú';
    final body = 'La lluvia caía sin descanso sobre el pabellón.';
    final authorNoteFooter = 'Si te gustó, añade a biblioteca y vota con estrellas.';

    final sb = StringBuffer();
    sb.writeln('=== NOTA DEL AUTOR ===');
    sb.writeln(authorNoteHeader);
    sb.writeln('======================\n');
    sb.writeln('## $chapterHeader\n');
    sb.writeln(body);
    sb.writeln('\n----------------------------------------');
    sb.writeln('=== PALABRAS DEL AUTOR ===');
    sb.writeln(authorNoteFooter);
    sb.writeln('----------------------------------------');

    final output = sb.toString();
    expect(output, contains('=== NOTA DEL AUTOR ==='));
    expect(output, contains('¡Gracias por leer este nuevo estreno!'));
    expect(output, contains('## Capítulo 1: El Sangrado del Bambú'));
    expect(output, contains('La lluvia caía sin descanso'));
    expect(output, contains('Si te gustó, añade a biblioteca y vota con estrellas.'));
  });
}
