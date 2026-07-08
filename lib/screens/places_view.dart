import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';

class PlacesView extends StatefulWidget {
  final int proyectoId;

  const PlacesView({super.key, required this.proyectoId});

  @override
  State<PlacesView> createState() => _PlacesViewState();
}

class _PlacesViewState extends State<PlacesView> {
  static const _placeAccent = Color(0xFF7DD3A8);
  static const _placeWarm = Color(0xFFF2B36D);
  static const _placeWater = Color(0xFF60A5FA);
  static const _attributeKeys = [
    'ATMÓSFERA',
    'PUNTOS DE INTERÉS',
    'HISTORIA',
    'SECRETOS',
  ];

  static const _importanceItems = [
    AppDropdownItem<String>(
      value: 'Principal',
      label: 'Principal',
      icon: Icons.star_rounded,
      color: _placeWarm,
    ),
    AppDropdownItem<String>(
      value: 'Secundario',
      label: 'Secundario',
      icon: Icons.place_rounded,
      color: _placeAccent,
    ),
    AppDropdownItem<String>(
      value: 'Ambiental',
      label: 'Ambiental',
      icon: Icons.grass_rounded,
      color: _placeWater,
    ),
  ];

  List<Map<String, dynamic>> _lugares = [];
  Map<String, dynamic>? _selectedLugar;
  bool _isLoading = true;
  Timer? _saveDebounce;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _climaController = TextEditingController();
  final TextEditingController _poblacionController = TextEditingController();
  final Map<String, TextEditingController> _attributeControllers = {
    for (final key in _attributeKeys) key: TextEditingController(),
  };

  Map<String, String> _atributos = {};

  @override
  void initState() {
    super.initState();
    _cargarLugares();
  }

  @override
  void dispose() {
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce?.cancel();
      _guardar();
    }
    _nombreController.dispose();
    _descripcionController.dispose();
    _climaController.dispose();
    _poblacionController.dispose();
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarLugares() async {
    final data = await AppDatabase.getLugaresByProyecto(widget.proyectoId);
    if (!mounted) return;

    Map<String, dynamic>? lugarSeleccionado;
    final selectedId = _selectedLugar?['id'];
    if (selectedId != null) {
      for (final lugar in data) {
        if (lugar['id'] == selectedId) {
          lugarSeleccionado = lugar;
          break;
        }
      }
    }
    if (lugarSeleccionado == null && data.isNotEmpty) {
      lugarSeleccionado = data.first;
    }

    setState(() {
      _lugares = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
      if (lugarSeleccionado == null) {
        _clearSelection();
      } else {
        _setSelectedLugarData(lugarSeleccionado);
      }
    });
  }

  void _clearSelection() {
    _selectedLugar = null;
    _nombreController.clear();
    _descripcionController.clear();
    _climaController.clear();
    _poblacionController.clear();
    _atributos = {};
    for (final controller in _attributeControllers.values) {
      controller.clear();
    }
  }

  void _setSelectedLugarData(Map<String, dynamic> lugar) {
    _selectedLugar = Map<String, dynamic>.from(lugar);
    _nombreController.text = _fieldValue('nombre');
    _descripcionController.text = _fieldValue('descripcion');
    _climaController.text = _fieldValue('clima');
    _poblacionController.text = _fieldValue('poblacion');
    _atributos = _parseAttributes(_selectedLugar?['atributos']);

    for (final key in _attributeKeys) {
      _attributeControllers[key]?.text = _atributos[key] ?? '';
    }
  }

  String _fieldValue(String key) => _selectedLugar?[key]?.toString() ?? '';

  Map<String, String> _parseAttributes(dynamic rawAttributes) {
    if (rawAttributes == null || rawAttributes.toString().trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawAttributes.toString());
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _seleccionarLugar(Map<String, dynamic> lugar) async {
    await _flushPendingSave();
    if (!mounted) return;
    setState(() => _setSelectedLugarData(lugar));
  }

  Future<void> _agregarLugar() async {
    await _flushPendingSave();

    final id = await AppDatabase.insertLugar({
      'proyecto_id': widget.proyectoId,
      'nombre': 'Nuevo Lugar',
      'descripcion': '',
      'clima': '',
      'poblacion': '',
      'importancia': 'Secundario',
      'atributos': jsonEncode({}),
    });

    final data = await AppDatabase.getLugaresByProyecto(widget.proyectoId);
    if (!mounted) return;

    Map<String, dynamic>? created;
    for (final lugar in data) {
      if (lugar['id'] == id) {
        created = lugar;
        break;
      }
    }

    setState(() {
      _lugares = List<Map<String, dynamic>>.from(data);
      if (created != null) _setSelectedLugarData(created);
    });
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 550), _guardar);
  }

  Future<void> _flushPendingSave() async {
    if (!(_saveDebounce?.isActive ?? false)) return;
    _saveDebounce?.cancel();
    await _guardar();
  }

  Future<void> _guardar() async {
    final lugar = _selectedLugar;
    if (lugar == null) return;

    final data = {
      'nombre': _nombreController.text.trim().isEmpty
          ? 'Lugar sin nombre'
          : _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'clima': _climaController.text.trim(),
      'poblacion': _poblacionController.text.trim(),
      'importancia': lugar['importancia'] ?? 'Secundario',
      'imagen_path': lugar['imagen_path'],
      'atributos': jsonEncode(_atributos),
      'actualizado_en': DateTime.now().toIso8601String(),
    };

    await AppDatabase.updateLugar(lugar['id'] as int, data);
  }

  void _updateLugarField(String field, String value) {
    final lugar = _selectedLugar;
    if (lugar == null) return;

    setState(() {
      lugar[field] = value;
      final index = _lugares.indexWhere((item) => item['id'] == lugar['id']);
      if (index != -1) {
        _lugares[index] = {..._lugares[index], field: value};
      }
    });
    _scheduleSave();
  }

  void _updateAttribute(String key, String value) {
    _atributos[key] = value;
    _scheduleSave();
  }

  Future<void> _eliminarLugar() async {
    final lugar = _selectedLugar;
    if (lugar == null) return;

    final confirm = await showConfirmDialog(
      context,
      title: 'Eliminar lugar',
      message: 'Esta acción borrará toda la información del lugar.',
      confirmColor: AppColors.red,
    );

    if (confirm) {
      _saveDebounce?.cancel();
      await AppDatabase.deleteLugar(lugar['id'] as int);
      if (!mounted) return;
      _clearSelection();
      await _cargarLugares();
    }
  }

  Future<void> _pickImage() async {
    final lugar = _selectedLugar;
    if (lugar == null) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final imagePath = result?.files.single.path;
    if (imagePath == null) return;

    setState(() {
      lugar['imagen_path'] = imagePath;
      final index = _lugares.indexWhere((item) => item['id'] == lugar['id']);
      if (index != -1) {
        _lugares[index] = {..._lugares[index], 'imagen_path': imagePath};
      }
    });
    await _guardar();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return buildLoadingIndicator();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedLugar == null
                  ? _buildEmptyState()
                  : _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 296,
      decoration: BoxDecoration(
        color: AppColors.navSurface,
        border: Border(right: BorderSide(color: AppColors.separator)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _placeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _placeAccent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: _placeAccent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atlas',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_lugares.length} lugares',
                        style: GoogleFonts.outfit(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _agregarLugar,
                  icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                  color: _placeAccent,
                  tooltip: 'Nuevo lugar',
                  style: IconButton.styleFrom(
                    backgroundColor: _placeAccent.withValues(alpha: 0.10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.separator, height: 1),
          Expanded(
            child: _lugares.isEmpty
                ? _buildSidebarEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _lugares.length,
                    itemBuilder: (context, index) {
                      final lugar = _lugares[index];
                      final isSelected =
                          _selectedLugar != null &&
                          lugar['id'] == _selectedLugar!['id'];
                      return _PlaceSidebarItem(
                        name: lugar['nombre']?.toString() ?? 'Lugar sin nombre',
                        importance:
                            lugar['importancia']?.toString() ?? 'Secundario',
                        imagePath: lugar['imagen_path']?.toString(),
                        isSelected: isSelected,
                        onTap: () => _seleccionarLugar(lugar),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarEmpty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 44,
            color: AppColors.textTertiary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            'Aún no hay lugares.',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return buildEmptyState(
      icon: Icons.explore_outlined,
      title: 'Tu mundo está esperando ser explorado.',
      subtitle:
          'Crea un lugar para guardar clima, población, secretos y rasgos narrativos.',
      actionLabel: 'CREAR PRIMER LUGAR',
      onAction: _agregarLugar,
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 28 : 44,
            34,
            isCompact ? 28 : 44,
            42,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isCompact: isCompact),
                const SizedBox(height: 34),
                _buildDetailSections(isCompact: isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final headerDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildNameField()),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _eliminarLugar,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.textTertiary,
              tooltip: 'Eliminar lugar',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.separator),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _buildInfoField(
              label: 'Clima',
              controller: _climaController,
              icon: Icons.wb_sunny_outlined,
              hint: 'Templado, lluvioso...',
              width: 210,
              onChanged: (value) => _updateLugarField('clima', value),
            ),
            _buildInfoField(
              label: 'Población',
              controller: _poblacionController,
              icon: Icons.groups_2_outlined,
              hint: 'Habitantes o escala',
              width: 230,
              onChanged: (value) => _updateLugarField('poblacion', value),
            ),
            _buildImportanceDropdown(),
          ],
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlaceImagePicker(
            imagePath: _selectedLugar?['imagen_path']?.toString(),
            onTap: _pickImage,
          ),
          const SizedBox(height: 24),
          headerDetails,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlaceImagePicker(
          imagePath: _selectedLugar?['imagen_path']?.toString(),
          onTap: _pickImage,
        ),
        const SizedBox(width: 34),
        Expanded(child: headerDetails),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nombreController,
      style: GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Nombre del lugar',
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textTertiary.withValues(alpha: 0.55),
          fontWeight: FontWeight.w700,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
      textInputAction: TextInputAction.next,
      onChanged: (value) => _updateLugarField('nombre', value),
      onEditingComplete: _flushPendingSave,
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required double width,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, size: 18),
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
            textInputAction: TextInputAction.next,
            onChanged: onChanged,
            onEditingComplete: _flushPendingSave,
          ),
        ],
      ),
    );
  }

  Widget _buildImportanceDropdown() {
    final rawValue = _selectedLugar?['importancia']?.toString();
    final value = _importanceItems.any((item) => item.value == rawValue)
        ? rawValue
        : 'Secundario';

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Importancia'),
          const SizedBox(height: 8),
          AppDropdown<String>(
            value: value,
            width: 220,
            items: _importanceItems,
            onChanged: (newValue) {
              if (newValue == null) return;
              _updateLugarField('importancia', newValue);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSections({required bool isCompact}) {
    final description = _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.auto_stories_outlined,
            title: 'Crónica y descripción',
            accent: _placeAccent,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _descripcionController,
            minLines: 12,
            maxLines: null,
            style: GoogleFonts.merriweather(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.8,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describe la geografía, arquitectura, ánimo social y detalles sensoriales de este lugar...',
              hintStyle: GoogleFonts.merriweather(
                color: AppColors.textTertiary.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.6,
              ),
              filled: true,
              fillColor: AppColors.bg,
              alignLabelWithHint: true,
            ),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: (value) => _updateLugarField('descripcion', value),
          ),
        ],
      ),
    );

    final attributes = _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.tune_rounded,
            title: 'Rasgos distintivos',
            accent: _placeWarm,
          ),
          const SizedBox(height: 18),
          _buildAttributeCard(
            title: 'ATMÓSFERA',
            hint: 'Qué se siente al estar aquí',
            icon: Icons.air_rounded,
          ),
          _buildAttributeCard(
            title: 'PUNTOS DE INTERÉS',
            hint: 'Hitos, tabernas, templos, rutas...',
            icon: Icons.signpost_outlined,
          ),
          _buildAttributeCard(
            title: 'HISTORIA',
            hint: 'Pasado relevante o memoria colectiva',
            icon: Icons.history_edu_outlined,
          ),
          _buildAttributeCard(
            title: 'SECRETOS',
            hint: 'Lo que no todos saben',
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        children: [description, const SizedBox(height: 20), attributes],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: description),
        const SizedBox(width: 22),
        Expanded(flex: 2, child: attributes),
      ],
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.separator),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withValues(alpha: 0.24)),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeCard({
    required String title,
    required String hint,
    required IconData icon,
  }) {
    final controller = _attributeControllers[title]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: null,
        style: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        decoration: InputDecoration(
          labelText: title,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Icon(icon, size: 18),
          ),
          alignLabelWithHint: true,
          filled: true,
          fillColor: AppColors.bg,
        ),
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onChanged: (value) => _updateAttribute(title, value),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _PlaceSidebarItem extends StatefulWidget {
  final String name;
  final String importance;
  final String? imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlaceSidebarItem({
    required this.name,
    required this.importance,
    this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PlaceSidebarItem> createState() => _PlaceSidebarItemState();
}

class _PlaceSidebarItemState extends State<_PlaceSidebarItem> {
  bool _isHovered = false;

  Color get _importanceColor {
    switch (widget.importance) {
      case 'Principal':
        return _PlacesViewState._placeWarm;
      case 'Ambiental':
        return _PlacesViewState._placeWater;
      default:
        return _PlacesViewState._placeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final hasImage = imagePath != null && File(imagePath).existsSync();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _importanceColor.withValues(alpha: 0.11)
                : _isHovered
                ? AppColors.surface.withValues(alpha: 0.70)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? _importanceColor.withValues(alpha: 0.38)
                  : _isHovered
                  ? AppColors.separator
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: _importanceColor.withValues(alpha: 0.13),
                  border: Border.all(
                    color: _importanceColor.withValues(alpha: 0.22),
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(imagePath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : Icon(
                        Icons.landscape_rounded,
                        color: _importanceColor,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name.trim().isEmpty
                          ? 'Lugar sin nombre'
                          : widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: widget.isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _importanceColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            widget.importance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceImagePicker extends StatefulWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _PlaceImagePicker({this.imagePath, required this.onTap});

  @override
  State<_PlaceImagePicker> createState() => _PlaceImagePickerState();
}

class _PlaceImagePickerState extends State<_PlaceImagePicker> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final hasImage = imagePath != null && File(imagePath).existsSync();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 210,
          height: 210,
          transformAlignment: Alignment.center,
          transform: _isHovered
              ? Matrix4.diagonal3Values(1.015, 1.015, 1.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.surface,
            border: Border.all(
              color: _isHovered
                  ? _PlacesViewState._placeAccent.withValues(alpha: 0.7)
                  : AppColors.separator,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _PlacesViewState._placeAccent.withValues(
                  alpha: _isHovered ? 0.13 : 0.05,
                ),
                blurRadius: _isHovered ? 26 : 18,
                offset: const Offset(0, 12),
              ),
            ],
            image: hasImage
                ? DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (!hasImage)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _PlacesViewState._placeAccent.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: _PlacesViewState._placeAccent,
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Añadir imagen',
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Container(
                  color: Colors.black.withValues(alpha: hasImage ? 0.48 : 0.08),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bg.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.separator),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_camera_back_rounded,
                            color: _PlacesViewState._placeAccent,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasImage ? 'Cambiar imagen' : 'Elegir imagen',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
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
