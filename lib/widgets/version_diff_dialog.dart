import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';
import '../utils/diff_utils.dart';

class VersionDiffDialog extends StatelessWidget {
  final String currentText;
  final String snapshotContent;
  final String snapshotMotivo;
  final String snapshotFecha;

  const VersionDiffDialog({
    super.key,
    required this.currentText,
    required this.snapshotContent,
    required this.snapshotMotivo,
    required this.snapshotFecha,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentText,
    required String snapshotContent,
    required String snapshotMotivo,
    required String snapshotFecha,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => VersionDiffDialog(
        currentText: currentText,
        snapshotContent: snapshotContent,
        snapshotMotivo: snapshotMotivo,
        snapshotFecha: snapshotFecha,
      ),
    );
  }

  static String _extractPlainText(String content) {
    if (content.trim().startsWith('[') && content.trim().endsWith(']')) {
      try {
        final List<dynamic> json = jsonDecode(content);
        final sb = StringBuffer();
        for (var op in json) {
          if (op is Map && op.containsKey('insert')) {
            final insertVal = op['insert'];
            if (insertVal is String) {
              sb.write(insertVal);
            }
          }
        }
        return sb.toString();
      } catch (_) {}
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final oldPlain = _extractPlainText(snapshotContent);
    final newPlain = _extractPlainText(currentText);
    final diffChunks = DiffUtils.computeDiff(oldPlain, newPlain);

    int additions = 0;
    int deletions = 0;
    for (final c in diffChunks) {
      if (c.type == DiffType.insertion) additions++;
      if (c.type == DiffType.deletion) deletions++;
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.separator),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 600),
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
                  child: Icon(Icons.compare_arrows_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparador de Versiones (Diff)',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Snapshot: $snapshotMotivo  ·  $snapshotFecha',
                      style: GoogleFonts.outfit(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+$additions cambios',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-$deletions eliminados',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textTertiary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.separator, height: 1),
            const SizedBox(height: 16),

            // Diff legend
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Texto actual (añadido)', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                const SizedBox(width: 20),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Snapshot anterior (eliminado)', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 14),

            // Diff rendering
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.separator),
                ),
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      children: diffChunks.map((chunk) {
                        if (chunk.type == DiffType.insertion) {
                          return TextSpan(
                            text: chunk.text,
                            style: GoogleFonts.merriweather(
                              color: const Color(0xFF81C784),
                              backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.25),
                              fontSize: 14,
                              height: 1.8,
                            ),
                          );
                        } else if (chunk.type == DiffType.deletion) {
                          return TextSpan(
                            text: chunk.text,
                            style: GoogleFonts.merriweather(
                              color: const Color(0xFFE57373),
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14,
                              height: 1.8,
                            ),
                          );
                        } else {
                          return TextSpan(
                            text: chunk.text,
                            style: GoogleFonts.merriweather(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.8,
                            ),
                          );
                        }
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
