import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';
import '../widgets/relations_graph_view.dart';
// --- PANTALLA DE DETALLE DEL PERSONAJE (CODEX) ---
class CharacterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> personaje;
  final List<Map<String, dynamic>> todosLosPersonajes;
  final VoidCallback onUpdate;

  const CharacterDetailScreen({
    super.key,
    required this.personaje,
    required this.todosLosPersonajes,
    required this.onUpdate,
  });

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  late Map<String, dynamic> _p;
  List<Map<String, dynamic>> _relaciones = [];
  late TextEditingController _nombreController;
  late TextEditingController _aliasController;
  late TextEditingController _fraseController;
  late TextEditingController _rolController;
  late TextEditingController _estadoController;
  late TextEditingController _emocionController;
  late TextEditingController _edadController;
  late TextEditingController _descripcionController;

  Map<String, String> _atributos = {};
  int _activeTab = 0; // 0: Perfil, 1: Apariencia, 2: Relaciones, 3: Timeline

  @override
  void initState() {
    super.initState();
    _p = Map<String, dynamic>.from(widget.personaje);
    _initControllers();
    _cargarRelaciones();
  }

  Future<void> _cargarRelaciones() async {
    final data = await AppDatabase.getRelacionesByPersonaje(_p['id']);
    setState(() => _relaciones = data);
  }

  void _initControllers() {
    _nombreController = TextEditingController(text: _p['nombre']);
    _aliasController = TextEditingController(text: _p['alias'] ?? '');
    _fraseController = TextEditingController(text: _p['frase_iconica'] ?? '');
    _rolController = TextEditingController(text: _p['rol'] ?? '');
    _estadoController = TextEditingController(text: _p['estado_actual'] ?? 'Activo');
    _emocionController = TextEditingController(text: _p['estado_emocional'] ?? 'Estable');
    _edadController = TextEditingController(text: _p['edad'] ?? '');
    _descripcionController = TextEditingController(text: _p['descripcion'] ?? '');

    if (_p['atributos'] != null) {
      try {
        _atributos = Map<String, String>.from(jsonDecode(_p['atributos']));
      } catch (_) {
        _atributos = {};
      }
    }
  }

  Future<void> _guardar() async {
    final data = {
      'nombre': _nombreController.text,
      'alias': _aliasController.text,
      'frase_iconica': _fraseController.text,
      'rol': _rolController.text,
      'estado_actual': _estadoController.text,
      'estado_emocional': _emocionController.text,
      'edad': _edadController.text,
      'descripcion': _descripcionController.text,
      'imagen_path': _p['imagen_path'],
      'atributos': jsonEncode(_atributos),
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    await AppDatabase.updatePersonaje(_p['id'], data);
    widget.onUpdate();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _p['imagen_path'] = result.files.single.path);
      _guardar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar Izquierda: Lista de Personajes
          _buildLeftSidebar(),

          // 2. Centro: Información Principal
          Expanded(
            flex: 5,
            child: _buildMainContent(),
          ),

          // 3. Sidebar Derecha: Relaciones y Extras
          _buildRightSidebar(),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.separator)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary),
            tooltip: 'Volver a personajes',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: widget.todosLosPersonajes.length,
              itemBuilder: (context, index) {
                final pj = widget.todosLosPersonajes[index];
                final isSelected = pj['id'] == _p['id'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _p = Map<String, dynamic>.from(pj);
                          _initControllers();
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.transparent,
                            width: 2,
                          ),
                          image: pj['imagen_path'] != null
                              ? DecorationImage(image: FileImage(File(pj['imagen_path'])), fit: BoxFit.cover)
                              : null,
                          color: AppColors.bg,
                        ),
                        child: pj['imagen_path'] == null
                            ? Icon(Icons.person, color: AppColors.textTertiary, size: 20)
                            : null,
                      ),
                      ),
                    ),
                  ),
                  );
                },
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO CINEMATOGRÁFICO
          _buildHeader(),
          const SizedBox(height: 48),

          // TABS DE NAVEGACIÓN INTERNA
          _buildTabNavigation(),
          const SizedBox(height: 32),

          // CONTENIDO DINÁMICO SEGÚN TAB
          Expanded(
            child: _buildTabView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Retrato Grande
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
          onTap: _pickImage,
          child: Hero(
            tag: 'pj_img_${_p['id']}',
            child: Container(
              width: 180,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 15))
                ],
                image: _p['imagen_path'] != null
                    ? DecorationImage(image: FileImage(File(_p['imagen_path'])), fit: BoxFit.cover)
                    : null,
                color: AppColors.bg,
              ),
              child: _p['imagen_path'] == null
                  ? Icon(Icons.add_a_photo_rounded, color: AppColors.textTertiary, size: 48)
                  : null,
            ),
          ),
        ),
        ),
        const SizedBox(width: 48),
        // Información de Texto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildEditableText(
                controller: _nombreController,
                style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -1),
                hint: 'Nombre del Personaje',
              ),
              _buildEditableText(
                controller: _fraseController,
                style: GoogleFonts.merriweather(fontSize: 18, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                hint: '“Una frase icónica que defina su alma...”',
                prefix: '“',
                suffix: '”',
              ),
              const SizedBox(height: 24),
              Divider(color: AppColors.separator.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildHeaderStat('ROL', _rolController, Icons.star_border_rounded),
                  _buildHeaderDivider(),
                  _buildHeaderStat('ESTADO', _estadoController, Icons.query_builder_rounded),
                  _buildHeaderDivider(),
                  _buildHeaderStat('EMOCIÓN', _emocionController, Icons.favorite_border_rounded),
                  _buildHeaderDivider(),
                  _buildHeaderStat('EDAD', _edadController, Icons.cake_outlined),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, TextEditingController controller, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            onChanged: (_) => _guardar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.separator,
    );
  }

  Widget _buildTabNavigation() {
    final tabs = ['PERFIL PSICOLÓGICO', 'APARIENCIA', 'RELACIONES', 'LÍNEA TEMPORAL'];
    return Row(
      children: tabs.asMap().entries.map((e) {
        final isSelected = _activeTab == e.key;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
          onTap: () => setState(() => _activeTab = e.key),
          child: Container(
            margin: const EdgeInsets.only(right: 32),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isSelected ? AppColors.accent : Colors.transparent, width: 2)),
            ),
            child: Text(
              e.value,
              style: GoogleFonts.outfit(
                color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            ),
          ),
        );
        }).toList(),
    );
  }

  Widget _buildTabView() {
    switch (_activeTab) {
      case 0: return _buildProfileTab();
      case 1: return _buildAppearanceTab();
      case 2: return _buildRelationshipsTab();
      default: return Center(child: Text('Sección en construcción...', style: TextStyle(color: AppColors.textTertiary)));
    }
  }

  Widget _buildRelationshipsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('RED DE VÍNCULOS'),
            OutlinedButton.icon(
              onPressed: _mostrarDialogoNuevaRelacion,
              icon: const Icon(Icons.hub_rounded, size: 18),
              label: const Text('NUEVO VÍNCULO'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: _relaciones.isEmpty
              ? Center(child: Text('Aún no hay relaciones definidas para este personaje.', style: GoogleFonts.outfit(color: AppColors.textTertiary)))
              : ListView.builder(
                  itemCount: _relaciones.length,
                  itemBuilder: (context, index) {
                    final rel = _relaciones[index];
                    return _buildRelacionItem(rel);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRelacionItem(Map<String, dynamic> rel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.separator),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: rel['imagen_otro'] != null
                  ? DecorationImage(image: FileImage(File(rel['imagen_otro'])), fit: BoxFit.cover)
                  : null,
              color: AppColors.bg,
            ),
            child: rel['imagen_otro'] == null ? Icon(Icons.person, color: AppColors.textTertiary) : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rel['nombre_otro'], style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(rel['tipo'].toUpperCase(), style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('INTENSIDAD EMOCIONAL', style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('${rel['intensidad']}%', style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rel['intensidad'] / 100,
                    backgroundColor: AppColors.separator.withValues(alpha: 0.3),
                    color: _getColorForIntensidad(rel['intensidad']),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary),
            tooltip: 'Eliminar vínculo',
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Eliminar Vínculo',
                message: '¿Estás seguro de eliminar la relación con "${rel['nombre_otro']}"?',
                confirmLabel: 'ELIMINAR',
              );
              if (!confirm) return;
              await AppDatabase.deleteRelacion(rel['id']);
              _cargarRelaciones();
            },
          ),
        ],
      ),
    );
  }

  Color _getColorForIntensidad(int value) {
    if (value > 80) return Colors.redAccent;
    if (value > 50) return AppColors.accent;
    return Colors.blueAccent;
  }

  void _mostrarDialogoNuevaRelacion() {
    // Filtrar para no relacionarse consigo mismo
    final otros = widget.todosLosPersonajes.where((pj) => pj['id'] != _p['id']).toList();
    
    if (otros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas al menos otro personaje para crear una relación.'))
      );
      return;
    }

    int? seleccionadoId;
    String tipo = 'Aliado';
    double intensidad = 50;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Vincular con...', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<int>(
                value: seleccionadoId,
                hint: 'Seleccionar...',
                items: otros.map((pj) => AppDropdownItem<int>(
                  value: pj['id'] as int,
                  label: pj['nombre'],
                )).toList(),
                onChanged: (v) => seleccionadoId = v,
              ),
              const SizedBox(height: 16),
              TextField(
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: 'Tipo de Relación (ej: Rivalidad)', labelStyle: TextStyle(color: AppColors.textSecondary)),
                onChanged: (v) => tipo = v,
              ),
              const SizedBox(height: 24),
              Text('Intensidad Emocional: ${intensidad.toInt()}%', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Slider(
                value: intensidad,
                min: 0,
                max: 100,
                activeColor: AppColors.accent,
                onChanged: (v) => setDialogState(() => intensidad = v),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
              child: const Text('CANCELAR'),
            ),
            OutlinedButton(
              onPressed: () async {
                if (seleccionadoId != null) {
                  await AppDatabase.insertRelacion({
                    'personaje_a_id': _p['id'],
                    'personaje_b_id': seleccionadoId,
                    'tipo': tipo,
                    'intensidad': intensidad.toInt(),
                  });
                  _cargarRelaciones();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('VINCULAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('BIOGRAFÍA NARRATIVA'),
          const SizedBox(height: 16),
          TextField(
            controller: _descripcionController,
            maxLines: null,
            style: GoogleFonts.merriweather(color: AppColors.textSecondary, fontSize: 16, height: 1.8),
            decoration: InputDecoration(border: InputBorder.none, hintText: 'Comienza a escribir la historia de este personaje...', hintStyle: TextStyle(color: AppColors.textTertiary)),
            onChanged: (_) => _guardar(),
          ),
          const SizedBox(height: 48),
          _buildSectionTitle('RASGOS PSICOLÓGICOS'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildPsychCard('DESEO', '¿Qué es lo que más anhela?', Icons.north_east_rounded),
              _buildPsychCard('MIEDO', '¿Cuál es su mayor terror?', Icons.south_west_rounded),
              _buildPsychCard('CONTRADICCIÓN', '¿Qué lucha interna libra?', Icons.sync_problem_rounded),
              _buildPsychCard('FILOSOFÍA', '¿En qué cree profundamente?', Icons.auto_awesome_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPsychCard(String title, String hint, IconData icon) {
    final value = _atributos[title] ?? '';
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 2,
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
            controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
            onChanged: (v) {
              _atributos[title] = v;
              _guardar();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DESCRIPCIÓN FÍSICA'),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildAppearanceField('ALTURA', 'altura'),
            _buildAppearanceField('COMPLEXIÓN', 'complexion'),
            _buildAppearanceField('OJOS', 'ojos'),
            _buildAppearanceField('CABELLO', 'cabello'),
            _buildAppearanceField('VESTIMENTA', 'ropa'),
            _buildAppearanceField('MARCAS', 'marcas'),
          ],
        ),
      ],
    );
  }

  Widget _buildAppearanceField(String label, String key) {
    final value = _atributos[key] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.separator),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.bold)),
          TextField(
            controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            onChanged: (v) {
              _atributos[key] = v;
              _guardar();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(left: BorderSide(color: AppColors.separator)),
      ),
      child: Column(
        children: [
          _buildRightSidebarSection('RELACIONES DINÁMICAS', Icons.hub_rounded),
          Expanded(
            flex: 2,
            child: _buildRelacionesGraph(),
          ),
          _buildRightSidebarSection('LÍNEA DE TIEMPO', Icons.timeline_rounded),
          Expanded(
            child: _buildTimelinePreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelacionesGraph() {
    if (_relaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hub_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Sin conexiones aún', style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _relaciones.length,
      itemBuilder: (context, index) {
        final rel = _relaciones[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: rel['imagen_otro'] != null
                      ? DecorationImage(image: FileImage(File(rel['imagen_otro'])), fit: BoxFit.cover)
                      : null,
                  color: AppColors.bg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rel['nombre_otro'], style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(rel['tipo'], style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 10)),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _getColorForIntensidad(rel['intensidad']).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelinePreview() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildTimelineItem('Nacimiento', 'Hace 24 años'),
        _buildTimelineItem('Tragedia Familiar', 'Capítulo 12'),
        _buildTimelineItem('Exilio', 'Capítulo 34'),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(time, style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebarSection(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2));
  }

  Widget _buildEditableText({required TextEditingController controller, required TextStyle style, required String hint, String prefix = '', String suffix = ''}) {
    return TextField(
      controller: controller,
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(color: AppColors.textTertiary),
        border: InputBorder.none,
        isDense: true,
        prefixText: prefix,
        suffixText: suffix,
      ),
      onChanged: (_) => _guardar(),
    );
  }
}

// --- VISTA PRINCIPAL DE PERSONAJES ---
class CharactersView extends StatefulWidget {
  final int proyectoId;
  const CharactersView({super.key, required this.proyectoId});

  @override
  State<CharactersView> createState() => _CharactersViewState();
}

class _CharactersViewState extends State<CharactersView> {
  List<Map<String, dynamic>> _personajes = [];
  List<Map<String, dynamic>> _relacionesProyecto = [];
  bool _isLoading = true;
  bool _showNetworkMap = false;
  int? _selectedPersonajeId;
  int? _firstSelectedId;

  @override
  void initState() {
    super.initState();
    _cargarPersonajes();
  }

  Future<void> _cargarPersonajes() async {
    setState(() => _isLoading = true);
    final data = await AppDatabase.getPersonajesByProyecto(widget.proyectoId);
    
    // Cargar todas las relaciones del proyecto
    final db = await AppDatabase.database;
    final rels = await db.rawQuery('''
      SELECT r.*, p1.nombre as nombre_a, p2.nombre as nombre_b 
      FROM relaciones_personajes r
      JOIN personajes p1 ON r.personaje_a_id = p1.id
      JOIN personajes p2 ON r.personaje_b_id = p2.id
      WHERE p1.proyecto_id = ? AND p2.proyecto_id = ?
    ''', [widget.proyectoId, widget.proyectoId]);

    setState(() {
      _personajes = data;
      _relacionesProyecto = List<Map<String, dynamic>>.from(rels);
      _isLoading = false;
    });
  }

  Future<void> _eliminarPersonaje(int id) async {
    final nombre = _personajes.firstWhere((p) => p['id'] == id)['nombre'] ?? 'este personaje';
    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar Personaje',
      message: '¿Estás seguro de eliminar a "$nombre"? Se perderán todos sus datos y relaciones.',
      confirmLabel: 'ELIMINAR',
    );
    if (!confirm) return;
    await AppDatabase.deletePersonaje(id);
    _cargarPersonajes();
  }

  void _onNodeTap(int id) {
    if (_firstSelectedId == null) {
      setState(() {
        _firstSelectedId = id;
        _selectedPersonajeId = id;
      });
    } else if (_firstSelectedId == id) {
      setState(() {
        _firstSelectedId = null;
        _selectedPersonajeId = null;
      });
    } else {
      final idA = _firstSelectedId!;
      final idB = id;
      setState(() {
        _firstSelectedId = null;
        _selectedPersonajeId = null;
      });
      _mostrarDialogoCrearRelacionRapida(idA, idB);
    }
  }

  void _mostrarDialogoCrearRelacionRapida(int idA, int idB) {
    final pjA = _personajes.firstWhere((p) => p['id'] == idA);
    final pjB = _personajes.firstWhere((p) => p['id'] == idB);

    String tipo = 'Aliado';
    double intensidad = 50;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Crear Vínculo',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relación entre ${pjA['nombre']} y ${pjB['nombre']}',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Tipo de Relación',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  hintText: 'ej: Enemigos, Romance, Mentor',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => tipo = v,
              ),
              const SizedBox(height: 24),
              Text(
                'Intensidad Emocional: ${intensidad.toInt()}%',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
              ),
              Slider(
                value: intensidad,
                min: 0,
                max: 100,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.separator,
                onChanged: (v) => setDialogState(() => intensidad = v),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
              child: Text('CANCELAR', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            OutlinedButton(
              onPressed: () async {
                await AppDatabase.insertRelacion({
                  'personaje_a_id': idA,
                  'personaje_b_id': idB,
                  'tipo': tipo.trim().isEmpty ? 'Aliado' : tipo.trim(),
                  'intensidad': intensidad.toInt(),
                });
                _cargarPersonajes();
                Navigator.pop(ctx);
              },
              child: Text('CREAR VÍNCULO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkMap() {
    if (_personajes.isEmpty) {
      return Center(
        child: Text(
          'Necesitas personajes para ver su red de vínculos.',
          style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 16),
        ),
      );
    }

    return RelationsGraphView(
      personajes: _personajes,
      relaciones: _relacionesProyecto,
      selectedPersonajeId: _selectedPersonajeId,
      firstSelectedId: _firstSelectedId,
      onNodeTap: _onNodeTap,
      onNodeDoubleTap: (id) {
        final pj = _personajes.firstWhere((p) => p['id'] == id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CharacterDetailScreen(
              personaje: pj,
              todosLosPersonajes: _personajes,
              onUpdate: _cargarPersonajes,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoCreacion(),
        icon: const Icon(Icons.person_add_rounded, size: 18),
        label: Text('NUEVO PERSONAJE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personajes',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showNetworkMap
                          ? 'Visualiza la red social y emocional de tus personajes. Selecciona dos para conectarlos.'
                          : 'Gestiona el elenco de tu historia. Haz clic en una cartilla para entrar al Codex.',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                
                // Toggle de Galería vs Red de Vínculos
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                        onTap: () => setState(() {
                          _showNetworkMap = false;
                          _firstSelectedId = null;
                          _selectedPersonajeId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_showNetworkMap
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_showNetworkMap ? AppColors.accent : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: !_showNetworkMap ? AppColors.accent : Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Galería',
                                style: GoogleFonts.outfit(
                                  fontWeight: !_showNetworkMap ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                  color: !_showNetworkMap ? AppColors.accent : Colors.white54,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                        onTap: () => setState(() => _showNetworkMap = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _showNetworkMap
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showNetworkMap ? AppColors.accent : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.hub_rounded,
                                size: 16,
                                color: _showNetworkMap ? AppColors.accent : Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Red de Vínculos',
                                style: GoogleFonts.outfit(
                                  fontWeight: _showNetworkMap ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                  color: _showNetworkMap ? AppColors.accent : Colors.white54,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _showNetworkMap
                  ? _buildNetworkMap()
                  : (_personajes.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisExtent: 360,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: _personajes.length,
                          itemBuilder: (context, index) => _CharacterCard(
                            personaje: _personajes[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CharacterDetailScreen(
                                  personaje: _personajes[index],
                                  todosLosPersonajes: _personajes,
                                  onUpdate: _cargarPersonajes,
                                ),
                              ),
                            ),
                            onDelete: () => _eliminarPersonaje(_personajes[index]['id']),
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return buildEmptyState(
      icon: Icons.people_outline_rounded,
      title: 'Aún no tienes personajes registrados.',
      subtitle: 'Crea tu primer personaje para poblar tu mundo narrativo.',
      actionLabel: 'CREAR PRIMER PERSONAJE',
      onAction: () => _mostrarDialogoCreacion(),
    );
  }

  void _mostrarDialogoCreacion() {
    showDialog(
      context: context,
      builder: (context) => _SimpleCreationDialog(
        proyectoId: widget.proyectoId,
        onSaved: _cargarPersonajes,
      ),
    );
  }
}

class _CharacterCard extends StatefulWidget {
  final Map<String, dynamic> personaje;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.personaje,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: _isHovered ? (Matrix4.translationValues(0.0, -8.0, 0.0) * Matrix4.diagonal3Values(1.02, 1.02, 1.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? AppColors.accent.withValues(alpha: 0.4) : AppColors.separator,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? AppColors.accent.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
              blurRadius: _isHovered ? 25 : 15,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: _isHovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          widget.personaje['imagen_path'] != null && File(widget.personaje['imagen_path']).existsSync()
                              ? Hero(
                                  tag: 'pj_img_${widget.personaje['id']}',
                                  child: Image.file(
                                    File(widget.personaje['imagen_path']),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 64,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                          tooltip: 'Eliminar personaje',
                          onPressed: widget.onDelete,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.personaje['nombre'] ?? 'Sin nombre',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (widget.personaje['rol'] ?? 'Sin rol definido').toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleCreationDialog extends StatefulWidget {
  final int proyectoId;
  final VoidCallback onSaved;

  const _SimpleCreationDialog({required this.proyectoId, required this.onSaved});

  @override
  State<_SimpleCreationDialog> createState() => _SimpleCreationDialogState();
}

class _SimpleCreationDialogState extends State<_SimpleCreationDialog> {
  final _nombreController = TextEditingController();
  String? _imagenPath;
  String? _nameError;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) setState(() => _imagenPath = result.files.single.path);
  }

  void _validate() {
    setState(() {
      _nameError = _nombreController.text.trim().isEmpty ? 'El nombre es obligatorio' : null;
    });
  }

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_validate);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_validate);
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Nuevo Personaje', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.bg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.separator),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imagenPath != null ? Image.file(File(_imagenPath!), fit: BoxFit.cover) : Icon(Icons.add_a_photo_rounded, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _nameError != null ? AppColors.red : AppColors.separator,
                  ),
                ),
                child: TextField(
                  controller: _nombreController,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nombre del personaje *',
                    labelStyle: TextStyle(color: _nameError != null ? AppColors.red : AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_nameError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 6),
                  child: Text(
                    _nameError!,
                    style: GoogleFonts.outfit(color: AppColors.red, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textTertiary, side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3))),
          child: const Text('CANCELAR'),
        ),
        OutlinedButton(
          onPressed: () async {
            _validate();
            if (_nombreController.text.trim().isNotEmpty) {
              await AppDatabase.insertPersonaje({
                'proyecto_id': widget.proyectoId,
                'nombre': _nombreController.text.trim(),
                'imagen_path': _imagenPath,
                'rol': 'Personaje',
                'estado_actual': 'Activo',
                'estado_emocional': 'Estable',
                'creado_en': DateTime.now().toIso8601String(),
                'actualizado_en': DateTime.now().toIso8601String(),
              });
              widget.onSaved();
              Navigator.pop(context);
            }
          },
          child: const Text('CREAR'),
        ),
      ],
    );
  }
}

// ── CUSTOM PAINTER DE RELACIONES DE PERSONAJES ────────────────
class CharacterRelationsPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final List<Map<String, dynamic>> relaciones;
  final int? selectedId;

  CharacterRelationsPainter({
    required this.positions,
    required this.relaciones,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final rel in relaciones) {
      final idA = rel['personaje_a_id'];
      final idB = rel['personaje_b_id'];

      final posA = positions[idA];
      final posB = positions[idB];

      if (posA != null && posB != null) {
        // Determinar opacidad si hay selección
        bool isRelatedToSelected = selectedId == null || idA == selectedId || idB == selectedId;
        double opacity = isRelatedToSelected ? 0.85 : 0.15;

        // Determinar color por tipo de relación
        final tipo = (rel['tipo'] as String? ?? '').toLowerCase();
        Color lineColor;
        if (tipo.contains('rival') || tipo.contains('enem') || tipo.contains('odio') || tipo.contains('contra')) {
          lineColor = Colors.redAccent.withValues(alpha: opacity);
        } else if (tipo.contains('amor') || tipo.contains('romance') || tipo.contains('pareja') || tipo.contains('espos') || tipo.contains('novi')) {
          lineColor = Colors.pinkAccent.withValues(alpha: opacity);
        } else if (tipo.contains('ami') || tipo.contains('alia') || tipo.contains('famil') || tipo.contains('herman')) {
          lineColor = Colors.greenAccent.withValues(alpha: opacity);
        } else {
          lineColor = AppColors.accent.withValues(alpha: opacity);
        }

        // Determinar grosor por intensidad (1 a 100)
        final intensidad = rel['intensidad'] as int? ?? 50;
        final double strokeWidth = (intensidad / 100 * 5.0).clamp(1.5, 6.0);

        final paint = Paint()
          ..color = lineColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        // Curvar la línea: calcular el vector perpendicular al segmento
        final dx = posB.dx - posA.dx;
        final dy = posB.dy - posA.dy;
        final double distance = sqrt(dx * dx + dy * dy);
        
        if (distance > 0) {
          final path = Path();
          path.moveTo(posA.dx, posA.dy);
          
          // La curvatura depende de si hay un ID seleccionado
          final double curvature = 35.0 * (selectedId == null ? 0.5 : 1.0);
          final nx = -dy / distance;
          final ny = dx / distance;
          
          final controlX = (posA.dx + posB.dx) / 2 + nx * curvature;
          final controlY = (posA.dy + posB.dy) / 2 + ny * curvature;
          
          path.quadraticBezierTo(controlX, controlY, posB.dx, posB.dy);
          canvas.drawPath(path, paint);

          // Si es relevante, pintar el label en el punto de control
          if (isRelatedToSelected && selectedId != null) {
            final labelPos = Offset(controlX, controlY);
            _drawTextLabel(canvas, labelPos, '${rel['tipo']} (${rel['intensidad']}%)', lineColor);
          }
        } else {
          canvas.drawLine(posA, posB, paint);
        }
      }
    }
  }

  void _drawTextLabel(Canvas canvas, Offset position, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgPaint = Paint()
      ..color = AppColors.bg
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CharacterRelationsPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId ||
        oldDelegate.relaciones != relaciones ||
        oldDelegate.positions != positions;
  }
}
