import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../database/app_database.dart';
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
  bool _formatoMarkdown = true; // true: MD, false: TXT
  bool _incluirTituloProyecto = true;
  bool _incluirSinopsis = true;
  bool _incluirNumeroCapitulo = true;
  bool _incluirTituloCapitulo = true;
  String _separador = 'Salto de Página (\\f)'; // Opciones: 'Salto de Página (\\f)', 'Línea Horizontal (---)', 'Asteriscos (***)', 'Espacio Doble'

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
      if (_formatoMarkdown) {
        sb.writeln('# ${widget.proyecto['titulo'] ?? 'Sin título'}');
        sb.writeln();
      } else {
        sb.writeln(widget.proyecto['titulo']?.toString().toUpperCase() ?? 'SIN TÍTULO');
        sb.writeln('========================================================================');
        sb.writeln();
      }
    }

    if (_incluirSinopsis && widget.proyecto['sinopsis'] != null && widget.proyecto['sinopsis'].toString().trim().isNotEmpty) {
      if (_formatoMarkdown) {
        sb.writeln('> ${widget.proyecto['sinopsis']}');
        sb.writeln();
      } else {
        sb.writeln('SINOPSIS:');
        sb.writeln(widget.proyecto['sinopsis']);
        sb.writeln('------------------------------------------------------------------------');
        sb.writeln();
      }
    }

    int indexContador = 1;
    final seleccionadosOrdenados = _capitulos.where((c) => _seleccionados[c['id']] == true).toList();

    for (var i = 0; i < seleccionadosOrdenados.length; i++) {
      final cap = seleccionadosOrdenados[i];
      final titulo = cap['titulo'] ?? 'Sin título';
      final contenido = _getPlainText(cap['contenido'] ?? '');

      if (_incluirNumeroCapitulo || _incluirTituloCapitulo) {
        String headerText = '';
        if (_incluirNumeroCapitulo && _incluirTituloCapitulo) {
          headerText = 'Capítulo $indexContador: $titulo';
        } else if (_incluirNumeroCapitulo) {
          headerText = 'Capítulo $indexContador';
        } else {
          headerText = titulo;
        }

        if (_formatoMarkdown) {
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

    return sb.toString();
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
        backgroundColor: const Color(0xFF2C2C2E),
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _formatoMarkdown ? const Color(0xFF00F0FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _formatoMarkdown ? const Color(0xFF00F0FF) : Colors.white10,
                          ),
                        ),
                        child: Text(
                          _formatoMarkdown ? '.md' : '.txt',
                          style: GoogleFonts.inter(
                            color: _formatoMarkdown ? const Color(0xFF00F0FF) : Colors.white54,
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
                    color: const Color(0xFF3A3A3C),
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
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'CERRAR',
                      style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportarManuscrito();
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      'EXPORTAR',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    final content = _generateContent();

    // Preparar nombre de archivo por defecto
    String cleanTitle = (widget.proyecto['titulo'] ?? 'manuscrito')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[\\/:*?"<>| ]'), '_');
    final ext = _formatoMarkdown ? 'md' : 'txt';

    // Abrir diálogo de guardado nativo
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar Manuscrito',
      fileName: '${cleanTitle}_compilado.$ext',
      type: FileType.custom,
      allowedExtensions: [ext],
    );

    if (path == null) return; // Cancelado por el usuario

    try {
      final file = File(path);
      await file.writeAsString(content);

      // Mostrar diálogo de éxito premium
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _SuccessDialog(filePath: path),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escribir el archivo: $e'),
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
            const Icon(Icons.warning_amber_rounded, size: 64, color: Color(0xFF00F0FF)),
            const SizedBox(height: 16),
            Text(
              'No se encontró ningún manuscrito asociado.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B14),
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
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Une tus capítulos, personaliza el formato y exporta tu borrador listo para publicar.',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.download_rounded, color: const Color(0xFF00F0FF).withValues(alpha: 0.2), size: 48),
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
        color: const Color(0xFF12131F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIGURACIÓN DE EXPORTACIÓN',
            style: GoogleFonts.inter(
              color: const Color(0xFF00F0FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Formato Selector (MD vs TXT)
          Text(
            'FORMATO DE ARCHIVO',
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormatButton('Markdown (.md)', _formatoMarkdown, () {
                  setState(() => _formatoMarkdown = true);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatButton('Texto Plano (.txt)', !_formatoMarkdown, () {
                  setState(() => _formatoMarkdown = false);
                }),
              ),
            ],
          ),
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
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _separador,
                dropdownColor: const Color(0xFF12131F),
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
                isExpanded: true,
                items: [
                  'Salto de Página (\\f)',
                  'Línea Horizontal (---)',
                  'Asteriscos (***)',
                  'Espacio Doble',
                ].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _separador = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
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
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00F0FF),
            activeTrackColor: const Color(0xFF00F0FF).withValues(alpha: 0.3),
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
        color: const Color(0xFF12131F),
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
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              ),
              Text(
                '$_totalSelectedChapters / ${_capitulos.length}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total palabras estimadas:',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
              ),
              Text(
                '$_totalSelectedWords palabras',
                style: GoogleFonts.inter(color: const Color(0xFF00F0FF), fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _mostrarPreview,
            icon: const Icon(Icons.preview_rounded, size: 20),
            label: Text(
              'VISTA PREVIA',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1C1C1E),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _exportarManuscrito,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            label: Text(
              'COMPILAR Y EXPORTAR',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black87,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF12131F),
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
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var c in _capitulos) {
                      _seleccionados[c['id']] = true;
                    }
                  });
                },
                child: Text('Seleccionar todos', style: GoogleFonts.inter(color: const Color(0xFF00F0FF), fontSize: 12)),
              ),
              Container(
                height: 12,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white10,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var c in _capitulos) {
                      _seleccionados[c['id']] = false;
                    }
                  });
                },
                child: Text('Deseleccionar todos', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: _capitulos.isEmpty
                ? Center(
                    child: Text(
                      'No hay capítulos registrados en este manuscrito.',
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 15),
                    ),
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
                          activeColor: const Color(0xFF00F0FF),
                          checkColor: Colors.black87,
                          title: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF00F0FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: isSelected ? const Color(0xFF00F0FF) : Colors.white38,
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
                                  style: GoogleFonts.inter(
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
                                  style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
}

class _CompilationDialog extends StatelessWidget {
  const _CompilationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
            ),
            const SizedBox(height: 32),
            Text(
              'Compilando borrador...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Concatenando capítulos y dando formato premium.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
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
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3), width: 1.5),
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
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu manuscrito ha sido compilado y guardado en tu equipo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
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
                style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00F0FF), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'ENTENDIDO',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
