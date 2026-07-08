import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../shared/app_widgets.dart';
import '../models/novel_style.dart';

class StyleDropdown extends StatefulWidget {
  final int proyectoId;
  final Function(int styleId) onStyleSelected;

  const StyleDropdown({
    super.key,
    required this.proyectoId,
    required this.onStyleSelected,
  });

  @override
  State<StyleDropdown> createState() => _StyleDropdownState();
}

class _StyleDropdownState extends State<StyleDropdown> {
  List<NovelStyle> _estilos = [];
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _cargarEstilos();
  }

  Future<void> _cargarEstilos() async {
    final rows = await AppDatabase.getEstilos(widget.proyectoId);
    if (!mounted) return;
    setState(() {
      _estilos = rows.map((r) => NovelStyle.fromMap(r)).toList();
      if (_estilos.isNotEmpty) _selectedId ??= _estilos.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: AppDropdown<int>(
        value: _selectedId,
        hint: 'Estilo',
        items: _estilos.map((s) => AppDropdownItem<int>(
          value: s.id!,
          label: s.nombre,
        )).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedId = val);
            widget.onStyleSelected(val);
          }
        },
      ),
    );
  }
}

Map<String, dynamic>? resolveStyleConfig(int styleId, List<NovelStyle> estilos) {
  final style = estilos.where((s) => s.id == styleId).firstOrNull;
  if (style == null) return null;
  return mergeStyleConfig(style, estilos);
}
