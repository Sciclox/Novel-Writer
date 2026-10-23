import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Update personajes and lugares with image paths', () async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Lenovo';
    final dbPath = p.join(userProfile, 'OneDrive', 'Documentos', 'novel_writer.db');
    final db = await databaseFactory.openDatabase(dbPath);

    final basePath = 'C:\\Users\\Lenovo\\OneDrive\\Documentos\\Proyectos\\Novel-Writer\\assets\\media';

    // 1. Actualizar Personajes
    final chars = await db.query('personajes', where: 'proyecto_id = ?', whereArgs: [18]);
    for (var c in chars) {
      final name = (c['nombre'] as String).toLowerCase();
      String? imagePath;
      if (name.contains('long ze')) {
        imagePath = p.join(basePath, 'long_ze.jpg');
      } else if (name.contains('kuro')) {
        imagePath = p.join(basePath, 'kuro.jpg');
      } else if (name.contains('zhao hu')) {
        imagePath = p.join(basePath, 'zhao_hu.jpg');
      } else if (name.contains('long zhen')) {
        imagePath = p.join(basePath, 'long_zhen.jpg');
      }

      if (imagePath != null && File(imagePath).existsSync()) {
        await db.update('personajes', {'imagen_path': imagePath}, where: 'id = ?', whereArgs: [c['id']]);
        print('Personaje ${c['nombre']} actualizado con imagen: $imagePath');
      }
    }

    // 2. Actualizar Lugares
    final places = await db.query('lugares', where: 'proyecto_id = ?', whereArgs: [18]);
    for (var l in places) {
      final name = (l['nombre'] as String).toLowerCase();
      String? imagePath;
      if (name.contains('bambú') || name.contains('bambu')) {
        imagePath = p.join(basePath, 'bamboo_pavilion.jpg');
      } else if (name.contains('palacio') || name.contains('dragón') || name.contains('dragon')) {
        imagePath = p.join(basePath, 'golden_palace.jpg');
      }

      if (imagePath != null && File(imagePath).existsSync()) {
        await db.update('lugares', {'imagen_path': imagePath}, where: 'id = ?', whereArgs: [l['id']]);
        print('Lugar ${l['nombre']} actualizado con imagen: $imagePath');
      }
    }

    await db.close();
  });
}
