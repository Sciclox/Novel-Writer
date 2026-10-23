import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:novel_writer/database/app_database.dart';
import 'package:novel_writer/utils/narrative_text_utils.dart';
import 'package:novel_writer/utils/diff_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath = r'C:\Users\Lenovo\OneDrive\Documentos\novel_writer.db';

  group('Web Novel Creation & App Tool Verification', () {
    test('Create Project, Characters, Places, Timeline, Ideas, Notes and Chapter 1 in Real DB', () async {
      final db = await openDatabase(dbPath, version: 20);
      AppDatabase.setDatabaseForTesting(db);

      // 1. Crear o recuperar el Proyecto de Novela Web
      final existingProjects = await db.query(
        'proyectos',
        where: 'titulo LIKE ?',
        whereArgs: ['%El Décimo Príncipe%'],
      );

      int projectId;
      if (existingProjects.isNotEmpty) {
        projectId = existingProjects.first['id'] as int;
        print('Proyecto existente encontrado: ID $projectId');
        // Limpiar datos antiguos para regenerar la novela de prueba de forma prístina
        await db.delete('personajes', where: 'proyecto_id = ?', whereArgs: [projectId]);
        await db.delete('lugares', where: 'proyecto_id = ?', whereArgs: [projectId]);
        await db.delete('eventos_timeline', where: 'proyecto_id = ?', whereArgs: [projectId]);
        await db.delete('tarjetas', where: 'proyecto_id = ?', whereArgs: [projectId]);
        
        final manuscrito = await db.query('manuscritos', where: 'proyecto_id = ?', whereArgs: [projectId]);
        if (manuscrito.isNotEmpty) {
          final manId = manuscrito.first['id'] as int;
          await db.delete('capitulos', where: 'manuscrito_id = ?', whereArgs: [manId]);
          await db.delete('notas', where: 'manuscrito_id = ?', whereArgs: [manId]);
        }
      } else {
        projectId = await db.insert('proyectos', {
          'titulo': 'El Décimo Príncipe Ya No Es Cobarde',
          'sinopsis': 'En la Gran Dinastía Tianlong, el Décimo Príncipe Long Ze era el hazmerreír de la corte: débil, enfermizo y despreciado. Una noche de tormenta, un escuadrón de asesinos asalta su desolado pabellón. A punto de ser degollado, el terror lo hace colapsar... pero al despertar, el alma que abre los ojos es la de un Soberano Tirano milenario. El cordero ha muerto. El carnicero ha despertado.',
          'creado_en': DateTime.now().toIso8601String(),
          'actualizado_en': DateTime.now().toIso8601String(),
        });
        print('Nuevo proyecto creado con ID: $projectId');
      }

      // Asegurar que existe Manuscrito
      int manuscritoId;
      final manQuery = await db.query('manuscritos', where: 'proyecto_id = ?', whereArgs: [projectId]);
      if (manQuery.isEmpty) {
        manuscritoId = await db.insert('manuscritos', {
          'proyecto_id': projectId,
          'contenido': '',
          'color_fondo': '#FFFFFF',
          'fuente': 'Merriweather',
          'font_size': 18.0,
          'line_height': 1.8,
          'creado_en': DateTime.now().toIso8601String(),
          'actualizado_en': DateTime.now().toIso8601String(),
        });
      } else {
        manuscritoId = manQuery.first['id'] as int;
      }

      // 2. CREACIÓN DEL CODEX DE PERSONAJES (Tool: CharactersView & Codex)
      final princeId = await db.insert('personajes', {
        'proyecto_id': projectId,
        'nombre': 'Long Ze (Décimo Príncipe)',
        'rol': 'Protagonista',
        'alias': 'El Príncipe Cobarde / Soberano Tirano Cang Tian',
        'frase_iconica': '¿Temblar? La última vez que este soberano sintió algo parecido fue por el júbilo de quemar imperios.',
        'estado_emocional': 'Gélido y calculador',
        'estado_actual': 'Recién despertado / Sediento de sangre',
        'edad': '17 años (Alma: Milenaria)',
        'descripcion': 'Joven de piel pálida y túnicas de seda desgastadas. Antes encorvado por la cobardía y el llanto constante; tras el despertar, su postura es regia e imponente, y sus ojos reflejan un abismo carmesí capaz de asfixiar con mera presencia.',
        'atributos': jsonEncode({
          'Cultivo': 'Cuerpo mortal (Alma de Soberano Tirano)',
          'Linaje': 'Décimo vástago de la Dinastía Tianlong',
          'Técnica': 'Manipulación del Hilo de Sangre Asura',
          'Debilidad actual': 'Vasos espirituales frágiles por falta de entrenamiento previo',
        }),
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      final assassinId = await db.insert('personajes', {
        'proyecto_id': projectId,
        'nombre': 'Kuro (Asesino del Loto Sombrío)',
        'rol': 'Antagonista Menor',
        'alias': 'Cuchilla de la Lluvia Nocturna',
        'frase_iconica': 'Una rata que sólo sabe llorar no merece respirar el aire de la capital.',
        'estado_emocional': 'Pánico absoluto previo a la muerte',
        'estado_actual': 'Fallecido (Cuello quebrado)',
        'edad': '29 años',
        'descripcion': 'Sicario de élite vestido con cuero reforzado y máscara de tela negra. Especialista en degüello silencioso y venenos de víbora de nueve lunas.',
        'atributos': jsonEncode({
          'Rango': 'Plata Superior',
          'Arma': 'Dagas gemelas de aleación meteórica',
          'Contratante': 'Secta Sombría / Tercer Príncipe',
        }),
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      final guardCaptainId = await db.insert('personajes', {
        'proyecto_id': projectId,
        'nombre': 'Zhao Hu',
        'rol': 'Secundario Aliado',
        'alias': 'Escudo de Hierro',
        'frase_iconica': '¡Alteza, no salga de la alcoba! ¡Mientras mi corazón lata, no tocarán un cabello suyo!',
        'estado_emocional': 'Desesperación leal',
        'estado_actual': 'Gravemente herido en el patio',
        'edad': '38 años',
        'descripcion': 'Comandante relegado a la guardia del príncipe inútil como castigo político. Armadura abollada y cicatriz en la mandíbula. Fiel hasta la muerte.',
        'atributos': jsonEncode({
          'Rango Militar': 'Capitán de Tercera Clase',
          'Lealtad': 'Inquebrantable',
          'Condición': 'Múltiples heridas de filo, pérdida masiva de sangre',
        }),
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      final rivalPrinceId = await db.insert('personajes', {
        'proyecto_id': projectId,
        'nombre': 'Long Zhen (Tercer Príncipe)',
        'rol': 'Antagonista Principal de Arco',
        'alias': 'El Dragón Esmeralda',
        'frase_iconica': 'En el tablero del trono, las piezas defectuosas deben barrerse antes del amanecer.',
        'estado_emocional': 'Confiado y arrogante',
        'estado_actual': 'En su mansión del distrito dorado',
        'edad': '23 años',
        'descripcion': 'Genio de la espada de la dinastía, favorecido por los ministros y concubinas. Impaciente por eliminar cualquier reclamo colateral.',
        'atributos': jsonEncode({
          'Cultivo': 'Reino del Mar Espiritual (Fase Media)',
          'Fuerza Política': 'Apoyado por el Gran Canciller',
        }),
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      // Relaciones entre personajes
      await db.insert('relaciones_personajes', {
        'personaje_a_id': princeId,
        'personaje_b_id': assassinId,
        'tipo': 'Enemigo mortal',
        'intensidad': 100,
        'notas': 'Kuro intentó degollarlo; el príncipe despiadado lo destrozó sin titubear.',
      });

      await db.insert('relaciones_personajes', {
        'personaje_a_id': princeId,
        'personaje_b_id': guardCaptainId,
        'tipo': 'Señor y Vasallo',
        'intensidad': 90,
        'notas': 'Zhao Hu dio su vida para proteger al príncipe cobarde. El nuevo tirano valora su lealtad.',
      });

      await db.insert('relaciones_personajes', {
        'personaje_a_id': princeId,
        'personaje_b_id': rivalPrinceId,
        'tipo': 'Rival dinástico / Venganza',
        'intensidad': 95,
        'notas': 'El Tercer Príncipe instigó el asesinato; ahora será la primera cabeza en rodar.',
      });

      // 3. CREACIÓN DE LUGARES (Tool: PlacesView)
      await db.insert('lugares', {
        'proyecto_id': projectId,
        'nombre': 'Pabellón del Bambú Sombrío',
        'descripcion': 'Residencia aislada y deteriorada en la esquina norte del complejo imperial. Rodeada por densos tallos de bambú negro que silban con el viento. Vigas podridas y patios fangosos.',
        'clima': 'Tormentoso, lluvia helada y relámpagos constantes',
        'poblacion': 'Apenas 10 sirvientes ancianos y 4 guardias relegados',
        'importancia': 'Principal',
        'atributos': jsonEncode({
          'Atmósfera': 'Opresiva, tétrica, olor a humedad, madera vieja y sangre fresca.',
          'Puntos de interés': 'Alcoba imperial destrozada, patio de piedras anegado, puerta de cedro astillada.',
          'Historia': 'Antiguo palacete de concubinas deshonradas, entregado a Long Ze como burla.',
          'Secretos': 'El sello subterráneo de energía del antiguo soberano se reactiva con la sangre derramada.',
        }),
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      await db.insert('lugares', {
        'proyecto_id': projectId,
        'nombre': 'Palacio Imperial del Dragón Dorado',
        'descripcion': 'El epicentro del imperio Tianlong. Techos de tejas doradas y columnas de jade esculpidas con dragones celestiales.',
        'clima': 'Templado mediante matrices de energía espiritual',
        'poblacion': 'Más de 40.000 cortesanos, guardias imperiales y sabios',
        'importancia': 'Principal',
        'atributos': jsonEncode({
          'Atmósfera': 'Majestuosa por fuera, nauseabunda por intrigas y veneno por dentro.',
          'Puntos de interés': 'Salón del Trono del Sol Naciente, Jardines de Loto Carmesí.',
        }),
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      // 4. CREACIÓN DE LÍNEA DE TIEMPO (Tool: TimelineView)
      await db.insert('eventos_timeline', {
        'proyecto_id': projectId,
        'titulo': 'Asedio a Medianoche en el Bambú Sombrío',
        'descripcion': 'Un escuadrón de doce sicarios de la Secta Sombría cruza el muro perimetral bajo la lluvia torrencial.',
        'fecha_relativa': 'Noche del Solsticio de Invierno - 23:40',
        'importancia': 2,
        'color_hex': '#60A5FA',
        'orden': 1,
      });

      await db.insert('eventos_timeline', {
        'proyecto_id': projectId,
        'titulo': 'Ruptura de la Defensa y Colapso del Cobarde',
        'descripcion': 'El Capitán Zhao Hu cae herido en el fango. El asesino Kuro atraviesa la mampara de papel. El Décimo Príncipe Long Ze suplica llorando y se desmaya de terror.',
        'fecha_relativa': '23:55',
        'importancia': 3,
        'color_hex': '#F87171',
        'orden': 2,
      });

      await db.insert('eventos_timeline', {
        'proyecto_id': projectId,
        'titulo': 'El Despertar del Tirano y Ejecución de Kuro',
        'descripcion': 'El alma milenaria de Cang Tian toma posesión del cuerpo. Detiene el golpe con dos dedos, destruye la daga y estrangula a Kuro sin pestañear.',
        'fecha_relativa': '00:02',
        'importancia': 3,
        'color_hex': '#D4AF37',
        'orden': 3,
      });

      await db.insert('eventos_timeline', {
        'proyecto_id': projectId,
        'titulo': 'Limpieza del Patio y Declaración de Guerra',
        'descripcion': 'El nuevo príncipe sale descalzo bajo la tormenta para encarar a los asesinos restantes y salvar al capitán.',
        'fecha_relativa': '00:15',
        'importancia': 2,
        'color_hex': '#A78BFA',
        'orden': 4,
      });

      // 5. CREACIÓN DE NOTAS EN EL TABLERO DE CORCHO (Tool: NotesView)
      await db.insert('notas', {
        'manuscrito_id': manuscritoId,
        'contenido': 'DINÁMICA DEL DESMAYO: El príncipe original no fingía; su corazón colapsó del pavor real. Ese instante de paro cardíaco abrió el vacío necesario para que el alma del Soberano Asura se anclara en su cuerpo mortal.',
        'color': '#FFE0B2', // Trama
        'categoria': '4',
        'pos_x': 40.0,
        'pos_y': 60.0,
        'ancho': 260.0,
        'alto': 180.0,
      });

      await db.insert('notas', {
        'manuscrito_id': manuscritoId,
        'contenido': 'CAMBIO DE ACTITUD: Antes tartamudeaba y temblaba. Tras el despertar, su postura es inmóvil, mirada penetrante y un tono vocal profundo que eriza la piel de quien lo escucha.',
        'color': '#E1BEE7', // Personaje
        'categoria': '3',
        'pos_x': 320.0,
        'pos_y': 60.0,
        'ancho': 260.0,
        'alto': 180.0,
      });

      await db.insert('notas', {
        'manuscrito_id': manuscritoId,
        'contenido': 'DETALLES DE AMBIENTACIÓN: El contraste entre el frío de la lluvia y el frío sobrenatural del alma del tirano que congela el vaho del asesino. Sonido del crujido de la madera y el goteo de la sangre.',
        'color': '#BBDEFB', // Escena
        'categoria': '5',
        'pos_x': 600.0,
        'pos_y': 60.0,
        'ancho': 260.0,
        'alto': 180.0,
      });

      await db.insert('notas', {
        'manuscrito_id': manuscritoId,
        'contenido': 'REGLA DE ORO: El tirano no es invulnerable al instante; su alma es ilimitada pero su recipiente es frágil. Deberá usar astucia cruel, puntos de acupuntura y reflejos sobrenaturales antes de cultivar su cuerpo.',
        'color': '#FFCDD2', // Importante
        'categoria': '8',
        'pos_x': 40.0,
        'pos_y': 260.0,
        'ancho': 260.0,
        'alto': 180.0,
      });

      // 6. CREACIÓN DE TARJETAS DE IDEAS Y CONEXIONES (Tool: IdeasView)
      final card1 = await db.insert('tarjetas', {
        'proyecto_id': projectId,
        'titulo': 'El Antiguo Soberano Cang Tian',
        'contenido': 'Emperador del Reino del Abismo sellado hace 10.000 años. Despierta en el cuerpo del príncipe más cobarde del imperio.',
        'tipo': 'lore',
        'color': '#FFCDD2',
        'pos_x': 1000.0,
        'pos_y': 1000.0,
        'ancho': 250.0,
        'alto': 160.0,
      });

      final card2 = await db.insert('tarjetas', {
        'proyecto_id': projectId,
        'titulo': 'Fachada de Cordero en la Corte',
        'contenido': 'Fingir que sigue siendo débil frente a los ministros para que sigan subestimándolo mientras construye su ejército sombrío.',
        'tipo': 'trama',
        'color': '#FFF9C4',
        'pos_x': 1350.0,
        'pos_y': 1000.0,
        'ancho': 250.0,
        'alto': 160.0,
      });

      final card3 = await db.insert('tarjetas', {
        'proyecto_id': projectId,
        'titulo': 'La Venganza contra el Tercer Príncipe',
        'contenido': 'Descubrir quién dio la orden exacta y devolver cada golpe con intereses sanguinarios en la gran Cacería de Primavera.',
        'tipo': 'conflicto',
        'color': '#BBDEFB',
        'pos_x': 1350.0,
        'pos_y': 1250.0,
        'ancho': 250.0,
        'alto': 160.0,
      });

      await db.insert('tarjetas_conexiones', {
        'tarjeta_origen_id': card1,
        'tarjeta_destino_id': card2,
      });

      await db.insert('tarjetas_conexiones', {
        'tarjeta_origen_id': card2,
        'tarjeta_destino_id': card3,
      });

      // 7. ESCRITURA DEL CAPÍTULO 1 COMPLETO EN FORMATO QUILL DELTA (Tool: EditorScreen)
      final chapterText = '''La lluvia caía como agujas de acero sobre las tejas agrietadas del Pabellón del Bambú Sombrío. El viento aullaba entre los tallos huecos, componiendo una melodía lúgubre que se mezclaba con el olor acre del óxido y la sangre fresca.

En el rincón más oscuro de la habitación imperial, acurrucado tras un biombo de madera carcomida, el Décimo Príncipe de la Gran Dinastía Tianlong no dejaba de llorar.

Se llamaba Long Ze. Durante diecisiete años, la corte entera lo había bautizado con títulos mucho menos honorables: "El Príncipe Inútil", "El Cordero Llorón", "La Basura del Harén Norte". Aislado en aquel rincón remoto del palacio, sin conexiones familiares ni cultivo marcial, su única estrategia de supervivencia había sido la cobardía: arrodillarse, bajar la cabeza y rogar clemencia ante cualquier mirada desdeñosa.

Pero esta noche, las súplicas no bastarían.

¡CRASH!

Los paneles corredizos de cedro y papel de arroz estallaron hacia el interior en una lluvia de astillas afiladas. El aire gélido de la tormenta inundó la recámara, acompañado por una figura esbelta envuelta en seda negra que aterrizó en los tablones sin emitir el más mínimo sonido. En su diestra sostenía una daga serpentina, cuya hoja dentada destilaba un líquido verdoso que chisporroteaba al tocar el suelo.

—¡Piedad... piedad, por favor! —chilló Long Ze, encogiéndose aún más. Sus manos delgadas y pálidas se aferraban a las mangas desgastadas de su túnica cerúlea—. ¡No tengo nada! ¡Renuncio a mi título! ¡Le diré a mi Hermano Imperial que jamás volveré a pisar la Ciudad Prohibida!

El asesino ladeó la cabeza. Debajo del velo de carbón que cubría su rostro, unos ojos gélidos brillaron con absoluto desprecio. Dio un paso lento hacia adelante, pisando los libros de poesía clásica desparramados en el suelo.

—Qué patético —dijo el sicario con voz ronca y rasposa—. Los sirvientes dijeron que el Décimo Príncipe era un cobarde, pero no imaginé que fuera una perra llorona. ¿De verdad corre la sangre del Dragón Celestial por esas venas tuyas? El Tercer Príncipe gasta demasiado oro contratando a la Secta Sombría para aplastar una mísera cucaracha.

Afuera, en el patio empapado, un rugido de dolor ahogado retumbó. Era el Capitán Zhao Hu, el último de los cuatro leales guardias asignados a su protección. Se escuchó el chasquido húmedo de una espada quebrando costillas y el golpe sordo de un cuerpo cayendo en el lodo. El silencio que siguió confirmó la tragedia: no quedaba nadie entre el asesino y el príncipe.

—Tus perros guardianes ya son abono para el bambú, Su Alteza —susurró el asesino con sarcasmo venenoso—. Ahora quédate quieto. La ponzoña de la víbora de nueve lunas te adormecerá la lengua antes de derretirte los pulmones. No sufrirás mucho.

El filo mortal se alzó en el aire. La punta envenenada apuntó directamente a la base de la garganta de Long Ze.

El muchacho miró la muerte de frente. El horror fue tan abrumador, tan visceral, que el pecho de Long Ze se cerró en un espasmo violento. Su corazón enfermizo dio tres latidos desbocados y luego... simplemente se detuvo. El aire abandonó sus pulmones. La visión se tiñó de un negro impenetrable y el cuerpo del Décimo Príncipe se desplomó de espaldas sobre el suelo de tatami mojado, inerte como un muñeco de trapo roto.

El asesino soltó una carcajada burlona y bajó levemente el brazo.

—¿Se desmayó del miedo? ¿Antes de que lo toque el cuchillo? Ja... Menuda escoria real. Menos trabajo para mí.

El sicario se inclinó tranquilamente, levantando la daga para cercenarle el cuello y llevar su cabeza de vuelta como prueba irrefutable ante el señor que pagaba la recompensa.

Sin embargo, en el instante en que la hoja descendió a una pulgada de la piel... el tiempo pareció detenerse.

Una ráfaga de aire no proveniente de la tormenta exterior barrió la habitación. No era viento: era una presión aplastante, pesada y sofocante como una montaña de hierro arrojada sobre el recinto. La temperatura del cuarto se desplomó en picado. El vaho de la respiración del asesino se congeló al instante en finas agujas de hielo sobre su máscara. Las gotas de lluvia que caían del techo en una gotera quedaron suspendidas a mitad de camino en el aire antes de estrellarse contra el suelo congelado.

El asesino se congeló. Su espina dorsal se erizó con un terror primitivo que jamás había experimentado en diez años como ejecutor de las sombras. Cada instinto de su ser le gritaba una sola palabra: ¡HUYE!

Pero sus piernas se negaron a obedecer. Sus músculos se habían vuelto plomo.

Sobre el tatami escarchado, los dedos de la mano izquierda del príncipe se movieron con una cadencia seca y precisa.

El cuerpo de Long Ze no se levantó torpemente como un muchacho asustado. Se incorporó con una fluidez antinatural, como si los huesos y tendones estuvieran siendo manipulados por una voluntad implacable y despiadada. La cabeza del príncipe giró lentamente hacia el asesino.

Sus párpados se abrieron.

La mirada cobarde, llorosa y temblorosa de Long Ze había desaparecido para siempre. En su lugar, ardían dos pozos insondables de un color dorado fundido, circundados por un anillo de carmesí profundo y espectral. Eran los ojos de un ser que había caminado sobre mares de cráneos, que había visto colapsar imperios celestiales sin parpadear.

Una sonrisa tenue, filosa y carente de toda humanidad curvó los labios del príncipe.

—¿Qué... qué eres tú...? —tartamudeó el asesino, el pánico estrangulándole las cuerdas vocales.

Long Ze bajó la mirada hacia sus propias manos pálidas. Las abrió y cerró despacio, escuchando el crujido de sus nudillos. Su voz brotó de su garganta, pero ya no era el chillido agudo del cordero asustado; resonaba como un trueno subterráneo, antiguo, cavernoso y majestuoso.

—Qué cuerpo tan mediocre... Vasos espirituales marchitos, músculos sin templar y un corazón blando como el lodo. Ciertamente, este envase mortal era una piltrafa despreciable.

El príncipe alzó la vista y clavó sus pupilas doradas en el sicario.

—Aun así... un insecto de sangre turbia como tú se ha atrevido a alzar metal contra este emperador.

El asesino sintió que su mente colapsaba ante aquella presencia demoníaca. Con un alarido histérico nacido de la pura desesperación, reunió hasta la última gota de su energía y lanzó una estocada brutal hacia los ojos del príncipe. Aquel era su golpe maestro, capaz de atravesar placas de acero templado.

Long Ze ni siquiera parpadeó. No retrocedió medio paso.

Simplemente levantó su mano derecha y juntó dos dedos.

¡CLANG!

Un estruendo metálico ensordecedor sacudió la estancia. La daga forjada con hierro de meteorito fue frenada en seco a tres centímetros de su rostro, atrapada con total firmeza entre el dedo índice y el medio del muchacho. La fuerza del impacto hizo añicos los tablones de madera bajo los pies del asesino, pero el brazo de Long Ze permaneció inmóvil como una roca milenaria.

—¿Arte marcial de la sombra? —murmuró Long Ze con una calma que helaba el alma—. Tan tosco y rudimentario que hasta los gusanos del inframundo se avergonzarían de aprenderlo.

Con una ligera torsión de sus dos dedos, la hoja forjada en acero negro crujió y se partió en tres pedazos con el sonido de cristal roto.

Los ojos del asesino se desorbitaron. Quiso retroceder de un salto para huir por el techo roto, pero la mano del príncipe se movió más rápido que el relámpago. Cinco dedos fríos como el mármol se cerraron alrededor de la garganta del sicario como una prensa de hierro indestructible.

—¡Ghk...! —el asesino pataleó en el aire, levantado con una sola mano por aquel joven que hasta hacía un minuto lloraba en el fango.

Long Ze lo acercó a su rostro. Sus ojos carmesí taladraron el alma del moribundo.

—Dime una cosa, rata nocturna. ¿Quién de mis queridos hermanos te pagó para venir hasta mi patio?

El asesino, asfixiándose bajo una fuerza descomunal que le trituraba la tráquea, intentó escupir una aguja envenenada oculta bajo su lengua. Pero antes de que pudiera dispararla, Long Ze hundió el pulgar libre en el punto de acupuntura bajo su mandíbula.

Un crujido repugnante resonó en el cuarto. La mandíbula del sicario se dislocó instantáneamente, derramando sangre y la aguja inofensiva sobre el suelo.

—Veo que aún tienes lealtad —dijo Long Ze en un susurro gélido—. Es inútil. No necesito que me respondas ahora. Arrancaré las respuestas de los cráneos de tus compañeros en el patio, y luego... cobraré la deuda en el Palacio Principal con intereses de sangre.

—P-piedad... —gimió el asesino entre gorgoteos carmesíes, temblando de pavor ante el monstruo que acababa de despertar.

La sonrisa de Long Ze se ensanchó, despiadada y siniestra.

—¿Piedad? Cuando este soberano gobernaba el Abismo de Sangre, los cielos enteros se arrodillaban para implorar un segundo más de aliento. Y a ninguno le fue concedido.

Con un chasquido seco y despiadado de su muñeca, Long Ze quebró el cuello del asesino.

El cuerpo sin vida de Kuro cayó al suelo como un fardo de ropa vieja, quedando inerte entre el agua de lluvia que corría por las rendijas del piso.

Long Ze tomó la seda del cinto del cadáver y limpió tranquilamente las gotas de sangre de sus dedos pálidos. Luego, descalzo, dio un paso adelante y salió al corredor exterior. La lluvia helada empapó su cabello azabache y su túnica rota, pero el frío ya no lo hacía temblar.

Abajo, en el fango del patio, los ocho asesinos restantes rodeaban el cuerpo malherido del Capitán Zhao Hu. Al escuchar los pasos crujir en la madera, los sicarios levantaron la vista hacia el corredor esperando ver a Kuro con la cabeza del príncipe cobarde.

Lo que vieron los hizo retroceder aterrorizados.

En lo alto de las escalinatas, bañado por la luz blanca de los relámpagos y envuelto en una niebla asesina que sofocaba la tormenta, el Décimo Príncipe los observaba con ojos de oro y fuego.

—Quédate en el suelo, Capitán —ordenó Long Ze, y su voz heló la sangre de los hombres armados—. Este emperador tiene ganas de recordar el sonido de los huesos al romperse.''';

      // Convertir a Quill Delta JSON
      final deltaOps = [
        {'insert': 'Capítulo 1: El Sangrado del Bambú y los Ojos del Tirano'},
        {'attributes': {'header': 1}, 'insert': '\n\n'},
        {'insert': chapterText},
        {'insert': '\n'},
      ];
      final deltaJson = jsonEncode(deltaOps);
      final totalRawWords = chapterText.trim().split(RegExp(r'\s+')).length;

      final chapterId = await db.insert('capitulos', {
        'manuscrito_id': manuscritoId,
        'titulo': 'Capítulo 1: El Sangrado del Bambú y los Ojos del Tirano',
        'contenido': deltaJson,
        'orden': 1,
        'tipo': 'capitulo',
        'palabras': totalRawWords,
        'meta_sesion': 1500,
        'meta_diaria': 2000,
        'sinopsis': 'Los asesinos asaltan el pabellón de Long Ze; cuando la daga está a punto de cercenarlo, el cobarde muere de terror y un tirano despiadado toma posesión de su carne para aniquilar al sicario.',
        'pov_personaje_id': princeId,
        'estado': 'en revisión',
        'meta_palabras': 1800,
        'creado_en': DateTime.now().toIso8601String(),
        'actualizado_en': DateTime.now().toIso8601String(),
      });

      // Crear versión inicial en historial de versiones
      await db.insert('capitulos_versiones', {
        'capitulo_id': chapterId,
        'contenido': deltaJson,
        'creado_en': DateTime.now().toIso8601String(),
      });

      print('Capítulo 1 insertado con éxito: ID $chapterId, $totalRawWords palabras.');

      // 8. VERIFICACIÓN DE HERRAMIENTAS Y SUBSISTEMAS DEL PROYECTO
      final stats = await AppDatabase.getProyectoStats(projectId);
      print('=== Estadísticas del Proyecto ===');
      print('Capítulos: ${stats['capitulos']}');
      print('Palabras: ${stats['palabras']}');
      print('Personajes: ${stats['personajes']}');
      print('Lugares: ${stats['lugares']}');
      print('Eventos: ${stats['eventos']}');

      expect(stats['capitulos'], greaterThanOrEqualTo(1));
      expect(stats['palabras'], greaterThanOrEqualTo(1000));
      expect(stats['personajes'], greaterThanOrEqualTo(4));
      expect(stats['lugares'], greaterThanOrEqualTo(2));
      expect(stats['eventos'], greaterThanOrEqualTo(4));

      // Verificación de utilidad: Tiempo de lectura
      final readingTime = NarrativeTextUtils.estimateReadingTime(totalRawWords);
      print('Tiempo estimado de lectura: $readingTime');
      expect(readingTime, isNotEmpty);

      // Verificación de utilidad: Frecuencia de palabras repetidas
      final freq = NarrativeTextUtils.analyzeWordFrequencies(chapterText, top: 10);
      print('Palabras más frecuentes (sin stop words): $freq');
      expect(freq.containsKey('asesino') || freq.containsKey('príncipe') || freq.containsKey('long'), isTrue);

      // Verificación de utilidad: Formateo de rayas de diálogo em-dash
      const testDialogue = '-- no te muevas, escoria.';
      final formattedDialogue = NarrativeTextUtils.formatDialogueDashes(testDialogue);
      print('Prueba de guiones de diálogo: "$testDialogue" -> "$formattedDialogue"');
      expect(formattedDialogue.startsWith('—No'), isTrue);

      // Verificación de utilidad: DiffUtils
      final diff = DiffUtils.computeDiff('El príncipe cobarde cayó.', 'El príncipe despiadado se levantó.');
      print('Diff calculado: ${diff.map((d) => '${d.type.name}: "${d.text}"').join(', ')}');
      expect(diff.any((d) => d.type == DiffType.insertion), isTrue);
      expect(diff.any((d) => d.type == DiffType.deletion), isTrue);

      await db.close();
      print('✓ Todas las herramientas de Novel-Writer han sido probadas y validadas con éxito.');
    });
  });
}
