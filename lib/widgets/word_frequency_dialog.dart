import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';
import '../utils/narrative_text_utils.dart';

class WordFrequencyDialog extends StatelessWidget {
  final String text;
  final int totalWords;

  const WordFrequencyDialog({
    super.key,
    required this.text,
    required this.totalWords,
  });

  static Future<void> show(BuildContext context, String text, int totalWords) async {
    await showDialog(
      context: context,
      builder: (ctx) => WordFrequencyDialog(text: text, totalWords: totalWords),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frequencies = NarrativeTextUtils.analyzeWordFrequencies(text, minLength: 4, top: 25);
    final readingTime = NarrativeTextUtils.estimateReadingTime(totalWords);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.separator),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Container(
        width: 520,
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
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis de Vocabulario y Ritmo',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$totalWords palabras  ·  Tiempo de lectura aprox: $readingTime',
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
            const SizedBox(height: 16),
            Divider(color: AppColors.separator, height: 1),
            const SizedBox(height: 16),

            Text(
              'PALABRAS MÁS REPETIDAS (Excluyendo conectores)',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Word list
            Expanded(
              child: frequencies.isEmpty
                  ? Center(
                      child: Text(
                        'Escribe más texto para analizar la frecuencia de palabras.',
                        style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: frequencies.length,
                      itemBuilder: (context, index) {
                        final entry = frequencies.entries.elementAt(index);
                        final maxCount = frequencies.values.first;
                        final ratio = (entry.value / maxCount).clamp(0.0, 1.0);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '#${index + 1}',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                                      valueColor: AlwaysStoppedAnimation(
                                        ratio > 0.6 ? AppColors.accent : AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${entry.value}x',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
