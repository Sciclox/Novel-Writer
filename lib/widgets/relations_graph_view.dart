import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_theme.dart';
import '../screens/characters_view.dart' show CharacterRelationsPainter;

class RelationsGraphView extends StatefulWidget {
  final List<Map<String, dynamic>> personajes;
  final List<Map<String, dynamic>> relaciones;
  final int? selectedPersonajeId;
  final int? firstSelectedId;
  final Function(int) onNodeTap;
  final Function(int) onNodeDoubleTap;

  const RelationsGraphView({
    super.key,
    required this.personajes,
    required this.relaciones,
    required this.selectedPersonajeId,
    required this.firstSelectedId,
    required this.onNodeTap,
    required this.onNodeDoubleTap,
  });

  @override
  State<RelationsGraphView> createState() => _RelationsGraphViewState();
}

class _RelationsGraphViewState extends State<RelationsGraphView> with SingleTickerProviderStateMixin {
  final double canvasSize = 1000.0;
  late Offset center;

  Map<int, Offset> _positions = {};
  Map<int, Offset> _velocities = {};
  int? _draggingId;
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    center = Offset(canvasSize / 2, canvasSize / 2);
    _initializePositions();
    
    _ticker = createTicker(_onTick);
    _ticker!.start();
  }

  @override
  void didUpdateWidget(covariant RelationsGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize positions for new characters if any
    bool changed = false;
    for (final pj in widget.personajes) {
      if (!_positions.containsKey(pj['id'])) {
        changed = true;
        break;
      }
    }
    if (changed || widget.personajes.length != oldWidget.personajes.length) {
      _initializePositions();
    }
    
    // Resume physics on any selection/relationship updates
    if (widget.selectedPersonajeId != oldWidget.selectedPersonajeId ||
        widget.firstSelectedId != oldWidget.firstSelectedId ||
        widget.relaciones.length != oldWidget.relaciones.length) {
      _resumeTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _initializePositions() {
    final rand = Random(42); // Seeded random for stable initial positions
    final radius = widget.personajes.length <= 1 ? 0.0 : 250.0;
    
    Map<int, Offset> newPositions = {};
    Map<int, Offset> newVelocities = {};

    for (int i = 0; i < widget.personajes.length; i++) {
      final pj = widget.personajes[i];
      final id = pj['id'] as int;
      
      // Preserve existing position if valid
      if (_positions.containsKey(id)) {
        newPositions[id] = _positions[id]!;
        newVelocities[id] = _velocities[id] ?? Offset.zero;
        continue;
      }

      if (widget.personajes.length == 1) {
        newPositions[id] = center;
      } else {
        final angle = (2 * pi * i) / widget.personajes.length;
        // Radial positioning + slight random noise to avoid collinear configurations
        newPositions[id] = Offset(
          center.dx + radius * cos(angle) + (rand.nextDouble() - 0.5) * 10,
          center.dy + radius * sin(angle) + (rand.nextDouble() - 0.5) * 10,
        );
      }
      newVelocities[id] = Offset.zero;
    }

    setState(() {
      _positions = newPositions;
      _velocities = newVelocities;
    });
    _resumeTicker();
  }

  void _resumeTicker() {
    if (_ticker != null && !_ticker!.isActive) {
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (widget.personajes.isEmpty) return;

    // Parameters for force-directed layout
    const double kRepulsion = 15000.0;
    const double kSpring = 0.06;
    const double kRestingDistance = 180.0;
    const double kGravity = 0.015;
    const double kDamping = 0.75;
    const double kMaxVelocity = 12.0;

    Map<int, Offset> forces = {};
    for (final pj in widget.personajes) {
      forces[pj['id']] = Offset.zero;
    }

    // 1. Coulomb Repulsion between all nodes
    for (int i = 0; i < widget.personajes.length; i++) {
      final idA = widget.personajes[i]['id'] as int;
      final posA = _positions[idA];
      if (posA == null) continue;

      for (int j = i + 1; j < widget.personajes.length; j++) {
        final idB = widget.personajes[j]['id'] as int;
        final posB = _positions[idB];
        if (posB == null) continue;

        final delta = posA - posB;
        final distance = delta.distance;
        
        // Prevent division by zero
        final d = max(1.0, distance);
        if (d < 500.0) {
          // Repulsion force vector
          final forceMagnitude = kRepulsion / (d * d);
          final force = (delta / d) * forceMagnitude;

          forces[idA] = forces[idA]! + force;
          forces[idB] = forces[idB]! - force;
        }
      }
    }

    // 2. Hooke Attraction along relationships
    for (final rel in widget.relaciones) {
      final idA = rel['personaje_a_id'] as int;
      final idB = rel['personaje_b_id'] as int;
      
      final posA = _positions[idA];
      final posB = _positions[idB];
      if (posA == null || posB == null) continue;

      final delta = posB - posA;
      final distance = delta.distance;
      final d = max(1.0, distance);

      // Spring force vector
      final forceMagnitude = kSpring * (d - kRestingDistance);
      final force = (delta / d) * forceMagnitude;

      forces[idA] = forces[idA]! + force;
      forces[idB] = forces[idB]! - force;
    }

    // 3. Central Gravity (pull towards center)
    for (final pj in widget.personajes) {
      final id = pj['id'] as int;
      final pos = _positions[id];
      if (pos == null) continue;

      final delta = center - pos;
      forces[id] = forces[id]! + delta * kGravity;
    }

    // 4. Update Velocities and Positions
    double totalEnergy = 0.0;
    Map<int, Offset> nextPositions = {};
    Map<int, Offset> nextVelocities = {};

    for (final pj in widget.personajes) {
      final id = pj['id'] as int;
      if (id == _draggingId) {
        // Locked position for dragged node
        nextPositions[id] = _positions[id]!;
        nextVelocities[id] = Offset.zero;
        continue;
      }

      final pos = _positions[id]!;
      final force = forces[id]!;
      final vel = _velocities[id] ?? Offset.zero;

      // Integrate velocity: v = (v + F) * damping
      Offset newVel = (vel + force) * kDamping;
      
      // Limit speed to prevent instabilities
      if (newVel.distance > kMaxVelocity) {
        newVel = (newVel / newVel.distance) * kMaxVelocity;
      }

      final newPos = pos + newVel;
      
      // Keep nodes within canvas bounds
      final clampedPos = Offset(
        newPos.dx.clamp(50.0, canvasSize - 50.0),
        newPos.dy.clamp(50.0, canvasSize - 50.0),
      );

      nextPositions[id] = clampedPos;
      nextVelocities[id] = newVel;
      totalEnergy += newVel.distanceSquared;
    }

    setState(() {
      _positions = nextPositions;
      _velocities = nextVelocities;
    });

    // Pause physics engine if system has cooled down to save CPU
    if (totalEnergy < 0.05 && _draggingId == null) {
      _ticker?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.separator, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(400),
        minScale: 0.4,
        maxScale: 2.0,
        constrained: false,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              widget.onNodeTap(-1); // Deselect nodes on background tap
            },
            child: SizedBox(
              width: canvasSize,
              height: canvasSize,
              child: Stack(
              children: [
                // 1. Connection lines (CustomPaint)
                Positioned.fill(
                  child: CustomPaint(
                    painter: CharacterRelationsPainter(
                      positions: _positions,
                      relaciones: widget.relaciones,
                      selectedId: widget.selectedPersonajeId,
                    ),
                  ),
                ),

                // 2. Interactive draggable nodes
                ...widget.personajes.where((pj) => _positions.containsKey(pj['id'])).map((pj) {
                  final id = pj['id'] as int;
                  final pos = _positions[id]!;
                  final isSelected = widget.selectedPersonajeId == id;
                  final isFirstSelected = widget.firstSelectedId == id;
                  const double nodeRadius = 45.0;
                  const double outerRadius = 52.0;

                  return Positioned(
                    left: pos.dx - outerRadius,
                    top: pos.dy - outerRadius,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          widget.onNodeTap(id);
                          _resumeTicker();
                        },
                      onDoubleTap: () => widget.onNodeDoubleTap(id),
                      onPanStart: (details) {
                        setState(() {
                          _draggingId = id;
                        });
                        _resumeTicker();
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _positions[id] = Offset(
                            (_positions[id]!.dx + details.delta.dx).clamp(50.0, canvasSize - 50.0),
                            (_positions[id]!.dy + details.delta.dy).clamp(50.0, canvasSize - 50.0),
                          );
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _draggingId = null;
                        });
                        _resumeTicker();
                      },
                      child: SizedBox(
                        width: outerRadius * 2,
                        height: outerRadius * 2,
                        child: Center(
                          child: Container(
                            width: nodeRadius * 2,
                            height: nodeRadius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.accent
                                  : isFirstSelected
                                      ? Colors.orangeAccent
                                      : AppColors.surface,
                              border: Border.all(
                                color: isSelected || isFirstSelected
                                    ? Colors.white
                                    : AppColors.separator,
                                width: isSelected || isFirstSelected ? 3.0 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.15),
                                  blurRadius: isSelected ? 12 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Material(
                                color: Colors.transparent,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      pj['nombre'] ?? '',
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        color: isSelected || isFirstSelected
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
