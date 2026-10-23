import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

int countWords(String text) {
  if (text.isEmpty) return 0;
  String plain = text;
  if (text.trim().startsWith('[') && text.trim().endsWith(']')) {
    try {
      final List<dynamic> json = jsonDecode(text);
      final sb = StringBuffer();
      for (var op in json) {
        if (op is Map && op.containsKey('insert')) {
          final insertVal = op['insert'];
          if (insertVal is String) {
            sb.write(insertVal);
          }
        }
      }
      plain = sb.toString();
    } catch (_) {}
  }
  return plain.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

void main() {
  group('Word Counter Tests', () {
    test('Empty text returns 0', () {
      expect(countWords(''), 0);
      expect(countWords('   \n\t  '), 0);
    });

    test('Counts simple plain text words correctly', () {
      expect(countWords('Hola mundo'), 2);
      expect(countWords('El veloz murciélago hindú comía feliz cardillo y kiwi.'), 9);
    });

    test('Handles multiple whitespace, tabs and newlines', () {
      expect(countWords('  Capítulo   uno:\n\nEl   comienzo   de  todo.  '), 6);
    });

    test('Parses and counts Quill Delta JSON string correctly', () {
      final deltaJson = jsonEncode([
        {'insert': 'Capítulo Primero\n'},
        {'insert': 'Era una noche oscura y tormentosa.\n', 'attributes': {'italic': true}},
      ]);
      expect(countWords(deltaJson), 8);
    });

    test('Gracefully falls back when JSON is malformed or not an array', () {
      const invalidJson = '[{invalid json}';
      expect(countWords(invalidJson), greaterThan(0));
    });
  });
}
