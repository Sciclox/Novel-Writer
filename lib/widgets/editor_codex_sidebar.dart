import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/character_model.dart';
import '../models/place_model.dart';
import '../shared/app_theme.dart';

class EditorCodexSidebar extends StatefulWidget {
  final List<Character> characters;
  final List<Place> places;

  const EditorCodexSidebar({
    super.key,
    required this.characters,
    required this.places,
  });

  @override
  State<EditorCodexSidebar> createState() => _EditorCodexSidebarState();
}

class _EditorCodexSidebarState extends State<EditorCodexSidebar> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTab = 0; // 0 = Personajes, 1 = Lugares
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChars = widget.characters.where((c) {
      if (_query.isEmpty) return true;
      return c.nombre.toLowerCase().contains(_query) ||
          (c.rol?.toLowerCase().contains(_query) ?? false) ||
          (c.alias?.toLowerCase().contains(_query) ?? false);
    }).toList();

    final filteredPlaces = widget.places.where((p) {
      if (_query.isEmpty) return true;
      return p.nombre.toLowerCase().contains(_query) ||
          (p.descripcion?.toLowerCase().contains(_query) ?? false) ||
          (p.clima?.toLowerCase().contains(_query) ?? false);
    }).toList();

    return Column(
      children: [
        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  index: 0,
                  label: 'Personajes (${widget.characters.length})',
                  icon: Icons.people_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton(
                  index: 1,
                  label: 'Lugares (${widget.places.length})',
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: _selectedTab == 0 ? 'Buscar personaje...' : 'Buscar lugar...',
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textTertiary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
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
        ),
        const SizedBox(height: 6),

        // Content
        Expanded(
          child: _selectedTab == 0
              ? _buildCharactersList(filteredChars)
              : _buildPlacesList(filteredPlaces),
        ),
      ],
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.5) : AppColors.separator,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.accent : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharactersList(List<Character> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 36, color: Colors.white12),
            const SizedBox(height: 8),
            Text(
              'No hay personajes en el códex',
              style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: ExpansionTile(
              dense: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                child: Text(
                  c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.nombre,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (c.alias != null && c.alias!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.alias!,
                        style: GoogleFonts.outfit(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  c.rol?.isNotEmpty == true ? c.rol! : 'Personaje',
                  style: GoogleFonts.outfit(color: AppColors.accent, fontSize: 11),
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: [
                // Quote / Frase icónica
                if (c.fraseIconica != null && c.fraseIconica!.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: AppColors.accent, width: 3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded, size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '"${c.fraseIconica!.trim()}"',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Attributes as neat pill cards
                if (c.atributos.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: c.atributos.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.key.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.value,
                              style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Biography / Notes box
                if (c.descripcion != null && c.descripcion!.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIOGRAFÍA',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.descripcion!.trim(),
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlacesList(List<Place> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 36, color: Colors.white12),
            const SizedBox(height: 8),
            Text(
              'No hay lugares en el códex',
              style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: ExpansionTile(
              dense: true,
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.place_rounded, color: AppColors.accent, size: 18),
              ),
              title: Text(
                p.nombre,
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  p.importancia.isNotEmpty ? p.importancia : 'Ubicación',
                  style: GoogleFonts.outfit(color: AppColors.textTertiary, fontSize: 11),
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              children: [
                // Info badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (p.clima != null && p.clima!.trim().isNotEmpty)
                      _buildInfoChip(Icons.cloud_outlined, 'Clima', p.clima!.trim()),
                    if (p.poblacion != null && p.poblacion!.trim().isNotEmpty)
                      _buildInfoChip(Icons.people_outline, 'Población', p.poblacion!.trim()),
                  ],
                ),

                // Description
                if (p.descripcion != null && p.descripcion!.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESCRIPCIÓN',
                          style: GoogleFonts.outfit(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.descripcion!.trim(),
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.accent),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
