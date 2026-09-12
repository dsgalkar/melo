import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/piano_constants.dart';
import '../../../../domain/models/midi_note_event.dart';

class FallingNotesWaterfall extends StatelessWidget {
  final List<MidiNoteEvent> notes;
  final int currentPositionMs;
  final int startMidiNote;
  final int endMidiNote;
  final int lookaheadMs;

  const FallingNotesWaterfall({
    super.key,
    required this.notes,
    required this.currentPositionMs,
    required this.startMidiNote,
    required this.endMidiNote,
    this.lookaheadMs = 2500,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FallingNotesPainter(
        notes: notes,
        currentPositionMs: currentPositionMs,
        startMidiNote: startMidiNote,
        endMidiNote: endMidiNote,
        lookaheadMs: lookaheadMs,
      ),
    );
  }
}

class _FallingNotesPainter extends CustomPainter {
  final List<MidiNoteEvent> notes;
  final int currentPositionMs;
  final int startMidiNote;
  final int endMidiNote;
  final int lookaheadMs;

  _FallingNotesPainter({
    required this.notes,
    required this.currentPositionMs,
    required this.startMidiNote,
    required this.endMidiNote,
    required this.lookaheadMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final whiteNotes = <int>[];
    for (int note = startMidiNote; note <= endMidiNote; note++) {
      if (!PianoConstants.isBlackKey(note)) {
        whiteNotes.add(note);
      }
    }

    if (whiteNotes.isEmpty) return;

    final whiteKeyWidth = size.width / whiteNotes.length;
    final blackKeyWidth = whiteKeyWidth * 0.62;

    // Draw subtle vertical lane grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= whiteNotes.length; i++) {
      final x = i * whiteKeyWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw hit threshold line near bottom
    final hitLinePaint = Paint()
      ..color = AppColors.primaryGold.withValues(alpha: 0.4)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      hitLinePaint,
    );

    // Compute active window of notes to render
    final windowStartMs = currentPositionMs - 200;
    final windowEndMs = currentPositionMs + lookaheadMs;

    for (final note in notes) {
      if (note.endTimeMs < windowStartMs || note.startTimeMs > windowEndMs) {
        continue;
      }
      if (note.midiNote < startMidiNote || note.midiNote > endMidiNote) {
        continue;
      }

      // Calculate horizontal position
      double x = 0.0;
      double width = 0.0;
      final isBlack = PianoConstants.isBlackKey(note.midiNote);

      if (isBlack) {
        // Find adjacent white note
        int prevWhiteIdx = -1;
        for (int i = 0; i < whiteNotes.length; i++) {
          if (whiteNotes[i] == note.midiNote - 1) {
            prevWhiteIdx = i;
            break;
          }
        }
        if (prevWhiteIdx != -1) {
          x = (prevWhiteIdx + 1) * whiteKeyWidth - (blackKeyWidth / 2);
          width = blackKeyWidth;
        }
      } else {
        final whiteIdx = whiteNotes.indexOf(note.midiNote);
        if (whiteIdx != -1) {
          x = whiteIdx * whiteKeyWidth;
          width = whiteKeyWidth;
        }
      }

      if (width == 0.0) continue;

      // Calculate vertical position (falling down towards size.height)
      // When note.startTimeMs == currentPositionMs, bottom of note is at size.height
      final timeFromNow = note.startTimeMs - currentPositionMs;
      final bottomY = size.height - (timeFromNow / lookaheadMs) * size.height;
      final noteHeight = (note.durationMs / lookaheadMs) * size.height;
      final topY = bottomY - noteHeight.clamp(14.0, size.height);

      final rect = Rect.fromLTRB(x + 2, topY, x + width - 2, bottomY);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      // Note Colors
      final isNearHit = (timeFromNow).abs() < 120;
      final Color noteColor = isNearHit
          ? AppColors.activeNoteGlow
          : (isBlack ? AppColors.neonPurple : AppColors.neonCyan);

      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            noteColor.withValues(alpha: 0.8),
            noteColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);

      canvas.drawRRect(rrect, barPaint);

      // Glow when near the keyboard line
      if (isNearHit) {
        final glowPaint = Paint()
          ..color = AppColors.activeNoteGlow.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
        canvas.drawRRect(rrect, glowPaint);
      }

      // Note label on falling note bar
      if (rect.height >= 16 && rect.width >= 12) {
        final noteName = PianoConstants.getNoteName(note.midiNote);
        final tp = TextPainter(
          text: TextSpan(
            text: noteName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 3),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        if (tp.width <= rect.width) {
          final tpPos = Offset(
            rect.left + (rect.width - tp.width) / 2,
            rect.bottom - tp.height - 2,
          );
          tp.paint(canvas, tpPos);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FallingNotesPainter oldDelegate) {
    return oldDelegate.currentPositionMs != currentPositionMs ||
        oldDelegate.lookaheadMs != lookaheadMs ||
        oldDelegate.startMidiNote != startMidiNote ||
        oldDelegate.endMidiNote != endMidiNote ||
        oldDelegate.notes != notes;
  }
}
