import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileAssociationService {
  static final FileAssociationService _instance = FileAssociationService._internal();
  factory FileAssociationService() => _instance;
  FileAssociationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<String?> getOpenFileName() async {
    return null;
  }

  Future<String> getProjectsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${appDir.path}/NovelWriter/Projects');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir.path;
  }

  Future<String> getExportsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${appDir.path}/NovelWriter/Exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir.path;
  }

  Future<String?> importProject(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final projectsDir = await getProjectsDirectory();
    final fileName = file.uri.pathSegments.last;
    final destPath = '$projectsDir/$fileName';

    await file.copy(destPath);
    return destPath;
  }
}