class PianoConstants {
  // Standard Piano range
  // Full: 21 (A0) to 108 (C8) = 88 keys
  // Default Melo view: C3 (48) to B5 (83) = 3 octaves (36 keys)
  // 5 Octaves: C2 (36) to B6 (95) = 60 keys
  static const int minMidiNote = 21; // A0
  static const int maxMidiNote = 108; // C8

  static const int defaultStartNote = 48; // C3
  static const int defaultEndNote = 83; // B5 (3 full octaves)

  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const List<int> blackKeyIndices = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#

  static bool isBlackKey(int midiNote) {
    return blackKeyIndices.contains(midiNote % 12);
  }

  static String getNoteName(int midiNote, {bool includeOctave = true}) {
    if (midiNote < 0 || midiNote > 127) return '??';
    final name = noteNames[midiNote % 12];
    final octave = (midiNote ~/ 12) - 1;
    return includeOctave ? '$name$octave' : name;
  }

  static const List<String> solfegeNames = [
    'Do', 'Do♯', 'Re', 'Re♯', 'Mi', 'Fa', 'Fa♯', 'Sol', 'Sol♯', 'La', 'La♯', 'Si'
  ];

  static String getSolfege(int midiNote) {
    if (midiNote < 0 || midiNote > 127) return '';
    return solfegeNames[midiNote % 12];
  }

  // QWERTY keyboard map: key character -> MIDI note (centered around Octave 4/5)
  static const Map<String, int> qwertyKeyToMidi = {
    'a': 60, // C4
    'w': 61, // C#4
    's': 62, // D4
    'e': 63, // D#4
    'd': 64, // E4
    'f': 65, // F4
    't': 66, // F#4
    'g': 67, // G4
    'y': 68, // G#4
    'h': 69, // A4
    'u': 70, // A#4
    'j': 71, // B4
    'k': 72, // C5
    'o': 73, // C#5
    'l': 74, // D5
    'p': 75, // D#5
    ';': 76, // E5
    "'": 77, // F5
  };

  static String? getQwertyKeyForMidi(int midiNote) {
    for (final entry in qwertyKeyToMidi.entries) {
      if (entry.value == midiNote) return entry.key.toUpperCase();
    }
    return null;
  }

  // Audio frequency in Hz for standard tuning A4 = 440 Hz
  static double getFrequency(int midiNote) {
    return 440.0 * (1 << ((midiNote - 69) ~/ 12)) * 
        (1.0 + ((midiNote - 69) % 12) * 0.059463094359);
  }
}
