import 'package:flutter/material.dart';

class AppColors {
  // Brand Dark Palette
  static const Color background = Color(0xFF0D0F12);
  static const Color surface = Color(0xFF161A20);
  static const Color surfaceLight = Color(0xFF1F242D);
  static const Color surfaceBorder = Color(0xFF2E3544);
  
  // Neon & Gold Accents for Melo
  static const Color primaryGold = Color(0xFFFFC837);
  static const Color primaryAmber = Color(0xFFFF8008);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonPurple = Color(0xFFBD00FF);
  static const Color accentPink = Color(0xFFFF2A6D);
  static const Color error = Color(0xFFFF4B4B);

  // Piano Visual Colors
  static const Color whiteKeyFill = Color(0xFFF7F8FA);
  static const Color whiteKeyPressed = Color(0xFF81D4FA);
  static const Color blackKeyFill = Color(0xFF1B1E24);
  static const Color blackKeyPressed = Color(0xFF0288D1);

  // Guided Note Highlights
  static const Color activeNoteGlow = Color(0xFF00E676); // Emerald Green for Current Note
  static const Color previewNoteGlow = Color(0xFFFFC837); // Amber/Gold for Next Note
  static const Color hitNoteGlow = Color(0xFF00E5FF); // Cyan for Successful User Hit
  static const Color missNoteGlow = Color(0xFFFF5252); // Red for Missed/Wrong Note
}
