import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chapter_coherence_model.dart';
import '../models/lore_node_model.dart';
import '../repositories/lore_graph_repository.dart';
import '../shared/app_theme.dart';

class EditorCoherenceSidebar extends StatefulWidget {
  final int proyectoId;
  final Map<String, dynamic>? capitulo;
  final VoidCallback? onContextCopied;

  const EditorCoherenceSidebar({
    super.key,
    required this.proyectoId,
    required this.capitulo,
    this.onContextCopied,
  });

  @override
  State<EditorCoherenceSidebar> createState() => _EditorCoherenceSidebarState();
}

class _EditorCoherenceSidebarState extends State<EditorCoherenceSidebar> {
  final _repository = LoreGraphRepository();
  bool _loading = true;
  bool _saving = false;
  bool _savedSuccess = false;
  Timer? _debounceTimer;

  List<LoreNodeModel> _allNodes = [];
  ChapterCoherenceModel? _coherence;

  int? _selectedPlaceId;
  final Set<int> _selectedPersonajes = {};
  final Set<int> _selectedArtefactos = {};
  final Map<int, TextEditingController> _healthControllers = {};
  final List<String> _secretos = [];
  final TextEditingController _newSecretCtrl = TextEditingController();
  final TextEditingController _notasContinuidadCtrl = TextEditingController();

  bool _showPromptPreview = false;
  String _generatedPrompt = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant EditorCoherenceSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capitulo?['id'] != widget.capitulo?['id']) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _newSecretCtrl.dispose();
    _notasContinuidadCtrl.dispose();
    for (final c in _healthControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final capId = widget.capitulo?['id'] as int?;
    if (capId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      // Ensure sync from legacy entities if needed
      await _repository.syncExistingEntities(widget.proyectoId);
      final nodes = await _repository.getNodes(widget.proyectoId);
      final coh = await _repository.getCoherence(capId);

      _allNodes = nodes;
      _coherence = coh;

      // Dispose old controllers
      for (final c in _healthControllers.values) {
        c.dispose();
      }
      _healthControllers.clear();
      _selectedPersonajes.clear();
      _selectedArtefactos.clear();
      _secretos.clear();

      if (coh != null) {
        _selectedPlaceId = coh.lugarId;
        _selectedPersonajes.addAll(coh.personajesIds);
        _selectedArtefactos.addAll(coh.artefactosIds);
        _secretos.addAll(coh.secretosRevelados);
        _notasContinuidadCtrl.text = coh.notasContinuidad ?? '';

        for (final pId in coh.personajesIds) {
          final estado = coh.estadoSalud[pId.toString()] ?? 'Saludable';
          _healthControllers[pId] = TextEditingController(text: estado);
        }
      } else {
        _selectedPlaceId = null;
        _notasContinuidadCtrl.text = '';
      }

      // Pre-generate prompt preview
      _generatedPrompt = await _repository.generateAiContextPrompt(
        proyectoId: widget.proyectoId,
        capituloId: capId,
        capituloTitulo: widget.capitulo?['titulo'] ?? 'Capítulo',
      );
    } catch (e) {
      debugPrint('Error cargando coherencia: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _triggerAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), _saveCoherence);
  }

  Future<void> _saveCoherence() async {
    final capId = widget.capitulo?['id'] as int?;
    if (capId == null) return;

    setState(() => _saving = true);

    final healthMap = <String, String>{};
    for (final pId in _selectedPersonajes) {
      final text = _healthControllers[pId]?.text.trim();
      if (text != null && text.isNotEmpty) {
        healthMap[pId.toString()] = text;
      }
    }

    final updated = ChapterCoherenceModel(
      id: _coherence?.id,
      capituloId: capId,
      lugarId: _selectedPlaceId,
      personajesIds: _selectedPersonajes.toList(),
      artefactosIds: _selectedArtefactos.toList(),
      estadoSalud: healthMap,
      secretosRevelados: List.from(_secretos),
      notasContinuidad: _notasContinuidadCtrl.text.trim().isEmpty ? null : _notasContinuidadCtrl.text.trim(),
    );

    await _repository.saveCoherence(updated);

    // Refresh prompt preview
    final prompt = await _repository.generateAiContextPrompt(
      proyectoId: widget.proyectoId,
      capituloId: capId,
      capituloTitulo: widget.capitulo?['titulo'] ?? 'Capítulo',
    );

    if (mounted) {
      setState(() {
        _coherence = updated;
        _generatedPrompt = prompt;
        _saving = false;
        _savedSuccess = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _savedSuccess = false);
      });
    }
  }

  Future<void> _copyAiPrompt() async {
    final capId = widget.capitulo?['id'] as int?;
    if (capId == null) return;

    await _saveCoherence();

    await Clipboard.setData(ClipboardData(text: _generatedPrompt));
    widget.onContextCopied?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ficha de Coherencia copiada al portapapeles. ¡Lista para alimentar a la IA!',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E2430),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.capitulo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_outlined, size: 42, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                'Selecciona un capítulo para configurar su matriz de coherencia.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final lugares = _allNodes.where((n) => n.tipo == 'lugar').toList();
    final personajes = _allNodes.where((n) => n.tipo == 'personaje').toList();
    final artefactos = _allNodes.where((n) => n.tipo == 'artefacto').toList();

    return Column(
      children: [
        // Header & Quick Prompt Copy
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.35),
            border: Border(bottom: BorderSide(color: AppColors.separator)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.hub_rounded, size: 16, color: AppColors.accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matriz de Coherencia',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.capitulo?['titulo'] ?? 'Capítulo actual',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_saving)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_savedSuccess)
                    Icon(Icons.check_rounded, size: 16, color: Colors.greenAccent)
                  else
                    Icon(Icons.cloud_done_outlined, size: 15, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyAiPrompt,
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: Text(
                        'Copiar Contexto IA',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: _showPromptPreview ? 'Ocultar vista previa' : 'Ver ficha IA generada',
                    onPressed: () => setState(() => _showPromptPreview = !_showPromptPreview),
                    icon: Icon(
                      _showPromptPreview ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: _showPromptPreview ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: _showPromptPreview
              ? _buildPromptPreview()
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // 1. Escenario
                    _buildSectionHeader('📍 Escenario del Capítulo', Icons.place_outlined),
                    const SizedBox(height: 6),
                    _buildPlaceSelector(lugares),

                    const SizedBox(height: 16),

                    // 2. Personajes
                    _buildSectionHeader('👥 Personajes en Escena (${_selectedPersonajes.length})', Icons.people_outline),
                    const SizedBox(height: 6),
                    _buildPersonajesSelector(personajes),

                    const SizedBox(height: 16),

                    // 3. Artefactos / Armas
                    _buildSectionHeader('⚔️ Artefactos Activos (${_selectedArtefactos.length})', Icons.shield_outlined),
                    const SizedBox(height: 6),
                    _buildArtefactosSelector(artefactos),

                    const SizedBox(height: 16),

                    // 4. Secretos Revelados
                    _buildSectionHeader('🗝️ Secretos Revelados (${_secretos.length})', Icons.vpn_key_outlined),
                    const SizedBox(height: 6),
                    _buildSecretosSection(),

                    const SizedBox(height: 16),

                    // 5. Reglas de Continuidad
                    _buildSectionHeader('⚠️ Reglas / Restricciones Narrativas', Icons.warning_amber_rounded),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notasContinuidadCtrl,
                      maxLines: 3,
                      onChanged: (_) => _triggerAutoSave(),
                      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Ej: Long Ze no puede revelar su cultivo aún; Zhao Hu tiene sospechas pero no pruebas...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.separator),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.separator),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceSelector(List<LoreNodeModel> lugares) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.separator),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedPlaceId,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          hint: Text(
            'Sin escenario específico',
            style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 12),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'Sin escenario específico',
                style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
            ...lugares.map(
              (l) => DropdownMenuItem<int?>(
                value: l.id,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.nombre,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (val) {
            setState(() => _selectedPlaceId = val);
            _triggerAutoSave();
          },
        ),
      ),
    );
  }

  Widget _buildPersonajesSelector(List<LoreNodeModel> personajes) {
    if (personajes.isEmpty) {
      return Text(
        'No hay personajes en la Red de Lore.',
        style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: personajes.map((p) {
            final isSelected = _selectedPersonajes.contains(p.id);
            return FilterChip(
              label: Text(p.nombre),
              labelStyle: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              selected: isSelected,
              selectedColor: AppColors.accent.withValues(alpha: 0.18),
              backgroundColor: Colors.white.withValues(alpha: 0.02),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.separator,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              showCheckmark: false,
              avatar: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                child: Text(
                  p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (p.id != null) {
                      _selectedPersonajes.add(p.id!);
                      _healthControllers.putIfAbsent(
                        p.id!,
                        () => TextEditingController(text: p.estado),
                      );
                    }
                  } else {
                    if (p.id != null) {
                      _selectedPersonajes.remove(p.id!);
                    }
                  }
                });
                _triggerAutoSave();
              },
            );
          }).toList(),
        ),

        // Lista de estado de salud/heridas para los personajes seleccionados
        if (_selectedPersonajes.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._selectedPersonajes.map((pId) {
            final pNode = personajes.where((n) => n.id == pId).firstOrNull;
            if (pNode == null) return const SizedBox.shrink();
            final ctrl = _healthControllers[pId] ??= TextEditingController(text: pNode.estado);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.separator.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      pNode.nombre,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: ctrl,
                      onChanged: (_) => _triggerAutoSave(),
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        hintText: 'Estado / Heridas',
                        hintStyle: GoogleFonts.outfit(fontSize: 10, color: AppColors.textTertiary),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: AppColors.separator),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildArtefactosSelector(List<LoreNodeModel> artefactos) {
    if (artefactos.isEmpty) {
      return Text(
        'No hay artefactos registrados en la Red de Lore.',
        style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: artefactos.map((a) {
        final isSelected = _selectedArtefactos.contains(a.id);
        return FilterChip(
          label: Text(a.nombre),
          labelStyle: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.cyanAccent : AppColors.textSecondary,
          ),
          selected: isSelected,
          selectedColor: Colors.cyanAccent.withValues(alpha: 0.15),
          backgroundColor: Colors.white.withValues(alpha: 0.02),
          side: BorderSide(
            color: isSelected ? Colors.cyanAccent : AppColors.separator,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          showCheckmark: false,
          avatar: Icon(Icons.shield_outlined, size: 14, color: isSelected ? Colors.cyanAccent : AppColors.textTertiary),
          onSelected: (selected) {
            setState(() {
              if (selected && a.id != null) {
                _selectedArtefactos.add(a.id!);
              } else if (a.id != null) {
                _selectedArtefactos.remove(a.id!);
              }
            });
            _triggerAutoSave();
          },
        );
      }).toList(),
    );
  }

  Widget _buildSecretosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_secretos.isNotEmpty)
          ..._secretos.asMap().entries.map((entry) {
            final index = entry.key;
            final secreto = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.separator.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_rounded, size: 12, color: Colors.amberAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      secreto,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 13, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() => _secretos.removeAt(index));
                      _triggerAutoSave();
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newSecretCtrl,
                style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Añadir secreto o revelación...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.separator),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _secretos.add(val.trim());
                      _newSecretCtrl.clear();
                    });
                    _triggerAutoSave();
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () {
                final val = _newSecretCtrl.text.trim();
                if (val.isNotEmpty) {
                  setState(() {
                    _secretos.add(val);
                    _newSecretCtrl.clear();
                  });
                  _triggerAutoSave();
                }
              },
              icon: Icon(Icons.add_circle_outline, size: 20, color: AppColors.accent),
              tooltip: 'Añadir secreto',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromptPreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ficha Markdown para IA',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                tooltip: 'Copiar todo',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedPrompt));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copiado al portapapeles'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF13171F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.separator),
              ),
              child: SelectableText(
                _generatedPrompt,
                style: GoogleFonts.firaCode(
                  fontSize: 11,
                  color: const Color(0xFFD4D4D8),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
