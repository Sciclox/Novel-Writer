import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Populate 10 Full Chapters with Rich Text and Cover Image', () async {
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Lenovo';
    final dbPath = p.join(userProfile, 'OneDrive', 'Documentos', 'novel_writer.db');

    final db = await databaseFactory.openDatabase(dbPath);

    // 1. Buscar proyecto
    final projs = await db.query('proyectos', where: 'id = ?', whereArgs: [18]);
    int projectId = 18;
    if (projs.isEmpty) {
      final anyProj = await db.query('proyectos', where: 'titulo LIKE ?', whereArgs: ['%Décimo Príncipe%']);
      if (anyProj.isNotEmpty) {
        projectId = anyProj.first['id'] as int;
      }
    }

    // 2. Cargar imagen de portada y actualizar el proyecto
    final coverFile = File('C:\\Users\\Lenovo\\.gemini\\antigravity\\brain\\776c78a1-af4d-42c7-9d6c-b3d7e64c18f9\\novel_cover_art_1789955354424.jpg');
    if (await coverFile.exists()) {
      final bytes = await coverFile.readAsBytes();
      await db.update('proyectos', {
        'portada_blob': bytes,
        'imagen_portada': coverFile.path,
        'sinopsis': 'En la Gran Dinastía Tianlong, el Décimo Príncipe Long Ze era el hazmerreír de la corte: cobarde, enfermizo y humillado. En una noche de tormenta, un asesino está a punto de degollarlo... pero al despertar, un Tirano Asura milenario ha reclamado su carne. El cordero ha muerto. El emperador de la sangre ha despertado.',
      }, where: 'id = ?', whereArgs: [projectId]);
      print('Portada actualizada para Proyecto $projectId (${bytes.length} bytes)');
    }

    // 3. Obtener ID del manuscrito
    final manQuery = await db.query('manuscritos', where: 'proyecto_id = ?', whereArgs: [projectId]);
    int manuscritoId;
    if (manQuery.isEmpty) {
      manuscritoId = await db.insert('manuscritos', {
        'proyecto_id': projectId,
        'color_fondo': '#FFFFFF',
        'fuente': 'Merriweather',
        'font_size': 18.0,
        'line_height': 1.8,
      });
    } else {
      manuscritoId = manQuery.first['id'] as int;
    }

    // 4. Obtener personajes para asignar POVs
    final chars = await db.query('personajes', where: 'proyecto_id = ?', whereArgs: [projectId]);
    int? longZeId;
    int? zhaoHuId;
    int? longZhenId;
    for (var c in chars) {
      final name = (c['nombre'] as String).toLowerCase();
      if (name.contains('long ze')) longZeId = c['id'] as int;
      if (name.contains('zhao hu')) zhaoHuId = c['id'] as int;
      if (name.contains('long zhen')) longZhenId = c['id'] as int;
    }

    // Limpiar capítulos anteriores para regenerar los 10 limpios y ordenados
    await db.delete('capitulos', where: 'manuscrito_id = ?', whereArgs: [manuscritoId]);

    // Función para crear Delta JSON enriquecido
    String makeDelta(List<Map<String, dynamic>> paragraphs) {
      final ops = <Map<String, dynamic>>[];
      for (var p in paragraphs) {
        final text = p['text'] as String;
        final bold = p['bold'] == true;
        final italic = p['italic'] == true;
        final isHeader = p['header'] == true;

        if (isHeader) {
          ops.add({'insert': text, 'attributes': {'bold': true, 'header': 2}});
          ops.add({'insert': '\n\n'});
        } else {
          final attrs = <String, dynamic>{};
          if (bold) attrs['bold'] = true;
          if (italic) attrs['italic'] = true;

          if (attrs.isNotEmpty) {
            ops.add({'insert': text, 'attributes': attrs});
          } else {
            ops.add({'insert': text});
          }
          ops.add({'insert': '\n\n'});
        }
      }
      return jsonEncode(ops);
    }

    // Definición de los 10 Capítulos
    final capitulosData = [
      {
        'titulo': 'Capítulo 1: El Sangrado del Bambú y los Ojos del Tirano',
        'sinopsis': 'La noche de la tormenta en el Pabellón del Bambú Sombrío. El Décimo Príncipe Long Ze se desmaya ante el asesino Kuro; al despertar, el Asura Carmesí destripa a sus atacantes.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1600,
        'contenido': makeDelta([
          {'text': 'Capítulo 1: El Sangrado del Bambú y los Ojos del Tirano', 'header': true},
          {'text': 'La lluvia caía como agujas de acero sobre las tejas agrietadas del Pabellón del Bambú Sombrío. El viento aullaba entre los tallos huecos, componiendo una melodía lúgubre que se mezclaba con el hedor acre de la pólvora húmeda y la sangre fresca.'},
          {'text': 'En el rincón más oscuro de la cámara imperial, acurrucado tras un biombo de seda podrida, el Décimo Príncipe de la Gran Dinastía Tianlong no dejaba de llorar.'},
          {'text': 'Se llamaba Long Ze. Durante diecisiete años, la corte entera lo había bautizado con títulos despectivos: «El Cordero Llorón», «La Vergüenza del Dragón Dorado», «El Príncipe Impotente». Jamás había empuñado una espada de verdad ni cultivado su Dan Tian. Para sus nueve hermanos mayores, no era más que un insecto conveniente que el Emperador mantenía con vida por mera indulgencia.'},
          {'text': '—¡Proceded! ¡Que no quede nadie con respiración en este lodazal! —rugió una voz áspera desde el patio.'},
          {'text': 'El capitán Zhao Hu, con la armadura despedazada y tres flechas de ballesta enterradas en el muslo, bloqueaba la puerta doble con su propio torso. Su respiración era un estertor agónico:'},
          {'text': '—¡Alteza... huya por el conducto trasero! ¡Son los Espectros de la Niebla Sombría! ¡No vienen a secuestrarlo... vienen a degollarlo!'},
          {'text': 'Un chasquido seco partió la madera de alcanfor. El filo de una katana de hoja ennegrecida atravesó el pecho del capitán desde el exterior. Zhao Hu escupió un chorro espeso sobre el suelo de roble y colapsó, sus ojos desorbitados fijos en el aterrorizado príncipe.'},
          {'text': 'Un hombre envuelto en vendajes empapados y cuero negro cruzó el umbral sin prisa. Kuro, el asesino líder, sacudió la sangre de su filo con un chasquido impecable.'},
          {'text': '—Tanto escándalo por una rata —bufó Kuro, dando un paso al frente—. Tu tercer hermano pagó diez mil monedas de oro espiritual por tu garganta, Décimo Príncipe. Agradece que mi acero es rápido.'},
          {'text': 'Long Ze intentó retroceder, pero su espalda golpeó el muro de piedra fría. El miedo paralizó su garganta; su pecho convulsionó y una oscuridad asfixiante nubló su visión. El príncipe se desmayó sobre sus propias rodillas, colapsando como un fardo de ropa vieja.'},
          {'text': '—Patético —Kuro alzó la katana a dos manos para la decapitación ritual.'},
          {'text': 'El filo descendió cortando el aire húmedo.'},
          {'text': 'Y entonces, en el instante exacto antes de que el acero tocara la piel desnuda del cuello... dos dedos pálidos y esbeltos interceptaron la hoja.', 'bold': true},
          {'text': '¡CLAAANG!'},
          {'text': 'Una onda de choque carmesí detonó en el suelo, pulverizando las baldosas de piedra en un radio de tres metros. Kuro abrió los ojos con pánico incontrolable. La katana no se movía ni un milímetro. La fuerza que la sujetaba no pertenecía a un mortal.'},
          {'text': 'El cuerpo del príncipe se enderezó lentamente. No había temblor. No había llanto.'},
          {'text': 'Cuando los párpados de Long Ze se abrieron, sus pupilas humanas habían desaparecido. En su lugar, dos soles de fuego rojo sangre ardían con una crueldad milenaria que parecía haber devorado imperios enteros.'},
          {'text': '—¿Rata? —susurró una voz cavernosa, grave y cargada de resonancia demoníaca—. Hace diez mil años que nadie se atrevía a mirarme sin arrodillarse hasta romperse las rótulas.'},
          {'text': 'Con un ligero giro de muñeca, los dedos de Long Ze quebraron la katana de acero forjado como si fuera una oblea seca. Kuro intentó saltar hacia atrás, pero la mano del príncipe se movió como un relámpago negro, cerrándose alrededor de su garganta.'},
          {'text': 'Kuro pataleó desesperado, sintiendo que sus vértebras crujían como madera seca bajo un torno hidráulico. En los ojos del príncipe vio el abismo insondable del infierno Asura.'},
          {'text': '—Duerme, escoria —dijo Long Ze con una sonrisa desprovista de calor humano.'},
          {'text': 'Un estallido de energía carmesí destrozó el cuello y el pecho del asesino en un instante. Cuando el cadáver cayó sin vida al suelo ensangrentado, el Décimo Príncipe respiró hondo el aire de la noche, limpiándose la lluvia del rostro.'},
          {'text': '«Este cuerpo es débil... pero servirá. Esta dinastía se arrodillará ante mí, o la ahogaré en su propia sangre.»', 'italic': true},
        ]),
      },
      {
        'titulo': 'Capítulo 2: Cenizas y Recuerdos Rotos',
        'sinopsis': 'Long Ze asimila las memorias de diecisiete años de abusos y purga a los sirvientes traidores que vendieron la guardia del pabellón.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1500,
        'contenido': makeDelta([
          {'text': 'Capítulo 2: Cenizas y Recuerdos Rotos', 'header': true},
          {'text': 'El silencio que siguió a la muerte de Kuro fue sepulcral. El goteo constante de la lluvia sobre los cadáveres de los asesinos era el único sonido en el patio del Pabellón del Bambú Sombrío.'},
          {'text': 'Long Ze se sentó con las piernas cruzadas en el suelo empapado de sangre. Cerró los ojos y permitió que la marea de recuerdos del antiguo dueño del cuerpo inundara su conciencia.'},
          {'text': 'Era un desfile interminable de humillaciones. Su madre, una concubina extranjera sin clan de respaldo, muerta por un «envenenamiento misterioso» cuando él tenía apenas cinco años. Los sirvientes que le escupían en la sopa. Los banquetes de Año Nuevo donde sus hermanos mayores lo obligaban a arrodillarse para servirles vino como si fuera un perro encadenado.'},
          {'text': '—Qué vida tan miserable llevaste, pequeño insecto —murmuró Long Ze, sintiendo un eco lejano de tristeza en el pecho del cuerpo que ahora habitaba—. Pero no te preocupes. Todo aquel que te hizo derramar una lágrima me pagará con ríos de sangre.'},
          {'text': 'Un leve crujido en la galería exterior interrumpió sus pensamientos.'},
          {'text': 'El mayordomo Liu, el eunuco encargado del pabellón, se asomaba tras una columna con una linterna temblorosa en la mano. Cuando vio los cuerpos destripados y a Long Ze de pie en medio del charco escarlata, sus piernas cedieron.'},
          {'text': '—¿A-Alteza? —tartamudeó Liu, con el rostro más blanco que la cal—. ¿Están... están todos muertos? ¿Dónde están los atacantes?'},
          {'text': 'Long Ze dio un paso hacia adelante. Su velocidad fue tan aterradora que Liu ni siquiera vio el movimiento; para cuando parpadeó, el príncipe ya estaba a diez centímetros de su rostro.'},
          {'text': '—La puerta trasera del pabellón estaba cerrada con cerrojo de hierro por fuera —dijo Long Ze con una voz suave, casi cariñosa—. La guardia del capitán Zhao Hu fue drogada con polvo de flor de sueño en el té de la cena. Dime, Liu... ¿cuánto te pagó el Tercer Príncipe para asegurar mi asesinato?'},
          {'text': 'El eunuco se desplomó de rodillas, golpeando la frente contra las piedras mojadas hasta sangrar:'},
          {'text': '—¡Piedad, Décimo Príncipe! ¡Me amenazaron con matar a mis sobrinos! ¡Fui obligado! ¡Por favor, tenga misericordia!'},
          {'text': 'Long Ze sonrió. Fue una sonrisa que congeló el aliento en los pulmones del eunuco.'},
          {'text': '—La misericordia es un lujo para los débiles, Liu. Y yo ya no soy débil.'},
          {'text': 'Un chasquido seco resonó en el pabellón. El cuerpo inerte del eunuco se desplomó hacia un lado, con el cuello quebrado en un ángulo antinatural.'},
          {'text': 'Long Ze sacudió sus mangas de seda y miró hacia el capitán Zhao Hu, que aún respiraba con dificultad entre los escombros.'},
          {'text': '—Tú... capitán. Aún te quedan diez años de vida útil si te mantienes leal a mí. Levántate. Esta misma noche comenzaremos a cobrar las primeras deudas.'},
        ]),
      },
      {
        'titulo': 'Capítulo 3: El Regalo de Medianoche',
        'sinopsis': 'El Tercer Príncipe Long Zhen espera la confirmación de la muerte de Long Ze en su opulento palacio, pero recibe un macabro paquete que cambia las reglas del juego.',
        'pov': longZhenId ?? longZeId,
        'estado': 'completado',
        'meta_palabras': 1500,
        'contenido': makeDelta([
          {'text': 'Capítulo 3: El Regalo de Medianoche', 'header': true},
          {'text': 'En el ala este de la Ciudad Prohibida, el Pabellón del Fénix Dorado resplandecía con sedas rojas, incienso de sándalo celestial y copas de vino de jade blanco.'},
          {'text': 'El Tercer Príncipe, Long Zhen, yacía reclinado sobre un diván de piel de tigre blanco. Tenía veintidós años, una mandíbula afilada y la mirada calculadora de un halcón de caza. Entre los diez herederos, él era considerado el cerebro militar más prometedor de la corte.'},
          {'text': '—¿Aún no hay noticias de Kuro? —preguntó Long Zhen a su consejero privado, haciendo girar una perla luminosa entre sus dedos.'},
          {'text': '—La tormenta en el Bambú Sombrío es densa, mi señor —respondió el consejero—. Pero Kuro llevó a doce asesinos de élite en la etapa de Condensación de Qi. El Décimo ni siquiera tiene cultivado el primer meridiano. A estas horas, su cadáver ya debe de estar flotando en el río subterráneo.'},
          {'text': 'Long Zhen sonrió con satisfacción:'},
          {'text': '—Una molestia menos para el banquete del Emperador. Con el décimo fuera del tablero, el reparto de feudos se concentrará entre el Quinto y yo.'},
          {'text': 'En ese instante, un ruido sordo resonó desde la terraza del patio interior. Un objeto pesado había caído sobre las losas de mármol.'},
          {'text': 'Los guardias personales del Tercer Príncipe desenvainaron sus aceros al unísono, rodeando el diván en formación de escudos. Long Zhen frunció el ceño:'},
          {'text': '—¿Quién se atreve a profanar mi residencia? ¡Traedlo aquí!'},
          {'text': 'Dos soldados avanzaron con antorchas hacia la terraza. Allí, sobre un charco de agua de lluvia, descansaba una caja de laca negra sellada con cordeles de cáñamo rojo.'},
          {'text': '—Mi señor... no hay nadie en los techos. Solo dejaron esta caja.'},
          {'text': 'Long Zhen se levantó con desdén. —Abridla con cuidado. Podría tener agujas envenenadas.'},
          {'text': 'El guardia cortó los cordeles con la punta de una daga y levantó la tapa de laca.'},
          {'text': 'El silencio en el salón fue repentino y absoluto. El guardia retrocedió tambaleándose, con náuseas visibles en la garganta.'},
          {'text': 'Dentro de la caja, colocada sobre una almohadilla de seda blanca manchada de carmesí, estaba la cabeza cercenada de Kuro. Sus ojos estaban abiertos en una mueca de terror indescriptible, y en su frente alguien había tallado con una hoja afilada cuatro caracteres en lengua imperial:'},
          {'text': '«EL SIGUIENTE ERES TÚ».', 'bold': true},
          {'text': 'Long Zhen sintió que la sangre se le helaba en las venas. La perla luminosa resbaló de sus dedos y se partió contra el mármol.'},
          {'text': '—¿Quién... quién hizo esto? —rugió Long Zhen, y por primera vez en su vida, sus propios oficiales escucharon una nota inconfundible de pánico en la voz de su amo.'},
        ]),
      },
      {
        'titulo': 'Capítulo 4: Saqueo en el Pabellón Alquímico',
        'sinopsis': 'Para reconstruir su cuerpo mortal, Long Ze irrumpe en la Tesorería de Píldoras Sagradas, devorando hierbas venenosas para templar su físico de Asura.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1500,
        'contenido': makeDelta([
          {'text': 'Capítulo 4: Saqueo en el Pabellón Alquímico', 'header': true},
          {'text': 'La madrugada trajo una niebla densa que envolvía las altas pagodas de la capital imperial. En el distrito norte, el Gran Pabellón de las Píldoras Sagradas custodiaba los tesoros medicinales más codiciados del imperio Tianlong.'},
          {'text': 'Dos ancianos alquimistas con túnicas grises revisaban el inventario de suministros cuando la pesada puerta de bronce de la entrada se abrió de golpe sin previo aviso.'},
          {'text': 'Por el umbral entró una figura esbelta vestida con túnicas de seda negra y oro desgastadas por la lluvia. Sus pasos no producían el menor eco contra el suelo pulido de jade.'},
          {'text': '—¿Quién es el insolente que interrumpe la hora de la destilación celestial? —bramó el Anciano Wu, ajustándose sus lentes de cristal.'},
          {'text': 'Cuando los ancianos reconocieron el rostro del intruso, una mueca de desprecio brotó espontáneamente en sus labios:'},
          {'text': '—¿El Décimo Príncipe? ¿Qué hace esta basura aquí a estas horas? Su asignación mensual de píldoras ya fue confiscada por orden del Tercer Príncipe.'},
          {'text': 'Long Ze no se detuvo. Caminó directamente hacia el estante blindado donde descansaban los frascos de cristal sellados con talismanes amarillos.'},
          {'text': '—No vengo por píldoras de basura para mortales —dijo Long Ze, barriendo con la mirada las etiquetas de los estantes—. Quiero la Flor del Corazón de Fuego y el Veneno del Dragón de Sombra.'},
          {'text': 'El Anciano Wu se carcajeó:'},
          {'text': '—¿Está demente este bastardo? La Flor de Fuego funde las entrañas de cualquier cultivador por debajo del Reino del Núcleo Dorado, y el Veneno de Sombra disuelve la carne en tres respiraciones. ¡Guardias, saquen a este loco a patadas!'},
          {'text': 'Dos discípulos fornidos armados con bastones de bronce corrieron hacia Long Ze. Pero antes de que pudieran dar dos pasos, una presión gravitacional monstruosa los aplastó contra el suelo de piedra.'},
          {'text': '¡CRACK! ¡CRACK!'},
          {'text': 'Los bastones de bronce se doblaron en U bajo el peso invisible del aire, y los dos discípulos escupieron sangre, incapaces de levantar la barbilla ni un solo milímetro.'},
          {'text': 'Los dos ancianos retrocedieron aterrados hasta chocar contra los calderos de cobre caliente. El aire del pabellón se había vuelto tan denso que respirar quemaba los pulmones.'},
          {'text': '—L-La presión del Alma Primordial... —balbuceó el Anciano Wu con los dientes castañeteando—. ¿C-Cómo es posible? ¡Si tú no tienes cultivo!'},
          {'text': 'Long Ze rompió los sellos mágicos de los dos frascos con un simple gesto de la mano. Sin dudar un instante, vertió el polvo incandescente de la flor de fuego y el líquido viscoso del veneno oscuro directamente en su boca, tragándolos de golpe.'},
          {'text': 'Una llamarada escarlata brotó de sus poros. Sus venas se hincharon bajo la piel translúcida como raíces de fuego líquido. El dolor era suficiente para volver loco a diez hombres, pero en el rostro de Long Ze solo se dibujó una mueca de satisfacción salvaje.'},
          {'text': '—Segundo Meridiano del Asura... desbloqueado —exhaló una bocanada de humo negro y miró a los dos ancianos—. Agradezcan que hoy estoy de buen humor. La próxima vez que me hablen sin inclinarse a noventa grados, cosecharé sus lenguas.'},
        ]),
      },
      {
        'titulo': 'Capítulo 5: El Banquete de los Dragones Ciegos',
        'sinopsis': 'La corte imperial celebra el banquete semestral de los príncipes ante el Emperador Tianlong. Los nobles planean burlarse de Long Ze, pero su presencia paraliza el gran salón.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1600,
        'contenido': makeDelta([
          {'text': 'Capítulo 5: El Banquete de los Dragones Ciegos', 'header': true},
          {'text': 'El Gran Salón del Trono Dorado de Tianlong resplandecía con la opulencia acumulada durante trescientos años de conquistas. Columnas monumentales talladas con dragones de oro macizo sostenían un techo pintado con constelaciones de piedras preciosas.'},
          {'text': 'Cientos de ministros, generales y nobles de alto linaje ocupaban las mesas bajas a ambos lados de la alfombra imperial de terciopelo escarlata. Al fondo, sobre una plataforma elevada de nueve escalones de jade blanco, el Emperador Long Aotian observaba con ojos severos a sus diez herederos reunidos.'},
          {'text': 'El Tercer Príncipe, Long Zhen, lucía pálido a pesar de sus ropajes suntuosos. No había dormido en dos días desde que aquella caja maldita había aparecido en su terraza.'},
          {'text': '—¡Presentando al Décimo Príncipe, Long Ze! —entonó el heraldo oficial en las puertas monumentales.'},
          {'text': 'Murmullos de burla y sonrisas burlonas recorrieron las mesas de los nobles:'},
          {'text': '—¿El cobarde se atrevió a venir? —susurró un viceministro—. Dicen que anoche casi se desmaya por un trueno durante la tormenta.'},
          {'text': '—Seguramente vendrá temblando a rogar por una concesión de arroz en las provincias del sur.'},
          {'text': 'Pero los murmullos se extinguieron como velas en un vendaval en el momento en que Long Ze cruzó las puertas.'},
          {'text': 'No vestía sus habituales harapos humildes. Portaba una túnica de seda azul noche con dragones de oro bordados a mano y brazales de obsidiana negra. Su cabello negro azabache ondeaba suelto sobre sus hombros anchos, y su postura irradiaba una majestad gélida que demandaba sumisión.'},
          {'text': 'Cada paso que daba resonaba en el salón con la cadencia de un tambor de guerra. Una tenue bruma carmesí serpenteaba sutilmente alrededor de sus dedos, disipando la opulencia de la sala con un aura que helaba los huesos.'},
          {'text': 'Los ministros más ancianos que estaban cerca de la alfombra retrocedieron instintivamente, tapándose la boca con las mangas ante la repentina dificultad para respirar.'},
          {'text': 'Cuando Long Ze pasó frente a la mesa del Tercer Príncipe, clavó sus ojos en él.'},
          {'text': 'Long Zhen sintió un golpe invisible en el pecho. Por un segundo, creyó ver detrás de Long Ze la silueta gigantesca de un dios de la guerra con múltiples brazos y ojos en llamas, devorando dragones celestiales.'},
          {'text': 'La copa de vino de Long Zhen se volcó sobre la mesa, manchando sus pantalones de púrpura imperial.'},
          {'text': 'En lo alto del trono, el Emperador Tianlong se enderezó lentamente, sus ojos entrecerrados fijos en su décimo hijo con un brillo de asombro y peligro jamás visto.'},
          {'text': '—Ze\'er... —dijo el Emperador con voz resonante—. Parece que el aire del Pabellón del Bambú te ha sentado bien.'},
          {'text': 'Long Ze no se arrodilló. Inclinó la cabeza apenas unos centímetros, con una sonrisa fría que desafiaba a los cielos:'},
          {'text': '—Padre Imperial. El cordero que conocías murió anoche bajo la lluvia. El que está ante ti... ha venido a reclamar lo que le pertenece.'},
        ]),
      },
      {
        'titulo': 'Capítulo 6: Triturador de Jade',
        'sinopsis': 'Chen Wei, el mejor guerrero del Tercer Príncipe, reta a Long Ze a un duelo en la Terraza Blanca. Long Ze destruye su espada sagrada con dos dedos desnudos.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1550,
        'contenido': makeDelta([
          {'text': 'Capítulo 6: Triturador de Jade', 'header': true},
          {'text': 'La audacia de Long Ze provocó un terremoto político en la corte. Los ministros conservadores gritaban por «falta de piedad filial», mientras los generales de frontera miraban al príncipe con un respeto recién nacido.'},
          {'text': 'Desesperado por recuperar la ventaja y borrar la humillación, el Tercer Príncipe dio una señal a su mano derecha.'},
          {'text': 'Chen Wei, apodado «La Espada de las Siete Luces», un genio marcial en el Reino de la Formación del Núcleo que había vencido a decenas de rivales en los torneos provinciales, se adelantó con paso marcial.'},
          {'text': '—¡Décimo Príncipe! —gritó Chen Wei, desenvainando una espada dorada que desprendía un resplandor cegador—. Tus palabras hacia Su Majestad son una afrenta intolerable. En nombre del honor de la corte, te desafío a un intercambio amistoso en la Terraza Blanca de Jade.'},
          {'text': 'Todos sabían lo que significaba un «intercambio amistoso» en manos de Chen Wei: lisiar a su oponente, cortarle los tendones del brazo para que jamás volviera a empuñar un arma.'},
          {'text': '—¿Aceptas el reto, Décimo Príncipe? —preguntó Chen Wei con una sonrisa cargada de arrogancia—, ¿o volverás a esconderte bajo las faldas de tus nodrizas como hiciste toda tu vida?'},
          {'text': 'Long Ze miró al guerrero como quien mira a una mosca zumbando cerca de un plato de comida.'},
          {'text': '—Acepto —dijo con calma—. Pero las armas de juguete no me interesan. Ven con todo tu poder, si aprecias tu vida.'},
          {'text': 'Minutos después, la corte entera se congregó en los balcones que rodeaban la monumental Terraza de Jade Blanco.'},
          {'text': 'Chen Wei adoptó una postura clásica de esgrima imperial. La energía dorada de su núcleo estalló alrededor de su hoja, creando un vendaval de viento cortante que hizo temblar los estandartes:'},
          {'text': '—¡Corte Celestial del Dragón Dorado! —rugió Chen Wei, lanzándose hacia adelante a una velocidad casi imperceptible para el ojo humano.'},
          {'text': 'La espada descendió buscando partir a Long Ze en dos desde el hombro hasta la cadera.'},
          {'text': 'Long Ze ni siquiera pestañeó.'},
          {'text': 'Alzó la mano derecha desarmada, envuelta en una llamarada negra y carmesí que absorbía la luz del sol, e interceptó el filo dorado directamente con los dedos.'},
          {'text': '¡KRAAAAK!'},
          {'text': 'Una onda de choque pulverizó las baldosas de jade blanco bajo los pies de ambos, lanzando esquirlas de piedra contra las barandillas. La espada de siete luces de Chen Wei, un tesoro forjado en acero meteórico, se quebró en cientos de fragmentos dorados que llovieron sobre la arena.'},
          {'text': 'Chen Wei quedó congelado, con la empuñadura rota en la mano temblorosa y sangre brotando de sus labios por el impacto del contragolpe.'},
          {'text': '—¿Es esto todo lo que puede ofrecer el mejor perro de mi hermano? —susurró Long Ze.'},
          {'text': 'Con la palma abierta, Long Ze golpeó el pecho de Chen Wei. El sonido de las costillas rompiéndose resonó en toda la terraza. El campeón salió disparado cuarenta metros por el aire, estrellándose contra una estatua de león de piedra que se derrumbó sobre su cuerpo inconsciente.'},
          {'text': 'El silencio que cayó sobre la corte imperial fue absoluto.'},
        ]),
      },
      {
        'titulo': 'Capítulo 7: La Cripta del Dios Caído',
        'sinopsis': 'Long Ze desciende a las catacumbas secretas bajo la capital para reclamar la Alabarda del Dragón Oscuro y secretos de la antigua dinastía.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1500,
        'contenido': makeDelta([
          {'text': 'Capítulo 7: La Cripta del Dios Caído', 'header': true},
          {'text': 'La noche del duelo, la capital entera no hablaba de otra cosa que de la monstruosa transformación del Décimo Príncipe. Pero mientras la corte conspiraba a puerta cerrada, Long Ze ya tenía otro objetivo en mente.'},
          {'text': 'Guiado por los recuerdos del Asura milenario y los mapas ocultos de la primera dinastía, Long Ze bajó por un pasaje subterráneo sellado tras el Altar de los Antepasados.'},
          {'text': 'A trescientos metros bajo tierra, las catacumbas respiraban un aire helado impregnado de miasma antiguo. Huesos de bestias colosales y estatuas de guerreros sin rostro flanqueaban el camino de baldosas de obsidiana.'},
          {'text': '—Este lugar no ha cambiado en diez mil años —dijo Long Ze para sí mismo, esquivando con gracia tres matrices de trampas con flechas envenenadas y gas petrificante.'},
          {'text': 'Al final de la galería, en el centro de un estanque de lava negra solidificada, una alabarda de dos metros y medio de largo estaba clavada en un pedestal de piedra celestial.'},
          {'text': 'Era la Alabarda del Dragón Oscuro, un arma forjada con la médula de un dragón del vacío y sangre de dioses caídos. Durante mil años, los emperadores de Tianlong habían intentado extraerla del pedestal sin éxito; todo aquel que la tocaba era consumido por las llamas espectrales en segundos.'},
          {'text': 'Cuando Long Ze se acercó, la alabarda comenzó a vibrar con un zumbido ensordecedor. Llamas negras brotaron de la hoja de doble filo, iluminando la caverna con destellos violetas.'},
          {'text': '—Reconoces a tu maestro, ¿verdad? —dijo Long Ze, extendiendo la mano derecha sin la menor vacilación.'},
          {'text': 'En cuanto sus dedos envolvieron la empuñadura de escamas de dragón, una llamarada de fuego negro envolvió su brazo entero. La carne ardió, pero la sangre del Asura respondió con un rugido que hizo temblar los cimientos de la capital imperial.'},
          {'text': '—¡RÚNDETE ANTE MÍ! —rugió Long Ze.'},
          {'text': 'Con un tirón violento, arrancó la alabarda del pedestal milenario. El miasma de la caverna fue absorbido por el vórtice de la hoja, restaurando su brillo letal.'},
          {'text': 'El Décimo Príncipe blandió el arma con una sola mano, cortando el aire con un silbido aterrador que dejó una estela de fuego negro en la penumbra.'},
          {'text': '«Ahora sí... que vengan todas las legiones que quieran.»', 'italic': true},
        ]),
      },
      {
        'titulo': 'Capítulo 8: Ríos Rojos en el Valle de la Ceniza',
        'sinopsis': 'Una emboscada masiva de 200 mercenarios y sectarios ataca el destacamento de Long Ze fuera de la capital. El príncipe desata el Dominio Asura.',
        'pov': zhaoHuId ?? longZeId,
        'estado': 'completado',
        'meta_palabras': 1550,
        'contenido': makeDelta([
          {'text': 'Capítulo 8: Ríos Rojos en el Valle de la Ceniza', 'header': true},
          {'text': 'Al día siguiente, por decreto imperial influenciado por las intrigas de sus hermanos, Long Ze fue enviado al Valle de la Ceniza bajo el pretexto de inspeccionar las defensas fronterizas contra las sectas rebeldes.'},
          {'text': 'Era una trampa evidente.'},
          {'text': 'El capitán Zhao Hu, con sus heridas vendadas y apoyado en una lanza de roble, cabalgaba al lado del carruaje de Long Ze. La tensión en el aire era tan espesa que los caballos resoplaban con nerviosismo.'},
          {'text': '—Alteza... este cañón es el lugar predilecto para emboscadas. Si los clanes oscuros nos atacan aquí, no tendremos retirada.'},
          {'text': 'Long Ze, que meditaba en el asiento del carruaje con la Alabarda del Dragón Oscuro apoyada en sus rodillas, ni siquiera abrió los ojos:'},
          {'text': '—No son ellos quienes deben preocuparse por mi retirada, capitán. Son ellos quienes no tendrán hacia dónde huir.'},
          {'text': 'Un segundo después, el cuerno de guerra sonó en las cumbres del cañón.'},
          {'text': 'Doscientos guerreros enmascarados, ataviados con armaduras de hierro negro y espadas impregnadas de veneno corrosivo, saltaron desde las rocas altas bloqueando ambos extremos del desfiladero.'},
          {'text': 'Eran los mercenarios de la Secta de la Luna Sangrienta, asesinos a sueldo famosos por no dejar testigos vivos.'},
          {'text': '—¡Corten en pedazos al príncipe y lleven su cabeza al Tercero! —rugió el comandante rebelde.'},
          {'text': 'Long Ze descendió del carruaje con parsimonia. Clavó la alabarda en la tierra pedregosa del valle.'},
          {'text': '—Dominio Asura: Campo de Matanza —susurró con calma helada.'},
          {'text': 'Un domo de energía carmesí se expandió a la velocidad de un relámpago, encerrando a los doscientos mercenarios en un espacio donde la gravedad se multiplicó por diez y el aire se transformó en vapores de sangre hirviente.'},
          {'text': 'Los mercenarios comenzaron a gritar aterrados. Sus armas pesaban como yunques de plomo, y sus ojos y oídos empezaron a sangrar espontáneamente.'},
          {'text': 'Long Ze se movió como un espectro entre las filas enemigas. Cada golpe de la alabarda cercenaba a cinco hombres a la vez. En menos de cinco minutos, el cañón entero se tiñó de rojo oscuro, y los doscientos asesinos yacían inmóviles sobre la ceniza.'},
          {'text': 'El capitán Zhao Hu contempló la carnicería con las piernas temblorosas. Supo en ese instante que su señor ya no era un simple príncipe imperial: era una fuerza de la naturaleza que devoraría el mundo.'},
        ]),
      },
      {
        'titulo': 'Capítulo 9: El Juicio del Trono Dorado',
        'sinopsis': 'Los ministros exigen la ejecución de Long Ze por masacre y brujería demoníaca. Long Ze se para ante el trono del Emperador sin arrodillarse, desafiando a la dinastía entera.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1500,
        'contenido': makeDelta([
          {'text': 'Capítulo 9: El Juicio del Trono Dorado', 'header': true},
          {'text': 'La noticia de la aniquilación de doscientos mercenarios de élite en el Valle de la Ceniza cayó sobre la corte imperial como un rayo en cielo despejado.'},
          {'text': 'El Tercer Príncipe Long Zhen, respaldado por el Primer Ministro y cinco generales corruptos, convocó un Juicio Imperial de Emergencia. Acusaban a Long Ze de practicar artes demoníacas prohibidas, asesinar sin juicio y planear una rebelión armada contra el trono.'},
          {'text': 'El gran salón estaba abarrotado por dos mil soldados de la Guardia Imperial con armaduras doradas y arcos tensados apuntando a las puertas.'},
          {'text': 'Long Ze entró solo. Su túnica imperial estaba manchada de sangre seca, y la Alabarda del Dragón Oscuro descansaba sobre su hombro derecho como un trofeo de caza.'},
          {'text': '—¡Arrodíllate ante el Hijo del Cielo, traidor! —rugió el Gran Censor Imperial, blandiendo el rollo con los cargos criminales.'},
          {'text': 'Long Ze clavó la alabarda en el mármol del salón, resquebrajando los azulejos hasta el estrado imperial.'},
          {'text': '—El día que yo me arrodille ante un mortal, este palacio entero se hundirá en el infierno —dijo con voz tan resonante que hizo temblar las lámparas de cristal.'},
          {'text': 'El Tercer Príncipe se adelantó, señalándolo con un dedo tembloroso:'},
          {'text': '—¡Padre! ¡Lo ves con tus propios ojos! ¡Desprecia las leyes imperiales, ha adquirido poderes demoníacos y no muestra respeto por la corona! ¡Exijo su decapitación inmediata por alta traición!'},
          {'text': 'El Emperador Long Aotian miró fijamente a Long Ze. La presión espiritual de un monarca en el Reino de la Transformación del Espíritu llenó la sala, sofocando a todos los presentes.'},
          {'text': 'Pero ante esa presión cósmica, Long Ze ni siquiera pestañeó. La sombra del Asura milenario emergió tras su espalda, bloqueando el poder del Emperador con una facilidad pasmosa.'},
          {'text': '—Zhen\'er dice que eres un traidor —dijo el Emperador con voz de trueno—. ¿Qué tienes que decir en tu defensa?'},
          {'text': 'Long Ze sonrió con frialdad implacable:'},
          {'text': '—¿Defensa? Un león no se defiende ante los chillidos de las hienas. Si la corte cree que tiene la fuerza para quitarme la cabeza... que vengan todos a la vez. Les ahorraré el trabajo del juicio.'},
        ]),
      },
      {
        'titulo': 'Capítulo 10: El Ascenso del Tirano de Tianlong',
        'sinopsis': 'El clímax del primer arco: El Tercer Príncipe da un golpe de estado desesperado. Long Ze masacra a los golpistas y asciende los escalones del trono bañado en luz de luna roja.',
        'pov': longZeId,
        'estado': 'completado',
        'meta_palabras': 1700,
        'contenido': makeDelta([
          {'text': 'Capítulo 10: El Ascenso del Tirano de Tianlong', 'header': true},
          {'text': 'El desafío de Long Ze en el tribunal desató la locura reprimida en el corazón de Long Zhen. Comprendiendo que jamás podría vencer a su hermano en un terreno justo, el Tercer Príncipe dio la señal convenida con los generales traidores.'},
          {'text': '¡Aullaron los cuernos de asedio en las cuatro murallas de la capital!'},
          {'text': 'Cinco mil soldados rebeldes irrumpieron en los jardines de la Ciudad Prohibida, degollando a los guardias leales e incendiando las torres de vigilancia. Una luna de color sangre iluminaba el cielo nocturno como un ojo de fuego celestial.'},
          {'text': '—¡Si no puedo tener el trono por la ley, lo tomaré por el acero! —gritó Long Zhen, empuñando una espada demoníaca alimentada con sacrificios de sangre— ¡Maten al Décimo! ¡Maten a todo aquel que no se postre!'},
          {'text': 'El Emperador, herido por un dardo envenenado que uno de sus concubinas traidoras le había clavado a traición, cayó de rodillas sobre los escalones del trono, escupiendo sangre negra.'},
          {'text': 'La corte entera se convirtió en un matadero de pánico y confusión. Príncipes y ministros huían como ganado acorralado.'},
          {'text': 'Solo Long Ze permaneció de pie en el centro de la masacre.'},
          {'text': '—Qué escena tan predecible —susurró con desdén.'},
          {'text': 'El Décimo Príncipe alzó la Alabarda del Dragón Oscuro hacia la luna roja.'},
          {'text': '—Sombra del Asura: Juicio de Sangre.', 'bold': true},
          {'text': 'Una erupción de energía carmesí brotó del suelo del palacio como geiseres de lava líquida. Cientos de soldados golpistas fueron elevados por los aires, sus almas y su fuerza vital absorbidas en un torbellino que alimentaba la fuerza de Long Ze.'},
          {'text': 'Long Ze avanzó a través del mar de soldados enemigos como un dios de la muerte cosechando trigo. Cada golpe de alabarda decapitaba oficiales, partía caballos de guerra por la mitad y pulverizaba las armaduras encantadas como si fueran cristal barato.'},
          {'text': 'En menos de diez minutos, los cinco mil rebeldes estaban aniquilados o huyendo en estampida.'},
          {'text': 'En los escalones del gran salón, el Tercer Príncipe Long Zhen se arrastraba de espaldas, con la espada rota y el rostro cubierto de lágrimas y orina:'},
          {'text': '—¡No... por favor! ¡Somos hermanos de sangre! ¡Tuvimos el mismo padre! ¡Ten piedad, hermano Ze!'},
          {'text': 'Long Ze se detuvo ante él. La punta goteante de la alabarda se posó sobre la garganta de Long Zhen:'},
          {'text': '—¿Hermanos? Cuando enviaste a Kuro al Pabellón del Bambú a degollar a un muchacho indefenso, no te acordaste de la sangre. Ahora... paga tu deuda.'},
          {'text': 'Un destello carmesí cruzó el aire. La cabeza del Tercer Príncipe rodó por los escalones de jade blanco, deteniéndose ante los pies de los ministros supervivientes que observaban mudos de terror.'},
          {'text': 'Long Ze subió lentamente los nueve escalones imperiales. Miró al agonizante Emperador, que lo observaba con ojos desorbitados:'},
          {'text': '—Tus nueve hijos eran basura cobarde o escoria ambiciosa, anciano. A partir de hoy, la dinastía Tianlong no se regirá por la debilidad de las palabras.'},
          {'text': 'Long Ze se dio la vuelta ante el salón cubierto de humo, fuego y sangre. Se sentó sobre el Trono del Dragón Dorado, apoyando la barbilla sobre el puño cerrado.'},
          {'text': 'Bajo el resplandor de la luna roja, una silueta colosal de un dios Asura de mil brazos se alzó majestuosa tras su trono.'},
          {'text': 'Todos los ministros, generales y soldados que quedaban vivos se arrodillaron al unísono, golpeando sus frentes contra el suelo hasta ensangrentarse:'},
          {'text': '—¡¡LARGA VIDA AL DÉCIMO PRÍNCIPE!! ¡¡LARGA VIDA AL TIRANO DE TIANLONG!!', 'bold': true},
        ]),
      },
    ];

    // Insertar los 10 capítulos en la base de datos
    for (int i = 0; i < capitulosData.length; i++) {
      final cap = capitulosData[i];
      final contenido = cap['contenido'] as String;
      final palabras = RegExp(r'\b\w+\b').allMatches(contenido).length;

      final capId = await db.insert('capitulos', {
        'manuscrito_id': manuscritoId,
        'titulo': cap['titulo'],
        'contenido': contenido,
        'orden': i,
        'tipo': 'capitulo',
        'palabras': palabras,
        'sinopsis': cap['sinopsis'],
        'pov_personaje_id': cap['pov'],
        'estado': cap['estado'],
        'meta_palabras': cap['meta_palabras'],
        'creado_en': DateTime.now().add(Duration(minutes: i)).toIso8601String(),
        'actualizado_en': DateTime.now().add(Duration(minutes: i)).toIso8601String(),
      });
      print('Capítulo ${i + 1} insertado con éxito: ID $capId, $palabras palabras, título: ${cap['titulo']}');
    }

    // Actualizar palabras totales del proyecto
    final capsCount = await db.rawQuery('SELECT COUNT(*) as total, SUM(palabras) as palabras FROM capitulos WHERE manuscrito_id = ?', [manuscritoId]);
    final totalCaps = capsCount.first['total'] as int;
    final totalWords = capsCount.first['palabras'] as int;
    print('\n=============================================');
    print('ÉXITO: Se han creado y poblado los $totalCaps capítulos completos.');
    print('Total de palabras de la novela: $totalWords palabras.');
    print('=============================================\n');

    await db.close();
  });
}
