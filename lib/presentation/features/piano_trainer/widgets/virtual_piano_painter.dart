import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/piano_constants.dart';

class VirtualPianoPainter extends CustomPainter {
  final int startMidiNote;
  final int endMidiNote;
  final Set<int> currentlyPressedKeys;
  final Set<int> activeTargetNotes;
  final Set<int> previewTargetNotes;
  final bool showNoteLabels;

  VirtualPianoPainter({
    required this.startMidiNote,
    required this.endMidiNote,
    required this.currentlyPressedKeys,
    required this.activeTargetNotes,
    required this.previewTargetNotes,
    this.showNoteLabels = true,
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
    final whiteKeyHeight = size.height;
    final blackKeyWidth = whiteKeyWidth * 0.62;
    final blackKeyHeight = size.height * 0.63;

    // 1. Paint White Keys First
    for (int i = 0; i < whiteNotes.length; i++) {
      final note = whiteNotes[i];
      final rect = Rect.fromLTWH(i * whiteKeyWidth, 0, whiteKeyWidth, whiteKeyHeight);
      _paintWhiteKey(canvas, rect, note);
    }

    // 2. Paint Black Keys Over White Keys
    for (int i = 0; i < whiteNotes.length; i++) {
      final note = whiteNotes[i];
      // Next semitone
      final nextNote = note + 1;
      if (nextNote <= endMidiNote && PianoConstants.isBlackKey(nextNote)) {
        // Place black key right along the junction between white key i and i+1
        final x = (i + 1) * whiteKeyWidth - (blackKeyWidth / 2);
        final rect = Rect.fromLTWH(x, 0, blackKeyWidth, blackKeyHeight);
        _paintBlackKey(canvas, rect, nextNote);
      }
    }
  }

  void _paintWhiteKey(Canvas canvas, Rect rect, int midiNote) {
    final isPressed = currentlyPressedKeys.contains(midiNote);
    final isActive = activeTargetNotes.contains(midiNote);
    final isPreview = previewTargetNotes.contains(midiNote);

    final rrect = RRect.fromRectAndCorners(
      rect.deflate(0.5),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );

    // Background Fill
    Color topColor;
    Color bottomColor;

    if (isPressed) {
      topColor = AppColors.neonCyan.withValues(alpha: 0.85);
      bottomColor = AppColors.neonCyan;
    } else if (isActive) {
      topColor = AppColors.activeNoteGlow.withValues(alpha: 0.8);
      bottomColor = AppColors.activeNoteGlow;
    } else if (isPreview) {
      topColor = AppColors.previewNoteGlow.withValues(alpha: 0.35);
      bottomColor = AppColors.previewNoteGlow.withValues(alpha: 0.7);
    } else {
      topColor = Colors.white;
      bottomColor = const Color(0xFFE8ECEF);
    }

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [topColor, bottomColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // Key Border
    final borderPaint = Paint()
      ..color = isActive
          ? AppColors.activeNoteGlow
          : (isPressed ? AppColors.neonCyan : const Color(0xFFCBD2D9))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive || isPressed ? 2.5 : 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // Active Note Glow & Target Beacon
    if (isActive) {
      final glowPaint = Paint()
        ..color = AppColors.activeNoteGlow.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      canvas.drawRRect(rrect, glowPaint);

      // Target Beacon Ring at the lower third of the key
      final beaconCenter = Offset(rect.left + rect.width / 2, rect.bottom - 44);
      final beaconBgPaint = Paint()..color = Colors.black87;
      canvas.drawCircle(beaconCenter, 12, beaconBgPaint);

      final beaconRingPaint = Paint()
        ..color = AppColors.activeNoteGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(beaconCenter, 12, beaconRingPaint);

      // Downward pointer triangle
      final arrowPath = Path()
        ..moveTo(beaconCenter.dx - 5, beaconCenter.dy - 3)
        ..lineTo(beaconCenter.dx + 5, beaconCenter.dy - 3)
        ..lineTo(beaconCenter.dx, beaconCenter.dy + 4)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.activeNoteGlow);
    }

    // Note Labels (Note name, Solfège, and PC Keyboard shortcut)
    if (showNoteLabels) {
      final noteName = PianoConstants.getNoteName(midiNote);
      final solfege = PianoConstants.getSolfege(midiNote);
      final qwertyKey = PianoConstants.getQwertyKeyForMidi(midiNote);
      final isC = noteName.startsWith('C') && !noteName.startsWith('C#');

      // Primary Note Name (e.g. C4)
      final textSpan = TextSpan(
        text: noteName,
        style: TextStyle(
          color: isPressed || isActive
              ? Colors.black87
              : (isC ? AppColors.primaryAmber : Colors.black87),
          fontSize: 11,
          fontWeight: isC || isActive || isPressed ? FontWeight.w900 : FontWeight.bold,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textPos = Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.bottom - tp.height - 8,
      );
      tp.paint(canvas, textPos);

      // Solfège / QWERTY Keyboard hint above the note name
      if (rect.height > 90) {
        final subLabel = qwertyKey != null ? '[$qwertyKey]' : solfege;
        final subSpan = TextSpan(
          text: subLabel,
          style: TextStyle(
            color: isPressed || isActive
                ? Colors.black54
                : (isC ? AppColors.primaryGold : Colors.black38),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        final subTp = TextPainter(
          text: subSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final subPos = Offset(
          rect.left + (rect.width - subTp.width) / 2,
          rect.bottom - tp.height - subTp.height - 10,
        );
        subTp.paint(canvas, subPos);
      }
    }
  }

  void _paintBlackKey(Canvas canvas, Rect rect, int midiNote) {
    final isPressed = currentlyPressedKeys.contains(midiNote);
    final isActive = activeTargetNotes.contains(midiNote);
    final isPreview = previewTargetNotes.contains(midiNote);

    final rrect = RRect.fromRectAndCorners(
      rect.deflate(0.5),
      bottomLeft: const Radius.circular(5),
      bottomRight: const Radius.circular(5),
    );

    Color topColor;
    Color bottomColor;

    if (isPressed) {
      topColor = AppColors.neonCyan;
      bottomColor = const Color(0xFF0091EA);
    } else if (isActive) {
      topColor = AppColors.activeNoteGlow;
      bottomColor = const Color(0xFF00B248);
    } else if (isPreview) {
      topColor = AppColors.previewNoteGlow;
      bottomColor = const Color(0xFFFF8F00);
    } else {
      topColor = const Color(0xFF32363E);
      bottomColor = const Color(0xFF14161A);
    }

    // Shadow
    canvas.drawRRect(
      rrect.shift(const Offset(1, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // Key Body
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [topColor, bottomColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // Glossy Highlight Line
    if (!isPressed && !isActive) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(rect.left + 2, rect.top + 2),
        Offset(rect.right - 2, rect.top + 2),
        highlightPaint,
      );
    }

    // Active Note Glow & Target Beacon on Black Key
    if (isActive) {
      final glowPaint = Paint()
        ..color = AppColors.activeNoteGlow.withValues(alpha: 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
      canvas.drawRRect(rrect, glowPaint);

      final beaconCenter = Offset(rect.left + rect.width / 2, rect.bottom - 26);
      canvas.drawCircle(beaconCenter, 8, Paint()..color = Colors.black);
      canvas.drawCircle(
        beaconCenter,
        8,
        Paint()
          ..color = AppColors.activeNoteGlow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Note Label on Black Key
    if (showNoteLabels) {
      final noteName = PianoConstants.getNoteName(midiNote);
      final qwertyKey = PianoConstants.getQwertyKeyForMidi(midiNote);
      final label = qwertyKey != null ? '[$qwertyKey]' : noteName;

      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: isPressed || isActive ? Colors.black87 : Colors.white70,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textPos = Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.bottom - tp.height - 5,
      );
      tp.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(covariant VirtualPianoPainter oldDelegate) {
    return oldDelegate.startMidiNote != startMidiNote ||
        oldDelegate.endMidiNote != endMidiNote ||
        oldDelegate.currentlyPressedKeys != currentlyPressedKeys ||
        oldDelegate.activeTargetNotes != activeTargetNotes ||
        oldDelegate.previewTargetNotes != previewTargetNotes ||
        oldDelegate.showNoteLabels != showNoteLabels;
  }
}
