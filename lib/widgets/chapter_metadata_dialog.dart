import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chapter_model.dart';
import '../models/character_model.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';

class ChapterMetadataDialog extends StatefulWidget {
  final Chapter chapter;
  final List<Character> characters;
  final Function(Chapter updated) onSave;

  const ChapterMetadataDialog({
    super.key,
    required this.chapter,
    required this.characters,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Chapter chapter,
    required List<Character> characters,
    required Function(Chapter updated) onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => ChapterMetadataDialog(
        chapter: chapter,
        characters: characters,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ChapterMetadataDialog> createState() => _ChapterMetadataDialogState();
}

class _ChapterMetadataDialogState extends State<ChapterMetadataDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _synopsisCtrl;
  late TextEditingController _goalCtrl;
  late String _estado;
  int? _povId;

  static const Map<String, ({String label, Color color, IconData icon})> _statusMap = {
    'borrador': (label: 'Borrador', color: Color(0xFF9E9E9E), icon: Icons.edit_note_rounded),
    'en_revision': (label: 'En Revisión', color: Color(0xFFFFB300), icon: Icons.rate_review_rounded),
    'reescritura': (label: 'Reescritura', color: Color(0xFFFF7043), icon: Icons.replay_rounded),
    'completado': (label: 'Completado', color: Color(0xFF4CAF50), icon: Icons.check_circle_rounded),
  };

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.chapter.titulo);
    _synopsisCtrl = TextEditingController(text: widget.chapter.sinopsis);
    _goalCtrl = TextEditingController(
      text: widget.chapter.metaPalabras > 0 ? widget.chapter.metaPalabras.toString() : '',
    );
    _estado = widget.chapter.estado;
    _povId = widget.chapter.povPersonajeId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final meta = int.tryParse(_goalCtrl.text.trim()) ?? 0;
    final updated = widget.chapter.copyWith(
      titulo: _titleCtrl.text.trim().isEmpty ? 'Sin título' : _titleCtrl.text.trim(),
      sinopsis: _synopsisCtrl.text.trim(),
      estado: _estado,
      povPersonajeId: _povId,
      metaPalabras: meta,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.separator),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalles del Capítulo',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Metadatos narrativos, punto de vista y estado',
                      style: GoogleFonts.outfit(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.separator, height: 1),
            const SizedBox(height: 20),

            // Título
            Text(
              'TÍTULO DEL CAPÍTULO',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ej: El encuentro en la taberna',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.separator),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.separator),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Estado del Capítulo
            Text(
              'ESTADO / WORKFLOW',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusMap.entries.map((e) {
                final isSelected = _estado == e.key;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.icon, size: 14, color: isSelected ? Colors.black : e.value.color),
                      const SizedBox(width: 6),
                      Text(
                        e.value.label,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.black : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: e.value.color,
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  side: BorderSide(
                    color: isSelected ? e.value.color : AppColors.separator,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _estado = e.key);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Fila: POV Personaje + Meta de palabras
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PUNTO DE VISTA (POV)',
                        style: GoogleFonts.outfit(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppDropdown<int?>(
                        value: _povId,
                        hint: 'Ninguno / Omnisciente',
                        items: [
                          const AppDropdownItem<int?>(value: null, label: 'Ninguno / Omnisciente'),
                          ...widget.characters.map((c) => AppDropdownItem<int?>(
                            value: c.id,
                            label: '👤 ${c.nombre}',
                          )),
                        ],
                        onChanged: (val) => setState(() => _povId = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'META DE PALABRAS',
                        style: GoogleFonts.outfit(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _goalCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ej: 2500',
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.03),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.separator),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.separator),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Sinopsis de escena
            Text(
              'SINOPSIS / RESUMEN DE LA ESCENA',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _synopsisCtrl,
              maxLines: 3,
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              decoration: InputDecoration(
                hintText: '¿Qué ocurre en este capítulo? ¿Cuál es el conflicto o giro principal?',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.separator),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.separator),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    side: BorderSide(color: AppColors.separator),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('CANCELAR'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('GUARDAR CAMBIOS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
