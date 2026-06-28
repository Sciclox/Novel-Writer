import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../database/app_database.dart';


class PlacesView extends StatefulWidget {
  final int proyectoId;

  const PlacesView({super.key, required this.proyectoId});

  @override
  State<PlacesView> createState() => _PlacesViewState();
}

class _PlacesViewState extends State<PlacesView> {
  List<Map<String, dynamic>> _lugares = [];
  Map<String, dynamic>? _selectedLugar;
  bool _isLoading = true;

  // Controllers for editing
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _climaController = TextEditingController();
  final TextEditingController _poblacionController = TextEditingController();
  Map<String, String> _atributos = {};

  @override
  void initState() {
    super.initState();
    _cargarLugares();
  }

  Future<void> _cargarLugares() async {
    final data = await AppDatabase.getLugaresByProyecto(widget.proyectoId);
    setState(() {
      _lugares = data;
      _isLoading = false;
      if (_selectedLugar == null && _lugares.isNotEmpty) {
        _seleccionarLugar(_lugares.first);
      }
    });
  }

  void _seleccionarLugar(Map<String, dynamic> lugar) {
    setState(() {
      _selectedLugar = Map<String, dynamic>.from(lugar);
      _nombreController.text = _selectedLugar!['nombre'] ?? '';
      _descripcionController.text = _selectedLugar!['descripcion'] ?? '';
      _climaController.text = _selectedLugar!['clima'] ?? '';
      _poblacionController.text = _selectedLugar!['poblacion'] ?? '';
      
      if (_selectedLugar!['atributos'] != null) {
        try {
          _atributos = Map<String, String>.from(jsonDecode(_selectedLugar!['atributos']));
        } catch (_) {
          _atributos = {};
        }
      } else {
        _atributos = {};
      }
    });
  }

  Future<void> _agregarLugar() async {
    final nuevo = {
      'proyecto_id': widget.proyectoId,
      'nombre': 'Nuevo Lugar',
      'descripcion': '',
      'clima': '',
      'poblacion': '',
      'importancia': 'Secundario',
      'atributos': jsonEncode({}),
    };
    final id = await AppDatabase.insertLugar(nuevo);
    await _cargarLugares();
    final created = _lugares.firstWhere((l) => l['id'] == id);
    _seleccionarLugar(created);
  }

  Future<void> _guardar() async {
    if (_selectedLugar == null) return;
    
    final data = {
      'nombre': _nombreController.text,
      'descripcion': _descripcionController.text,
      'clima': _climaController.text,
      'poblacion': _poblacionController.text,
      'importancia': _selectedLugar!['importancia'],
      'imagen_path': _selectedLugar!['imagen_path'],
      'atributos': jsonEncode(_atributos),
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    
    await AppDatabase.updateLugar(_selectedLugar!['id'], data);
    await _cargarLugares();
  }

  Future<void> _eliminarLugar() async {
    if (_selectedLugar == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar lugar?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Esta acción borrará toda la información del lugar.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCELAR', style: GoogleFonts.inter(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text('ELIMINAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.deleteLugar(_selectedLugar!['id']);
      _selectedLugar = null;
      await _cargarLugares();
    }
  }

  Future<void> _pickImage() async {
    if (_selectedLugar == null) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _selectedLugar!['imagen_path'] = result.files.single.path);
      _guardar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar Izquierda: Lista de Lugares
          _buildSidebar(),

          // 2. Contenido Principal
          Expanded(
            child: _selectedLugar == null 
              ? _buildEmptyState() 
              : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ATLAS',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                IconButton(
                  onPressed: _agregarLugar,
                  icon: Icon(Icons.add_location_rounded, color: Colors.white, size: 20),
                  tooltip: 'Nuevo Lugar',
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _lugares.length,
              itemBuilder: (context, index) {
                final l = _lugares[index];
                final isSelected = _selectedLugar != null && l['id'] == _selectedLugar!['id'];
                return _PlaceSidebarItem(
                  name: l['nombre'],
                  importance: l['importancia'] ?? 'Secundario',
                  imagePath: l['imagen_path'],
                  isSelected: isSelected,
                  onTap: () => _seleccionarLugar(l),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          Text(
            'Tu mundo está esperando ser explorado.',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _agregarLugar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C1C1E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: Text('CREAR PRIMER LUGAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Imagen + Nombre/Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceImagePicker(
                imagePath: _selectedLugar!['imagen_path'],
                onTap: _pickImage,
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nombreController,
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        hintText: 'Nombre del Lugar',
                        hintStyle: TextStyle(color: Colors.white10),
                      ),
                      onChanged: (_) => _guardar(),
                    ),
                    Row(
                      children: [
                        _buildBadge('CLIMA', _climaController, Icons.wb_sunny_rounded),
                        const SizedBox(width: 24),
                        _buildBadge('POBLACIÓN', _poblacionController, Icons.people_rounded),
                        const SizedBox(width: 24),
                        _buildImportanceDropdown(),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _eliminarLugar,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30),
                tooltip: 'Eliminar Lugar',
              ),
            ],
          ),
          
          const SizedBox(height: 64),
          
          // Descripción y Atributos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna Izquierda: Descripción
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('CRÓNICA Y DESCRIPCIÓN'),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _descripcionController,
                      maxLines: null,
                      style: GoogleFonts.merriweather(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 2.0,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        hintText: 'Describe la geografía, la arquitectura y el espíritu de este lugar...',
                        hintStyle: TextStyle(color: Colors.white10),
                      ),
                      onChanged: (_) => _guardar(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              // Columna Derecha: Atributos
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('RASGOS DISTINTIVOS'),
                    const SizedBox(height: 24),
                    _buildAttributeCard('ATMÓSFERA', '¿Qué se siente al estar aquí?'),
                    _buildAttributeCard('PUNTOS DE INTERÉS', 'Hitos, tabernas, templos...'),
                    _buildAttributeCard('HISTORIA', 'Breve pasado relevante'),
                    _buildAttributeCard('SECRETOS', 'Lo que no todos saben...'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              hintText: 'Desconocido',
              hintStyle: TextStyle(color: Colors.white10, fontSize: 13),
            ),
            onChanged: (_) => _guardar(),
          ),
        ),
      ],
    );
  }

  Widget _buildImportanceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMPORTANCIA',
          style: GoogleFonts.inter(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        DropdownButton<String>(
          value: _selectedLugar!['importancia'] ?? 'Secundario',
          dropdownColor: const Color(0xFF2C2C2E),
          underline: const SizedBox(),
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          items: ['Principal', 'Secundario', 'Ambiental'].map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedLugar!['importancia'] = val);
              _guardar();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeCard(String title, String hint) {
    final value = _atributos[title] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: null,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white10, fontSize: 13),
              border: InputBorder.none,
              filled: false,
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
}

// ── CUSTOM STATEFUL MENU LIST SIDEBAR ITEM ─────────────────
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

  @override
  Widget build(BuildContext context) {
    const gold = Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      gold.withValues(alpha: 0.15),
                      gold.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : _isHovered
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
            border: Border.all(
              color: widget.isSelected
                  ? gold.withValues(alpha: 0.3)
                  : _isHovered
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: widget.isSelected ? 20 : 0,
                margin: EdgeInsets.only(right: widget.isSelected ? 10 : 0),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.isSelected ? gold : Colors.white.withValues(alpha: 0.05),
                  image: widget.imagePath != null 
                    ? DecorationImage(image: FileImage(File(widget.imagePath!)), fit: BoxFit.cover)
                    : null,
                ),
                child: widget.imagePath == null 
                  ? Icon(Icons.landscape_rounded, color: widget.isSelected ? Colors.black87 : Colors.white24, size: 20)
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: GoogleFonts.inter(
                        color: widget.isSelected
                            ? Colors.white
                            : _isHovered
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.white70,
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.importance,
                      style: GoogleFonts.inter(
                        color: widget.isSelected
                            ? gold.withValues(alpha: 0.8)
                            : Colors.white30,
                        fontSize: 12,
                      ),
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

// ── CUSTOM HOVER IMAGE PICKER CARD ────────────────────────
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
    const gold = Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 200,
          height: 200,
          transformAlignment: Alignment.center,
          transform: _isHovered ? Matrix4.diagonal3Values(1.03, 1.03, 1.0) : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(
              color: _isHovered ? gold.withValues(alpha: 0.6) : gold.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 25 : 15,
                offset: const Offset(0, 6),
              ),
            ],
            image: widget.imagePath != null 
              ? DecorationImage(image: FileImage(File(widget.imagePath!)), fit: BoxFit.cover)
              : null,
          ),
          child: Stack(
            children: [
              if (widget.imagePath == null)
                const Center(
                  child: Icon(Icons.add_a_photo_rounded, color: Colors.white30, size: 40),
                ),
              // Hover overlay
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_camera_back_rounded, color: gold, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          widget.imagePath == null ? 'Añadir Foto' : 'Cambiar Foto',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
