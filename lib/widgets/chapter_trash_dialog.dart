import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chapter_model.dart';
import '../repositories/chapter_repository.dart';
import '../shared/app_theme.dart';

class ChapterTrashDialog extends StatefulWidget {
  final int manuscritoId;
  final VoidCallback onRestored;

  const ChapterTrashDialog({
    super.key,
    required this.manuscritoId,
    required this.onRestored,
  });

  static Future<void> show({
    required BuildContext context,
    required int manuscritoId,
    required VoidCallback onRestored,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => ChapterTrashDialog(
        manuscritoId: manuscritoId,
        onRestored: onRestored,
      ),
    );
  }

  @override
  State<ChapterTrashDialog> createState() => _ChapterTrashDialogState();
}

class _ChapterTrashDialogState extends State<ChapterTrashDialog> {
  final ChapterRepository _repo = ChapterRepository();
  List<Chapter> _trash = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _loading = true);
    final items = await _repo.getTrash(widget.manuscritoId);
    if (!mounted) return;
    setState(() {
      _trash = items;
      _loading = false;
    });
  }

  Future<void> _restore(Chapter chapter) async {
    if (chapter.id == null) return;
    await _repo.restoreFromTrash(chapter.id!);
    await _loadTrash();
    widget.onRestored();
  }

  Future<void> _deletePermanently(Chapter chapter) async {
    if (chapter.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('¿Eliminar permanentemente?', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text(
          'Esta acción destruirá el capítulo "${chapter.titulo}" de forma irreversible.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteChapterPermanently(chapter.id!);
      await _loadTrash();
    }
  }

  Future<void> _emptyAll() async {
    if (_trash.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('¿Vaciar papelera?', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
        content: Text(
          'Se eliminarán permanentemente todos los capítulos en la papelera (${_trash.length}).',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('VACIAR TODO'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.emptyTrash(widget.manuscritoId);
      await _loadTrash();
    }
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
        width: 560,
        constraints: const BoxConstraints(maxHeight: 520),
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
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Papelera del Manuscrito',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Restaura capítulos eliminados o elimínalos definitivamente',
                      style: GoogleFonts.outfit(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_trash.isNotEmpty)
                  TextButton.icon(
                    onPressed: _emptyAll,
                    icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.redAccent),
                    label: Text(
                      'Vaciar',
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.separator, height: 1),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _trash.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_delete_outlined, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'La papelera está vacía',
                                style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _trash.length,
                          separatorBuilder: (_, _) => Divider(color: AppColors.separator, height: 1),
                          itemBuilder: (context, index) {
                            final c = _trash[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Icon(Icons.article_outlined, color: AppColors.textTertiary),
                              title: Text(
                                c.titulo,
                                style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${c.palabras} palabras · Eliminado el ${c.eliminadoEn?.toLocal().toString().split('.').first ?? ''}',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore_from_trash_rounded, color: Color(0xFF4CAF50)),
                                    tooltip: 'Restaurar capítulo',
                                    onPressed: () => _restore(c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                    tooltip: 'Eliminar permanentemente',
                                    onPressed: () => _deletePermanently(c),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
