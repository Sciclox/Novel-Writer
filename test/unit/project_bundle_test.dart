import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:novel_writer/database/app_database.dart';
import 'package:novel_writer/services/project_bundle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath = r'C:\Users\Lenovo\OneDrive\Documentos\novel_writer.db';

  test('ProjectBundleService exports project 18 to bundle and verifies bundle contents', () async {
    final db = await openDatabase(dbPath, version: 20);
    AppDatabase.setDatabaseForTesting(db);

    final bytes = await ProjectBundleService.exportProjectToBundle(18);
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1000));

    // Save temporary bundle
    final tmpDir = Directory.systemTemp.createTempSync('nw_bundle_test');
    final bundleFile = File('${tmpDir.path}/test_project.nwproj');
    await bundleFile.writeAsBytes(bytes);
    expect(bundleFile.existsSync(), isTrue);

    // Test import
    final importedId = await ProjectBundleService.importProjectFromBundle(bytes);
    expect(importedId, greaterThan(0));
    expect(importedId, isNot(18));

    // Verify imported project has stats
    final stats = await AppDatabase.getProyectoStats(importedId);
    expect(stats['capitulos'], greaterThanOrEqualTo(1));
    expect(stats['personajes'], 4);
    expect(stats['lugares'], 2);
    expect(stats['eventos'], 4);

    // Clean up imported test project
    await AppDatabase.deleteProyecto(importedId);
    tmpDir.deleteSync(recursive: true);
    await db.close();
  });
}
