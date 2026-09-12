import 'midi_note_event.dart';

enum TrainerMode {
  autoPlay,     // Plays notes automatically, user listens & observes highlights
  stepByStep,   // Pauses song playback until user presses the correct note
  professional, // Unassisted playback - test skills without visual guides
}

enum PlaybackStatus {
  idle,
  playing,
  paused,
  completed,
}

class LearningSessionState {
  final TrainerMode mode;
  final PlaybackStatus status;
  final int currentPositionMs;
  final int totalDurationMs;
  final double playbackSpeed;
  final int startMidiNote;
  final int endMidiNote;
  final bool showNoteLabels;
  final bool isDeskCameraMode;
  final bool isRecording;
  final Set<int> activeTargetNotes;
  final Set<int> previewTargetNotes;
  final Set<int> currentlyPressedKeys;
  final List<UserNotePress> recordedPresses;
  final int currentStepNoteIndex;
  final String? feedbackMessage;
  final bool isFeedbackPositive;

  const LearningSessionState({
    this.mode = TrainerMode.stepByStep,
    this.status = PlaybackStatus.idle,
    this.currentPositionMs = 0,
    this.totalDurationMs = 0,
    this.playbackSpeed = 1.0,
    this.startMidiNote = 48, // C3
    this.endMidiNote = 83,   // B5 (3 full octaves)
    this.showNoteLabels = true,
    this.isDeskCameraMode = false,
    this.isRecording = false,
    this.activeTargetNotes = const {},
    this.previewTargetNotes = const {},
    this.currentlyPressedKeys = const {},
    this.recordedPresses = const [],
    this.currentStepNoteIndex = 0,
    this.feedbackMessage,
    this.isFeedbackPositive = true,
  });

  LearningSessionState copyWith({
    TrainerMode? mode,
    PlaybackStatus? status,
    int? currentPositionMs,
    int? totalDurationMs,
    double? playbackSpeed,
    int? startMidiNote,
    int? endMidiNote,
    bool? showNoteLabels,
    bool? isDeskCameraMode,
    bool? isRecording,
    Set<int>? activeTargetNotes,
    Set<int>? previewTargetNotes,
    Set<int>? currentlyPressedKeys,
    List<UserNotePress>? recordedPresses,
    int? currentStepNoteIndex,
    String? feedbackMessage,
    bool? isFeedbackPositive,
  }) {
    return LearningSessionState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      startMidiNote: startMidiNote ?? this.startMidiNote,
      endMidiNote: endMidiNote ?? this.endMidiNote,
      showNoteLabels: showNoteLabels ?? this.showNoteLabels,
      isDeskCameraMode: isDeskCameraMode ?? this.isDeskCameraMode,
      isRecording: isRecording ?? this.isRecording,
      activeTargetNotes: activeTargetNotes ?? this.activeTargetNotes,
      previewTargetNotes: previewTargetNotes ?? this.previewTargetNotes,
      currentlyPressedKeys: currentlyPressedKeys ?? this.currentlyPressedKeys,
      recordedPresses: recordedPresses ?? this.recordedPresses,
      currentStepNoteIndex: currentStepNoteIndex ?? this.currentStepNoteIndex,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      isFeedbackPositive: isFeedbackPositive ?? this.isFeedbackPositive,
    );
  }
}
