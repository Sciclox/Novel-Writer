import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Pomodoro Timer Widget ─────────────────────────────
class PomodoroSection extends StatelessWidget {
  final bool isRunning;
  final int secondsRemaining;
  final int durationMinutes;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final ValueChanged<int> onSetDuration;

  const PomodoroSection({
    super.key,
    required this.isRunning,
    required this.secondsRemaining,
    required this.durationMinutes,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSetDuration,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final double progress = secondsRemaining / (durationMinutes * 60);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.03),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isRunning ? const Color(0xFF00F0FF) : const Color(0xFFAEAEB2),
                    ),
                  ),
                ),
                if (isRunning)
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isRunning ? Colors.white : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRunning ? 'ENFOQUE' : 'PAUSA',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isRunning ? const Color(0xFF00F0FF) : Colors.white24,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isRunning ? onPause : onStart,
                  borderRadius: BorderRadius.circular(50),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRunning
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isRunning ? const Color(0xFF00F0FF) : Colors.white24,
                      ),
                    ),
                    child: Icon(
                      isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isRunning ? const Color(0xFF00F0FF) : Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onReset,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.02),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(
                      Icons.replay_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [15, 25, 45, 60].map((mins) {
              final isCurrent = durationMinutes == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => onSetDuration(mins),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent ? const Color(0xFF00F0FF) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${mins}m',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isCurrent ? const Color(0xFF00F0FF) : Colors.white38,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── AppBar Pomodoro Indicator ─────────────────────────
class AppBarPomodoroTimer extends StatelessWidget {
  final bool isRunning;
  final int secondsRemaining;
  final int durationMinutes;

  const AppBarPomodoroTimer({
    super.key,
    required this.isRunning,
    required this.secondsRemaining,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRunning && secondsRemaining == durationMinutes * 60) {
      return Container();
    }
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Tooltip(
      message: isRunning ? 'Pomodoro activo. ¡Sigue escribiendo!' : 'Pomodoro pausado',
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isRunning ? const Color(0xFF00F0FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRunning ? const Color(0xFF00F0FF) : Colors.white24,
              width: 1,
            ),
            boxShadow: isRunning
                ? [BoxShadow(color: const Color(0xFF00F0FF).withValues(alpha: 0.15), blurRadius: 8)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_bottom_rounded,
                size: 14,
                color: isRunning ? const Color(0xFF00F0FF) : Colors.white30,
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isRunning ? const Color(0xFF00F0FF) : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Session Goal Widget ──────────────────────────────
class SessionGoalSection extends StatelessWidget {
  final int sessionWordGoal;
  final int sessionWordsWritten;
  final VoidCallback onEdit;

  const SessionGoalSection({
    super.key,
    required this.sessionWordGoal,
    required this.sessionWordsWritten,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    double progress = sessionWordGoal > 0 ? sessionWordsWritten / sessionWordGoal : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'META DE SESIÓN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Tooltip(
                    message: 'Editar meta de palabras',
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.edit_note_rounded, size: 18, color: const Color(0xFF00F0FF)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$sessionWordsWritten / $sessionWordGoal palabras',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F0FF), const Color(0xFFAEAEB2)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Stat Card ───────────────────────────────────
Widget buildMiniStatCard(String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF3A3A3C),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 14, color: color),
            Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 6),
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFFAEAEB2), fontWeight: FontWeight.w500, letterSpacing: 0.8)),
      ],
    ),
  );
}

// ── Save Status Indicator ────────────────────────────
enum SaveStatus { saved, saving, unsaved }

Widget buildSaveIndicator(SaveStatus status) {
  switch (status) {
    case SaveStatus.saved:
      return Row(
        children: [
          Tooltip(
            message: 'Todo guardado',
            child: const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4ADE80)),
          ),
          const SizedBox(width: 4),
          Text('Guardado', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4ADE80))),
        ],
      );
    case SaveStatus.saving:
      return Row(
        children: [
          Tooltip(
            message: 'Guardando...',
            child: const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
          ),
          const SizedBox(width: 6),
          Text('Guardando...', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF00F0FF))),
        ],
      );
    case SaveStatus.unsaved:
      return Row(
        children: [
          Tooltip(
            message: 'Cambios sin guardar',
            child: const Icon(Icons.circle, size: 8, color: Color(0xFFFB923C)),
          ),
          const SizedBox(width: 6),
          Text('Sin guardar', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFB923C))),
        ],
      );
  }
}

// ── Pomodoro Completion Overlay ──────────────────────
class PomodoroCompletionOverlay extends StatelessWidget {
  final int durationMinutes;
  final VoidCallback onClose;

  const PomodoroCompletionOverlay({
    super.key,
    required this.durationMinutes,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.1),
                    border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                        blurRadius: 20, spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00F0FF), size: 40),
                ),
                const SizedBox(height: 28),
                Text(
                  '¡POMODORO COMPLETADO!',
                  style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.bold,
                    color: const Color(0xFF00F0FF), letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Has mantenido la concentración durante $durationMinutes minutos. Es hora de tomar un breve descanso y estirar el cuerpo.',
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.white70, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 8,
                    shadowColor: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                  ),
                  child: Text(
                    'VOLVER AL EDITOR',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
