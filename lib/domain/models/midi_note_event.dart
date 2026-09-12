import '../../core/constants/piano_constants.dart';

class MidiNoteEvent {
  final int midiNote;
  final int velocity;
  final int startTimeMs;
  final int durationMs;
  final int trackIndex;

  const MidiNoteEvent({
    required this.midiNote,
    required this.velocity,
    required this.startTimeMs,
    required this.durationMs,
    this.trackIndex = 0,
  });

  String get noteName => PianoConstants.getNoteName(midiNote);
  bool get isBlackKey => PianoConstants.isBlackKey(midiNote);
  int get endTimeMs => startTimeMs + durationMs;

  Map<String, dynamic> toJson() => {
    'midiNote': midiNote,
    'velocity': velocity,
    'startTimeMs': startTimeMs,
    'durationMs': durationMs,
    'trackIndex': trackIndex,
  };

  factory MidiNoteEvent.fromJson(Map<String, dynamic> json) => MidiNoteEvent(
    midiNote: json['midiNote'] as int,
    velocity: (json['velocity'] as num?)?.toInt() ?? 80,
    startTimeMs: json['startTimeMs'] as int,
    durationMs: json['durationMs'] as int,
    trackIndex: (json['trackIndex'] as num?)?.toInt() ?? 0,
  );
}

class UserNotePress {
  final int midiNote;
  final int timestampMs;
  final int durationMs;
  final int velocity;

  const UserNotePress({
    required this.midiNote,
    required this.timestampMs,
    this.durationMs = 200,
    this.velocity = 100,
  });

  Map<String, dynamic> toJson() => {
    'midiNote': midiNote,
    'timestampMs': timestampMs,
    'durationMs': durationMs,
    'velocity': velocity,
  };

  factory UserNotePress.fromJson(Map<String, dynamic> json) => UserNotePress(
    midiNote: json['midiNote'] as int,
    timestampMs: json['timestampMs'] as int,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 200,
    velocity: (json['velocity'] as num?)?.toInt() ?? 100,
  );
}
