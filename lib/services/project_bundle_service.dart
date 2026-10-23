import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../database/app_database.dart';

class ProjectBundleService {
  /// Exporta un proyecto completo con todas sus entidades a un archivo .nwproj (ZIP)
  static Future<Uint8List> exportProjectToBundle(int proyectoId) async {
    final db = await AppDatabase.database;

    // 1. Proyecto base
    final projectList = await db.query('proyectos', where: 'id = ?', whereArgs: [proyectoId]);
    if (projectList.isEmpty) {
      throw Exception('Proyecto con id $proyectoId no encontrado');
    }
    final project = Map<String, dynamic>.from(projectList.first);

    // Convertir portada_blob a base64 si existe
    String? coverBase64;
    if (project['portada_blob'] != null && project['portada_blob'] is Uint8List) {
      coverBase64 = base64Encode(project['portada_blob'] as Uint8List);
    }
    project.remove('portada_blob'); // No guardar buffer binario directamente en JSON

    // 2. Manuscrito y capítulos
    final manuscritoList = await db.query('manuscritos', where: 'proyecto_id = ?', whereArgs: [proyectoId]);
    Map<String, dynamic>? manuscrito;
    List<Map<String, dynamic>> capitulos = [];
    List<Map<String, dynamic>> versiones = [];
    List<Map<String, dynamic>> notas = [];

    if (manuscritoList.isNotEmpty) {
      manuscrito = Map<String, dynamic>.from(manuscritoList.first);
      final manId = manuscrito['id'] as int;

      final capList = await db.query('capitulos', where: 'manuscrito_id = ?', whereArgs: [manId], orderBy: 'orden ASC');
      capitulos = capList.map((c) => Map<String, dynamic>.from(c)).toList();

      final notasList = await db.query('notas', where: 'manuscrito_id = ?', whereArgs: [manId]);
      notas = notasList.map((n) => Map<String, dynamic>.from(n)).toList();

      final capIds = capitulos.map((c) => c['id'] as int).toList();
      if (capIds.isNotEmpty) {
        final versList = await db.query(
          'capitulos_versiones',
          where: 'capitulo_id IN (${capIds.join(',')})',
          orderBy: 'creado_en DESC',
        );
        versiones = versList.map((v) => Map<String, dynamic>.from(v)).toList();
      }
    }

    // 3. Personajes y relaciones
    final personajesList = await db.query('personajes', where: 'proyecto_id = ?', whereArgs: [proyectoId]);
    final personajes = personajesList.map((p) => Map<String, dynamic>.from(p)).toList();

    final pjIds = personajes.map((p) => p['id'] as int).toList();
    List<Map<String, dynamic>> relaciones = [];
    if (pjIds.isNotEmpty) {
      final relList = await db.query(
        'relaciones_personajes',
        where: 'personaje_a_id IN (${pjIds.join(',')}) OR personaje_b_id IN (${pjIds.join(',')})',
      );
      relaciones = relList.map((r) => Map<String, dynamic>.from(r)).toList();
    }

    // 4. Lugares
    final lugaresList = await db.query('lugares', where: 'proyecto_id = ?', whereArgs: [proyectoId]);
    final lugares = lugaresList.map((l) => Map<String, dynamic>.from(l)).toList();

    // 5. Línea de tiempo
    final eventosList = await db.query('eventos_timeline', where: 'proyecto_id = ?', whereArgs: [proyectoId], orderBy: 'orden ASC');
    final eventos = eventosList.map((e) => Map<String, dynamic>.from(e)).toList();

    // 6. Tarjetas de ideas y conexiones
    final tarjetasList = await db.query('tarjetas', where: 'proyecto_id = ?', whereArgs: [proyectoId]);
    final tarjetas = tarjetasList.map((t) => Map<String, dynamic>.from(t)).toList();

    final tarjIds = tarjetas.map((t) => t['id'] as int).toList();
    List<Map<String, dynamic>> conexiones = [];
    if (tarjIds.isNotEmpty) {
      final conList = await db.query(
        'tarjetas_conexiones',
        where: 'tarjeta_origen_id IN (${tarjIds.join(',')}) OR tarjeta_destino_id IN (${tarjIds.join(',')})',
      );
      conexiones = conList.map((c) => Map<String, dynamic>.from(c)).toList();
    }

    // 7. Estilos del proyecto
    final estilosList = await db.query('estilos', where: 'proyecto_id = ? AND es_global = 0', whereArgs: [proyectoId]);
    final estilos = estilosList.map((s) => Map<String, dynamic>.from(s)).toList();

    final bundleMap = {
      'version': '1.0',
      'app': 'Novel-Writer',
      'exported_at': DateTime.now().toIso8601String(),
      'project': project,
      'cover_base64': coverBase64,
      'manuscrito': manuscrito,
      'capitulos': capitulos,
      'versiones': versiones,
      'personajes': personajes,
      'relaciones': relaciones,
      'lugares': lugares,
      'eventos': eventos,
      'notas': notas,
      'tarjetas': tarjetas,
      'conexiones': conexiones,
      'estilos': estilos,
    };

    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode(bundleMap));
    archive.addFile(ArchiveFile('project.json', jsonBytes.length, jsonBytes));

    if (coverBase64 != null) {
      final coverBytes = base64Decode(coverBase64);
      archive.addFile(ArchiveFile('cover.png', coverBytes.length, coverBytes));
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// Guarda el paquete en un archivo en disco
  static Future<File> saveBundleToFile(int proyectoId, String targetPath) async {
    final bytes = await exportProjectToBundle(proyectoId);
    final file = File(targetPath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Importa un archivo .nwproj (bytes o path) y lo recrea íntegramente en la base de datos
  static Future<int> importProjectFromBundle(Uint8List bundleBytes) async {
    final archive = ZipDecoder().decodeBytes(bundleBytes);
    final jsonFile = archive.findFile('project.json');
    if (jsonFile == null) {
      throw Exception('Archivo .nwproj inválido: falta project.json');
    }

    final jsonStr = utf8.decode(jsonFile.content as List<int>);
    final Map<String, dynamic> data = jsonDecode(jsonStr);

    final db = await AppDatabase.database;

    // 1. Insertar Proyecto
    final projData = Map<String, dynamic>.from(data['project']);
    projData.remove('id'); // ID nuevo
    projData['creado_en'] = DateTime.now().toIso8601String();
    projData['actualizado_en'] = DateTime.now().toIso8601String();

    if (data['cover_base64'] != null) {
      projData['portada_blob'] = base64Decode(data['cover_base64'] as String);
    }

    final newProjectId = await db.insert('proyectos', projData);

    // 2. Insertar Manuscrito
    int? newManuscritoId;
    if (data['manuscrito'] != null) {
      final manData = Map<String, dynamic>.from(data['manuscrito']);
      manData.remove('id');
      manData['proyecto_id'] = newProjectId;
      manData['creado_en'] = DateTime.now().toIso8601String();
      manData['actualizado_en'] = DateTime.now().toIso8601String();
      newManuscritoId = await db.insert('manuscritos', manData);
    }

    // 3. Insertar Capítulos y mapeo de IDs
    final oldToNewCapId = <int, int>{};
    if (newManuscritoId != null && data['capitulos'] != null) {
      for (var rawCap in (data['capitulos'] as List)) {
        final cap = Map<String, dynamic>.from(rawCap);
        final oldId = cap['id'] as int;
        cap.remove('id');
        cap['manuscrito_id'] = newManuscritoId;
        cap['creado_en'] = DateTime.now().toIso8601String();
        cap['actualizado_en'] = DateTime.now().toIso8601String();
        final newId = await db.insert('capitulos', cap);
        oldToNewCapId[oldId] = newId;
      }
    }

    // 4. Insertar Versiones de capítulos
    if (data['versiones'] != null) {
      for (var rawVer in (data['versiones'] as List)) {
        final ver = Map<String, dynamic>.from(rawVer);
        final oldCapId = ver['capitulo_id'] as int?;
        if (oldCapId != null && oldToNewCapId.containsKey(oldCapId)) {
          ver.remove('id');
          ver['capitulo_id'] = oldToNewCapId[oldCapId]!;
          await db.insert('capitulos_versiones', ver);
        }
      }
    }

    // 5. Insertar Notas
    if (newManuscritoId != null && data['notas'] != null) {
      for (var rawNota in (data['notas'] as List)) {
        final nota = Map<String, dynamic>.from(rawNota);
        nota.remove('id');
        nota['manuscrito_id'] = newManuscritoId;
        nota['creado_en'] = DateTime.now().toIso8601String();
        await db.insert('notas', nota);
      }
    }

    // 6. Insertar Personajes y mapeo de IDs
    final oldToNewPjId = <int, int>{};
    if (data['personajes'] != null) {
      for (var rawPj in (data['personajes'] as List)) {
        final pj = Map<String, dynamic>.from(rawPj);
        final oldId = pj['id'] as int;
        pj.remove('id');
        pj['proyecto_id'] = newProjectId;
        pj['creado_en'] = DateTime.now().toIso8601String();
        pj['actualizado_en'] = DateTime.now().toIso8601String();
        final newId = await db.insert('personajes', pj);
        oldToNewPjId[oldId] = newId;
      }
    }

    // 7. Insertar Relaciones de Personajes
    if (data['relaciones'] != null) {
      for (var rawRel in (data['relaciones'] as List)) {
        final rel = Map<String, dynamic>.from(rawRel);
        final oldA = rel['personaje_a_id'] as int;
        final oldB = rel['personaje_b_id'] as int;
        if (oldToNewPjId.containsKey(oldA) && oldToNewPjId.containsKey(oldB)) {
          rel.remove('id');
          rel['personaje_a_id'] = oldToNewPjId[oldA]!;
          rel['personaje_b_id'] = oldToNewPjId[oldB]!;
          await db.insert('relaciones_personajes', rel);
        }
      }
    }

    // 8. Insertar Lugares
    if (data['lugares'] != null) {
      for (var rawLug in (data['lugares'] as List)) {
        final lug = Map<String, dynamic>.from(rawLug);
        lug.remove('id');
        lug['proyecto_id'] = newProjectId;
        lug['creado_en'] = DateTime.now().toIso8601String();
        lug['actualizado_en'] = DateTime.now().toIso8601String();
        await db.insert('lugares', lug);
      }
    }

    // 9. Insertar Eventos de Timeline
    if (data['eventos'] != null) {
      for (var rawEv in (data['eventos'] as List)) {
        final ev = Map<String, dynamic>.from(rawEv);
        ev.remove('id');
        ev['proyecto_id'] = newProjectId;
        ev['creado_en'] = DateTime.now().toIso8601String();
        ev['actualizado_en'] = DateTime.now().toIso8601String();
        await db.insert('eventos_timeline', ev);
      }
    }

    // 10. Insertar Tarjetas y Conexiones de Ideas
    final oldToNewTarjId = <int, int>{};
    if (data['tarjetas'] != null) {
      for (var rawTarj in (data['tarjetas'] as List)) {
        final tarj = Map<String, dynamic>.from(rawTarj);
        final oldId = tarj['id'] as int;
        tarj.remove('id');
        tarj['proyecto_id'] = newProjectId;
        tarj['creado_en'] = DateTime.now().toIso8601String();
        final newId = await db.insert('tarjetas', tarj);
        oldToNewTarjId[oldId] = newId;
      }
    }

    if (data['conexiones'] != null) {
      for (var rawCon in (data['conexiones'] as List)) {
        final con = Map<String, dynamic>.from(rawCon);
        final oldOrig = con['tarjeta_origen_id'] as int;
        final oldDest = con['tarjeta_destino_id'] as int;
        if (oldToNewTarjId.containsKey(oldOrig) && oldToNewTarjId.containsKey(oldDest)) {
          con.remove('id');
          con['tarjeta_origen_id'] = oldToNewTarjId[oldOrig]!;
          con['tarjeta_destino_id'] = oldToNewTarjId[oldDest]!;
          await db.insert('tarjetas_conexiones', con);
        }
      }
    }

    // 11. Estilos por defecto / del proyecto
    if (data['estilos'] != null) {
      for (var rawEstilo in (data['estilos'] as List)) {
        final estilo = Map<String, dynamic>.from(rawEstilo);
        estilo.remove('id');
        estilo['proyecto_id'] = newProjectId;
        estilo['es_global'] = 0;
        await db.insert('estilos', estilo);
      }
    } else {
      await AppDatabase.insertEstilosPorDefecto(newProjectId);
    }

    return newProjectId;
  }
}
