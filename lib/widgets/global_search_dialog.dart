import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';

class GlobalSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> capitulos;
  final Function(int chapterIndex, int matchOffset) onNavigate;

  const GlobalSearchDialog({
    super.key,
    required this.capitulos,
    required this.onNavigate,
  });

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> capitulos,
    required Function(int chapterIndex, int matchOffset) onNavigate,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => GlobalSearchDialog(
        capitulos: capitulos,
        onNavigate: onNavigate,
      ),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _SearchResult {
  final int chapterIndex;
  final String chapterTitle;
  final int offset;
  final String beforeSnippet;
  final String matchSnippet;
  final String afterSnippet;

  _SearchResult({
    required this.chapterIndex,
    required this.chapterTitle,
    required this.offset,
    required this.beforeSnippet,
    required this.matchSnippet,
    required this.afterSnippet,
  });
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_SearchResult> _results = [];
  bool _caseSensitive = false;
  int _totalOccurrences = 0;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_performSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _extractPlainText(String rawContent) {
    if (rawContent.trim().startsWith('[') && rawContent.trim().endsWith(']')) {
      try {
        final List<dynamic> json = jsonDecode(rawContent);
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
    return rawContent;
  }

  void _performSearch() {
    final query = _queryController.text;
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _totalOccurrences = 0;
      });
      return;
    }

    final List<_SearchResult> matches = [];
    final searchQuery = _caseSensitive ? query : query.toLowerCase();

    for (int chIdx = 0; chIdx < widget.capitulos.length; chIdx++) {
      final cap = widget.capitulos[chIdx];
      final title = (cap['titulo'] as String? ?? '').trim().isEmpty
          ? 'Capítulo ${chIdx + 1}'
          : cap['titulo'] as String;
      final plainText = _extractPlainText(cap['contenido'] as String? ?? '');
      final textToSearch = _caseSensitive ? plainText : plainText.toLowerCase();

      int startIndex = 0;
      while (startIndex < textToSearch.length) {
        final foundIndex = textToSearch.indexOf(searchQuery, startIndex);
        if (foundIndex == -1) break;

        final beforeStart = (foundIndex - 35).clamp(0, plainText.length);
        final beforeSnippet = plainText.substring(beforeStart, foundIndex).replaceAll('\n', ' ');
        final matchSnippet = plainText.substring(foundIndex, foundIndex + query.length);
        final afterEnd = (foundIndex + query.length + 50).clamp(0, plainText.length);
        final afterSnippet = plainText.substring(foundIndex + query.length, afterEnd).replaceAll('\n', ' ');

        matches.add(_SearchResult(
          chapterIndex: chIdx,
          chapterTitle: title,
          offset: foundIndex,
          beforeSnippet: beforeSnippet,
          matchSnippet: matchSnippet,
          afterSnippet: afterSnippet,
        ));

        startIndex = foundIndex + query.length;
      }
    }

    setState(() {
      _results = matches;
      _totalOccurrences = matches.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Container(
        width: 720,
        height: 600,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.manage_search_rounded, color: AppColors.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BÚSQUEDA GLOBAL EN EL MANUSCRITO',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Busca términos, personajes o tramas en todos los capítulos',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    focusNode: _focusNode,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Escribe para buscar en todo el manuscrito...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Distinguir mayúsculas / minúsculas',
                  child: InkWell(
                    onTap: () {
                      setState(() => _caseSensitive = !_caseSensitive);
                      _performSearch();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: _caseSensitive
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _caseSensitive ? AppColors.accent : Colors.white10,
                        ),
                      ),
                      child: Text(
                        'Aa',
                        style: GoogleFonts.outfit(
                          color: _caseSensitive ? AppColors.accent : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Match counter info
            if (_queryController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$_totalOccurrences ${_totalOccurrences == 1 ? "coincidencia" : "coincidencias"} en ${widget.capitulos.length} capítulos',
                  style: GoogleFonts.outfit(
                    color: _totalOccurrences > 0 ? AppColors.accent : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Results List
            Expanded(
              child: _queryController.text.trim().isEmpty
                  ? Center(
                      child: Text(
                        'Escribe una palabra o frase para comenzar la búsqueda.',
                        style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, color: Colors.white24, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'No se encontraron coincidencias en ningún capítulo.',
                                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final res = _results[idx];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onNavigate(res.chapterIndex, res.offset);
                                },
                                borderRadius: BorderRadius.circular(12),
                                hoverColor: Colors.white.withValues(alpha: 0.04),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.article_outlined, size: 14, color: AppColors.accent),
                                          const SizedBox(width: 6),
                                          Text(
                                            res.chapterTitle,
                                            style: GoogleFonts.outfit(
                                              color: AppColors.accent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Pos: ${res.offset}',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white24,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      RichText(
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
                                          children: [
                                            TextSpan(text: '...${res.beforeSnippet}'),
                                            TextSpan(
                                              text: res.matchSnippet,
                                              style: TextStyle(
                                                backgroundColor: AppColors.accent.withValues(alpha: 0.35),
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '${res.afterSnippet}...'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
