import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../database/app_database.dart';
import '../shared/app_theme.dart';
import '../shared/app_widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:archive/archive.dart';
class ExporterView extends StatefulWidget {
  final Map<String, dynamic> proyecto;

  const ExporterView({super.key, required this.proyecto});

  @override
  State<ExporterView> createState() => _ExporterViewState();
}

class _ExporterViewState extends State<ExporterView> {
  int? _manuscritoId;
  List<Map<String, dynamic>> _capitulos = [];
  final Map<int, bool> _seleccionados = {};
  bool _isLoading = true;

  // Opciones de exportación
  String _exportFormat = 'markdown'; // Options: 'markdown', 'txt', 'pdf', 'epub', 'webnovel'
  bool _incluirTituloProyecto = true;
  bool _incluirSinopsis = true;
  bool _incluirNumeroCapitulo = true;
  bool _incluirTituloCapitulo = true;
  String _separador = 'Salto de Página (\\f)'; // Opciones: 'Salto de Página (\\f)', 'Línea Horizontal (---)', 'Asteriscos (***)', 'Espacio Doble'

  // Notas de autor para modo Web Novel
  final TextEditingController _authorNoteHeaderController = TextEditingController();
  final TextEditingController _authorNoteFooterController = TextEditingController();

  @override
  void dispose() {
    _authorNoteHeaderController.dispose();
    _authorNoteFooterController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final manuscrito = await AppDatabase.getManuscritoByProyecto(widget.proyecto['id']);
    if (manuscrito != null) {
      _manuscritoId = manuscrito['id'];
      final caps = await AppDatabase.getCapitulosByManuscrito(_manuscritoId!);
      setState(() {
        _capitulos = caps;
        for (var c in _capitulos) {
          _seleccionados[c['id']] = true;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getPlainText(String content) {
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
      } catch (e) {
        // Fallback
      }
    }
    return content;
  }

  String _deltaToMarkdown(String content) {
    if (content.trim().startsWith('[') && content.trim().endsWith(']')) {
      try {
        final List<dynamic> json = jsonDecode(content);
        final sb = StringBuffer();
        for (var op in json) {
          if (op is Map && op.containsKey('insert')) {
            final insertVal = op['insert'];
            if (insertVal is String) {
              final attrs = op['attributes'] as Map<String, dynamic>?;
              String text = insertVal;
              if (attrs != null && text.trim().isNotEmpty) {
                if (attrs['bold'] == true) text = '**$text**';
                if (attrs['italic'] == true) text = '*$text*';
                if (attrs['header'] == 1) text = '\n### $text\n';
                if (attrs['header'] == 2) text = '\n#### $text\n';
                if (attrs['blockquote'] == true) text = '\n> $text';
              }
              sb.write(text);
            }
          }
        }
        return sb.toString();
      } catch (e) {
        // Fallback
      }
    }
    return content;
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int get _totalSelectedWords {
    int total = 0;
    for (var c in _capitulos) {
      if (_seleccionados[c['id']] == true) {
        total += _countWords(_getPlainText(c['contenido'] ?? ''));
      }
    }
    return total;
  }

  int get _totalSelectedChapters {
    return _capitulos.where((c) => _seleccionados[c['id']] == true).length;
  }

  String _getSeparatorText() {
    switch (_separador) {
      case 'Línea Horizontal (---)':
        return '\n\n---\n\n';
      case 'Asteriscos (***)':
        return '\n\n***\n\n';
      case 'Espacio Doble':
        return '\n\n\n\n';
      case 'Salto de Página (\\f)':
      default:
        return '\n\n\f\n\n';
    }
  }

  String _generateContent() {
    StringBuffer sb = StringBuffer();

    if (_incluirTituloProyecto) {
      if (_exportFormat == 'markdown' || _exportFormat == 'webnovel') {
        sb.writeln('# ${widget.proyecto['titulo'] ?? 'Sin título'}');
        sb.writeln();
      } else {
        sb.writeln(widget.proyecto['titulo']?.toString().toUpperCase() ?? 'SIN TÍTULO');
        sb.writeln('========================================================================');
        sb.writeln();
      }
    }

    if (_incluirSinopsis && widget.proyecto['sinopsis'] != null && widget.proyecto['sinopsis'].toString().trim().isNotEmpty) {
      if (_exportFormat == 'markdown' || _exportFormat == 'webnovel') {
        sb.writeln('> ${widget.proyecto['sinopsis']}');
        sb.writeln();
      } else {
        sb.writeln('SINOPSIS:');
        sb.writeln(widget.proyecto['sinopsis']);
        sb.writeln('------------------------------------------------------------------------');
        sb.writeln();
      }
    }

    // Nota del autor inicial (Web Novel)
    if (_exportFormat == 'webnovel' && _authorNoteHeaderController.text.trim().isNotEmpty) {
      sb.writeln('> **[Nota del Autor / Author\'s Note]:**');
      for (final line in _authorNoteHeaderController.text.trim().split('\n')) {
        sb.writeln('> $line');
      }
      sb.writeln();
      sb.writeln('---');
      sb.writeln();
    }

    int indexContador = 1;
    final seleccionadosOrdenados = _capitulos.where((c) => _seleccionados[c['id']] == true).toList();

    for (var i = 0; i < seleccionadosOrdenados.length; i++) {
      final cap = seleccionadosOrdenados[i];
      final titulo = cap['titulo'] ?? 'Sin título';
      final contenido = (_exportFormat == 'markdown' || _exportFormat == 'webnovel')
          ? _deltaToMarkdown(cap['contenido'] ?? '')
          : _getPlainText(cap['contenido'] ?? '');

      if (_incluirNumeroCapitulo || _incluirTituloCapitulo) {
        String headerText = '';
        final cleanTitle = titulo.replaceFirst(
          RegExp(r'^cap[ií]tulo\s*\d*[:\s-]*', caseSensitive: false),
          '',
        ).trim();
        final displayTitle = cleanTitle.isNotEmpty ? cleanTitle : titulo;

        if (_incluirNumeroCapitulo && _incluirTituloCapitulo) {
          headerText = 'Capítulo $indexContador: $displayTitle';
        } else if (_incluirNumeroCapitulo) {
          headerText = 'Capítulo $indexContador';
        } else {
          headerText = titulo;
        }

        if (_exportFormat == 'markdown' || _exportFormat == 'webnovel') {
          sb.writeln('## $headerText');
          sb.writeln();
        } else {
          sb.writeln(headerText.toUpperCase());
          sb.writeln('----------------------------------------');
          sb.writeln();
        }
      }

      sb.writeln(contenido);
      sb.writeln();

      if (i < seleccionadosOrdenados.length - 1) {
        sb.writeln(_getSeparatorText());
      }
      indexContador++;
    }

    // Nota del autor de cierre (Web Novel)
    if (_exportFormat == 'webnovel' && _authorNoteFooterController.text.trim().isNotEmpty) {
      sb.writeln();
      sb.writeln('---');
      sb.writeln();
      sb.writeln('> **[Fin del Capítulo - Palabras del Autor]:**');
      for (final line in _authorNoteFooterController.text.trim().split('\n')) {
        sb.writeln('> $line');
      }
      sb.writeln();
    }

    return sb.toString();
  }

  void _copiarFormatoWeb() {
    final content = _generateContent();
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Texto copiado al portapapeles listo para publicar! ($_totalSelectedWords palabras)'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _mostrarPreview() {
    if (_totalSelectedChapters == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos un capítulo para previsualizar.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    final content = _generateContent();
    final lineCount = '\n'.allMatches(content).length + 1;
    final previewLines = content.split('\n').take(100).toList();
    final isTruncated = lineCount > 100;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Container(
          width: 700,
          height: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.preview_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'VISTA PREVIA',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$lineCount líneas · $_totalSelectedWords palabras',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _exportFormat == 'markdown' ? AppColors.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _exportFormat == 'markdown' ? AppColors.accent : Colors.white10,
                          ),
                        ),
                        child: Text(
                          _exportFormat == 'markdown' ? '.md' : _exportFormat == 'webnovel' ? 'web.md' : _exportFormat == 'txt' ? '.txt' : _exportFormat == 'pdf' ? '.pdf' : '.epub',
                          style: GoogleFonts.outfit(
                            color: (_exportFormat == 'markdown' || _exportFormat == 'webnovel') ? AppColors.accent : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      previewLines.join('\n') + (isTruncated ? '\n\n... (vista previa truncada a 100 líneas)' : ''),
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'CERRAR',
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportarManuscrito();
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      'EXPORTAR',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportarManuscrito() async {
    if (_totalSelectedChapters == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos un capítulo para exportar.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // Simular proceso de compilación prémium
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _CompilationDialog(),
    );

    await Future.delayed(const Duration(milliseconds: 1500)); // Delay cinematográfico
    if (!mounted) return;
    Navigator.pop(context); // Cerrar diálogo de compilación

    String cleanTitle = (widget.proyecto['titulo'] ?? 'manuscrito')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
    
    final ext = (_exportFormat == 'markdown' || _exportFormat == 'webnovel')
        ? 'md'
        : _exportFormat == 'txt'
            ? 'txt'
            : _exportFormat == 'pdf'
                ? 'pdf'
                : 'epub';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar Manuscrito',
      fileName: '${cleanTitle}_compilado.$ext',
      type: FileType.custom,
      allowedExtensions: [ext],
    );

    if (path == null) return;

    try {
      if (_exportFormat == 'pdf') {
        await _exportarPDF(path);
      } else if (_exportFormat == 'epub') {
        await _exportarEPUB(path);
      } else {
        final content = _generateContent();
        final file = File(path);
        await file.writeAsString(content);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _SuccessDialog(filePath: path),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar el archivo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_manuscritoId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'No se encontró ningún manuscrito asociado.',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compilador de Manuscrito',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Une tus capítulos, personaliza el formato y exporta tu borrador listo para publicar.',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.download_rounded, color: AppColors.accent.withValues(alpha: 0.2), size: 48),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PANEL IZQUIERDO: Configuración (450px)
                  SizedBox(
                    width: 420,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConfigSection(),
                          const SizedBox(height: 24),
                          _buildActionsCard(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),

                  // PANEL DERECHO: Capítulos Checklist
                  Expanded(
                    child: _buildChaptersPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIGURACIÓN DE EXPORTACIÓN',
            style: GoogleFonts.outfit(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Formato Selector (MD vs TXT)
          Text(
            'FORMATO DE ARCHIVO',
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 175,
                child: _buildFormatButton('Markdown (.md)', _exportFormat == 'markdown', () {
                  setState(() => _exportFormat = 'markdown');
                }),
              ),
              SizedBox(
                width: 175,
                child: _buildFormatButton('Texto Plano (.txt)', _exportFormat == 'txt', () {
                  setState(() => _exportFormat = 'txt');
                }),
              ),
              SizedBox(
                width: 175,
                child: _buildFormatButton('PDF (.pdf)', _exportFormat == 'pdf', () {
                  setState(() => _exportFormat = 'pdf');
                }),
              ),
              SizedBox(
                width: 175,
                child: _buildFormatButton('EPUB (.epub)', _exportFormat == 'epub', () {
                  setState(() => _exportFormat = 'epub');
                }),
              ),
              SizedBox(
                width: 358,
                child: _buildFormatButton('Web Novel / Publicación Digital', _exportFormat == 'webnovel', () {
                  setState(() => _exportFormat = 'webnovel');
                }),
              ),
            ],
          ),
          if (_exportFormat == 'webnovel') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'MODO NOVELA WEB (NOTAS DE AUTOR)',
                        style: GoogleFonts.outfit(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nota del Autor (Encabezado):',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _authorNoteHeaderController,
                    maxLines: 2,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Ej: ¡Bienvenidos al inicio de la novela! Saludos a todos los lectores.',
                      hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nota del Autor (Pie de página):',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _authorNoteFooterController,
                    maxLines: 2,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Ej: ¿Qué les pareció el despertar del 10° Príncipe? Dejen sus comentarios...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Checkboxes de opciones
          _buildToggleOption(
            title: 'Incluir Título del Proyecto',
            subtitle: 'Agrega el título de la novela al inicio del documento.',
            value: _incluirTituloProyecto,
            onChanged: (val) => setState(() => _incluirTituloProyecto = val),
          ),
          _buildToggleOption(
            title: 'Incluir Sinopsis del Proyecto',
            subtitle: 'Coloca la sinopsis inicial antes del primer capítulo.',
            value: _incluirSinopsis,
            onChanged: (val) => setState(() => _incluirSinopsis = val),
          ),
          _buildToggleOption(
            title: 'Incluir Números de Capítulos',
            subtitle: 'Inserta "Capítulo X" automáticamente.',
            value: _incluirNumeroCapitulo,
            onChanged: (val) => setState(() => _incluirNumeroCapitulo = val),
          ),
          _buildToggleOption(
            title: 'Incluir Títulos de Capítulos',
            subtitle: 'Muestra los nombres asignados a los capítulos.',
            value: _incluirTituloCapitulo,
            onChanged: (val) => setState(() => _incluirTituloCapitulo = val),
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Separador Dropdown
          Text(
            'SEPARADOR ENTRE CAPÍTULOS',
            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: AppDropdown<String>(
              value: _separador,
              items: [
                'Salto de Página (\\f)',
                'Línea Horizontal (---)',
                'Asteriscos (***)',
                'Espacio Doble',
              ].map((val) {
                return AppDropdownItem<String>(value: val, label: val);
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _separador = val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton(String label, bool isSelected, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.white10,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isSelected ? AppColors.accent : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capítulos a compilar:',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
              ),
              Text(
                '$_totalSelectedChapters / ${_capitulos.length}',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total palabras estimadas:',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
              ),
              Text(
                '$_totalSelectedWords palabras',
                style: GoogleFonts.outfit(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _mostrarPreview,
            icon: const Icon(Icons.preview_rounded, size: 20),
            label: Text(
              'VISTA PREVIA',
              style: GoogleFonts.outfit(fontSize: 15),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _exportarManuscrito,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              'COMPILAR Y EXPORTAR',
              style: GoogleFonts.outfit(fontSize: 15),
            ),
          ),
          if (_exportFormat == 'webnovel') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copiarFormatoWeb,
              icon: const Icon(Icons.copy_all_rounded, size: 20),
              label: Text(
                'COPIAR FORMATO WEB',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChaptersPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ESTRUCTURA DEL MANUSCRITO',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    for (var c in _capitulos) {
                      _seleccionados[c['id']] = true;
                    }
                  });
                },
                child: Text('Seleccionar todos', style: GoogleFonts.outfit(fontSize: 12)),
              ),
              Container(
                height: 12,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white10,
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    for (var c in _capitulos) {
                      _seleccionados[c['id']] = false;
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.3)),
                ),
                child: Text('Deseleccionar todos', style: GoogleFonts.outfit(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: _capitulos.isEmpty
                ? buildEmptyState(
                    icon: Icons.article_outlined,
                    title: 'No hay capítulos registrados',
                    subtitle: 'Este manuscrito no tiene capítulos aún.',
                  )
                : ListView.builder(
                    itemCount: _capitulos.length,
                    itemBuilder: (context, index) {
                      final cap = _capitulos[index];
                      final id = cap['id'] as int;
                      final isSelected = _seleccionados[id] == true;
                      final count = _countWords(cap['contenido'] ?? '');
                      final tipo = cap['tipo'] ?? 'capitulo';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              _seleccionados[id] = val ?? false;
                            });
                          },
                          activeColor: AppColors.accent,
                          checkColor: Colors.black87,
                          title: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: isSelected ? AppColors.accent : Colors.white38,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  cap['titulo'] ?? 'Capítulo sin título',
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? Colors.white : Colors.white38,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 44, top: 4),
                            child: Row(
                              children: [
                                Text(
                                  '$count palabras',
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? Colors.white30 : Colors.white12,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (tipo == 'prologo' || tipo == 'epilogo')
                                        ? Colors.purple.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tipo.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      color: (tipo == 'prologo' || tipo == 'epilogo')
                                          ? Colors.purpleAccent.withValues(alpha: 0.7)
                                          : Colors.white24,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarPDF(String path) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    if (_incluirTituloProyecto) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(54),
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 100),
                pw.Text(
                  widget.proyecto['titulo'] ?? 'Sin Título',
                  style: pw.TextStyle(font: fontBold, fontSize: 32),
                  textAlign: pw.TextAlign.center,
                ),
                if (widget.proyecto['autor'] != null) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Por: ${widget.proyecto['autor']}',
                    style: pw.TextStyle(font: font, fontSize: 18),
                  ),
                ],
                pw.SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );
    }

    if (_incluirSinopsis && widget.proyecto['sinopsis'] != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(54),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SINOPSIS',
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                widget.proyecto['sinopsis']!,
                style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    int capIdx = 1;
    for (var c in _capitulos) {
      if (_seleccionados[c['id']] == true) {
        final title = c['titulo'] ?? '';
        final text = _getPlainText(c['contenido'] ?? '');

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(54),
            build: (context) => [
              if (_incluirNumeroCapitulo)
                pw.Text(
                  'CAPÍTULO $capIdx',
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700),
                ),
              if (_incluirTituloCapitulo && title.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(font: fontBold, fontSize: 22),
                ),
              ],
              pw.SizedBox(height: 16),
              pw.Paragraph(
                text: text,
                style: pw.TextStyle(font: font, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        );
        capIdx++;
      }
    }

    final file = File(path);
    await file.writeAsBytes(await pdf.save());
  }

  Future<void> _exportarEPUB(String path) async {
    final archive = Archive();
    final mimetypeBytes = utf8.encode('application/epub+zip');
    archive.addFile(ArchiveFile.noCompress('mimetype', mimetypeBytes.length, mimetypeBytes));

    final containerXml = """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="EPUB/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>""";
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    final spineItems = <String>[];
    final manifestItems = <String>[];
    final tocEntries = <String>[];
    int index = 1;

    if (_incluirTituloProyecto) {
      final titleHtml = """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="es" lang="es">
<head>
  <title>${widget.proyecto['titulo'] ?? 'Novela'}</title>
  <style>
    body { text-align: center; font-family: sans-serif; padding: 50px; }
    h1 { font-size: 3em; margin-top: 100px; }
    h2 { font-size: 1.5em; color: #555; }
  </style>
</head>
<body>
  <h1>${widget.proyecto['titulo'] ?? 'Novela'}</h1>
  <h2>Novela compilada con Novel Writer</h2>
</body>
</html>""";
      archive.addFile(ArchiveFile('EPUB/title.xhtml', titleHtml.length, utf8.encode(titleHtml)));
      manifestItems.add('<item id="title" href="title.xhtml" media-type="application/xhtml+xml"/>');
      spineItems.add('<itemref idref="title"/>');
      tocEntries.add('<navPoint id="title" playOrder="$index"><navLabel><text>Portada</text></navLabel><content src="title.xhtml"/></navPoint>');
      index++;
    }

    if (_incluirSinopsis && widget.proyecto['sinopsis'] != null) {
      final sinopsisHtml = """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="es" lang="es">
<head>
  <title>Sinopsis</title>
  <style>
    body { font-family: sans-serif; padding: 20px; line-height: 1.6; }
    h1 { text-align: center; }
  </style>
</head>
<body>
  <h1>Sinopsis</h1>
  <p>${widget.proyecto['sinopsis']?.replaceAll('\n', '<br/>')}</p>
</body>
</html>""";
      archive.addFile(ArchiveFile('EPUB/sinopsis.xhtml', sinopsisHtml.length, utf8.encode(sinopsisHtml)));
      manifestItems.add('<item id="sinopsis" href="sinopsis.xhtml" media-type="application/xhtml+xml"/>');
      spineItems.add('<itemref idref="sinopsis"/>');
      tocEntries.add('<navPoint id="sinopsis" playOrder="$index"><navLabel><text>Sinopsis</text></navLabel><content src="sinopsis.xhtml"/></navPoint>');
      index++;
    }

    int capIdx = 1;
    for (var c in _capitulos) {
      if (_seleccionados[c['id']] == true) {
        final title = c['titulo'] ?? '';
        final text = _getPlainText(c['contenido'] ?? '');
        final idStr = 'chapter_$capIdx';

        final html = """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="es" lang="es">
<head>
  <title>$title</title>
  <style>
    body { font-family: serif; padding: 20px; line-height: 1.8; font-size: 1.1em; }
    h1 { font-size: 1.8em; margin-bottom: 20px; text-align: center; }
    .chap-num { text-align: center; color: #666; font-size: 0.9em; margin-bottom: 5px; text-transform: uppercase; }
  </style>
</head>
<body>
  ${_incluirNumeroCapitulo ? '<div class="chap-num">Capítulo $capIdx</div>' : ''}
  ${_incluirTituloCapitulo && title.isNotEmpty ? '<h1>$title</h1>' : ''}
  <p>${text.replaceAll('\n', '</p><p>')}</p>
</body>
</html>""";

        archive.addFile(ArchiveFile('EPUB/$idStr.xhtml', html.length, utf8.encode(html)));
        manifestItems.add('<item id="$idStr" href="$idStr.xhtml" media-type="application/xhtml+xml"/>');
        spineItems.add('<itemref idref="$idStr"/>');
        
        final tocTitle = title.isNotEmpty ? title : 'Capítulo $capIdx';
        tocEntries.add('<navPoint id="$idStr" playOrder="$index"><navLabel><text>$tocTitle</text></navLabel><content src="$idStr.xhtml"/></navPoint>');
        
        index++;
        capIdx++;
      }
    }

    final tocNcx = """<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${widget.proyecto['id']}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${widget.proyecto['titulo'] ?? 'Novela'}</text>
  </docTitle>
  <navMap>
    ${tocEntries.join('\n    ')}
  </navMap>
</ncx>""";
    archive.addFile(ArchiveFile('EPUB/toc.ncx', tocNcx.length, utf8.encode(tocNcx)));
    manifestItems.add('<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');

    final contentOpf = """<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookID" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>${widget.proyecto['titulo'] ?? 'Novela'}</dc:title>
    <dc:language>es</dc:language>
    <dc:identifier id="BookID">urn:uuid:${widget.proyecto['id']}</dc:identifier>
    <dc:creator>${widget.proyecto['autor'] ?? 'Autor'}</dc:creator>
  </metadata>
  <manifest>
    ${manifestItems.join('\n    ')}
  </manifest>
  <spine toc="ncx">
    ${spineItems.join('\n    ')}
  </spine>
</package>""";
    archive.addFile(ArchiveFile('EPUB/content.opf', contentOpf.length, utf8.encode(contentOpf)));

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    final file = File(path);
    await file.writeAsBytes(zipData);
  }

}

class _CompilationDialog extends StatelessWidget {
  const _CompilationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            const SizedBox(height: 32),
            Text(
              'Compilando borrador...',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Concatenando capítulos y dando formato premium.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String filePath;

  const _SuccessDialog({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 32),
            Text(
              '¡Exportación Exitosa!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu manuscrito ha sido compilado y guardado en tu equipo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SelectableText(
                filePath,
                style: GoogleFonts.jetBrainsMono(color: AppColors.accent, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ENTENDIDO',
              ),
            )
          ],
        ),
      ),
    );
  }
}
