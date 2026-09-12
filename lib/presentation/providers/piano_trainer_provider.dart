import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/piano_constants.dart';
import '../../data/repositories/attempt_repository.dart';
import '../../data/services/audio_synth_service.dart';
import '../../domain/models/attempt_record.dart';
import '../../domain/models/learning_session_state.dart';
import '../../domain/models/midi_note_event.dart';
import '../../domain/models/song_model.dart';
import '../../domain/use_cases/evaluate_performance_use_case.dart';
import '../../domain/use_cases/parse_midi_use_case.dart';
import 'song_providers.dart';

class PianoTrainerNotifier extends Notifier<LearningSessionState> {
  AudioSynthService get _audioSynth => ref.read(audioSynthServiceProvider);
  ParseMidiUseCase get _parseMidiUseCase => ref.read(parseMidiUseCaseProvider);
  AttemptRepository get _attemptRepository => ref.read(attemptRepositoryProvider);
  EvaluatePerformanceUseCase get _evaluateUseCase => ref.read(evaluatePerformanceUseCaseProvider);

  Timer? _playbackTimer;
  SongModel? _currentSong;
  List<MidiNoteEvent> _songNotes = [];
  PerformanceEvaluationResult? _lastEvaluation;

  SongModel? get currentSong => _currentSong;
  List<MidiNoteEvent> get songNotes => _songNotes;
  PerformanceEvaluationResult? get lastEvaluation => _lastEvaluation;

  @override
  LearningSessionState build() {
    ref.onDispose(() {
      _playbackTimer?.cancel();
    });
    return const LearningSessionState();
  }

  Future<void> loadSong(SongModel song) async {
    _currentSong = song;
    pause();

    try {
      final bytes = await ref.read(songRepositoryProvider).getSongMidiBytes(song);
      if (bytes.isNotEmpty) {
        final parsed = await _parseMidiUseCase.parseAsync(bytes);
        _songNotes = parsed.notes;
      } else {
        _songNotes = [];
      }
    } catch (e) {
      debugPrint('Error loading song notes: $e');
      _songNotes = [];
    }

    final totalDur = _songNotes.isNotEmpty
        ? _songNotes.map((n) => n.endTimeMs).reduce((a, b) => a > b ? a : b)
        : song.durationMs;

    int startNote = 48; // C3
    int endNote = 83;   // B5
    if (_songNotes.isNotEmpty) {
      final minPitch = _songNotes.map((n) => n.midiNote).reduce((a, b) => a < b ? a : b);
      final maxPitch = _songNotes.map((n) => n.midiNote).reduce((a, b) => a > b ? a : b);
      if (minPitch < startNote || maxPitch > endNote) {
        startNote = (minPitch ~/ 12) * 12;
        endNote = ((maxPitch ~/ 12) + 1) * 12 - 1;
      }
    }

    state = state.copyWith(
      currentPositionMs: 0,
      totalDurationMs: totalDur,
      status: PlaybackStatus.idle,
      currentStepNoteIndex: 0,
      startMidiNote: startNote,
      endMidiNote: endNote,
      activeTargetNotes: {},
      previewTargetNotes: {},
      currentlyPressedKeys: {},
      recordedPresses: [],
    );

    _updateTargetNoteHighlights();
  }

  void setMode(TrainerMode mode) {
    state = state.copyWith(mode: mode);
    _updateTargetNoteHighlights();
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
  }

  void setOctaveRange(int startNote, int endNote) {
    state = state.copyWith(
      startMidiNote: startNote,
      endMidiNote: endNote,
    );
  }

  void toggleNoteLabels() {
    state = state.copyWith(showNoteLabels: !state.showNoteLabels);
  }

  void toggleDeskCameraMode() {
    state = state.copyWith(isDeskCameraMode: !state.isDeskCameraMode);
  }

  void startRecording() {
    state = state.copyWith(
      isRecording: true,
      recordedPresses: [],
    );
  }

  Future<AttemptRecord?> stopRecording() async {
    if (!state.isRecording || _currentSong == null) return null;

    final evaluation = _evaluateUseCase.execute(
      targetNotes: _songNotes,
      userPresses: state.recordedPresses,
    );
    _lastEvaluation = evaluation;

    final record = await _attemptRepository.recordAttempt(
      song: _currentSong!,
      accuracyPercent: evaluation.accuracyPercent,
      avgTimingDeviationMs: evaluation.avgTimingDeviationMs,
      correctNotes: evaluation.correctNotes,
      missedNotes: evaluation.missedNotes,
      extraNotes: evaluation.extraNotes,
      totalNotes: evaluation.totalNotes,
      score: evaluation.score,
      grade: evaluation.grade,
      playedNotes: state.recordedPresses,
    );

    state = state.copyWith(isRecording: false);
    return record;
  }

  void play() {
    if (state.status == PlaybackStatus.playing) return;

    state = state.copyWith(status: PlaybackStatus.playing);
    _startTimer();
  }

  void pause() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  void reset() {
    pause();
    state = state.copyWith(
      currentPositionMs: 0,
      status: PlaybackStatus.idle,
      currentStepNoteIndex: 0,
      currentlyPressedKeys: {},
      recordedPresses: [],
    );
    _updateTargetNoteHighlights();
  }

  void seekTo(int positionMs) {
    state = state.copyWith(
      currentPositionMs: positionMs.clamp(0, state.totalDurationMs),
    );
    _updateTargetNoteHighlights();
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    const intervalMs = 25; // 40 ticks per second

    _playbackTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      final stepMs = (intervalMs * state.playbackSpeed).round();
      final newPos = state.currentPositionMs + stepMs;

      if (newPos >= state.totalDurationMs && state.totalDurationMs > 0) {
        timer.cancel();
        state = state.copyWith(
          currentPositionMs: state.totalDurationMs,
          status: PlaybackStatus.completed,
        );
        if (state.isRecording) {
          stopRecording();
        }
        return;
      }

      state = state.copyWith(currentPositionMs: newPos);

      // Auto-play mode triggers sound and key flash
      if (state.mode == TrainerMode.autoPlay) {
        _triggerAutoPlayNotes(newPos - stepMs, newPos);
      }

      _updateTargetNoteHighlights();
    });
  }

  void _triggerAutoPlayNotes(int fromMs, int toMs) {
    for (final note in _songNotes) {
      if (note.startTimeMs >= fromMs && note.startTimeMs < toMs) {
        _audioSynth.playNote(note.midiNote, velocity: note.velocity);
        _flashKey(note.midiNote);
      }
    }
  }

  void _flashKey(int midiNote) {
    final updated = Set<int>.from(state.currentlyPressedKeys)..add(midiNote);
    state = state.copyWith(currentlyPressedKeys: updated);

    Future.delayed(const Duration(milliseconds: 180), () {
      final released = Set<int>.from(state.currentlyPressedKeys)..remove(midiNote);
      state = state.copyWith(currentlyPressedKeys: released);
    });
  }

  /// User taps or presses a piano key
  void onUserKeyPress(int midiNote, {int velocity = 100}) {
    // 1. Play acoustic audio note immediately
    _audioSynth.playNote(midiNote, velocity: velocity);

    // 2. Visually highlight pressed key
    _flashKey(midiNote);

    // 3. Record press if recording session is active
    if (state.isRecording) {
      final press = UserNotePress(
        midiNote: midiNote,
        timestampMs: state.currentPositionMs,
        velocity: velocity,
      );
      state = state.copyWith(
        recordedPresses: [...state.recordedPresses, press],
      );
    }

    // 4. Handle Step-by-Step interactive learning mode
    if (state.mode == TrainerMode.stepByStep && _songNotes.isNotEmpty) {
      if (state.currentStepNoteIndex < _songNotes.length) {
        final expectedNote = _songNotes[state.currentStepNoteIndex];
        if (expectedNote.midiNote == midiNote) {
          // Success! Advance to next note
          final nextIdx = state.currentStepNoteIndex + 1;
          final nextNote = nextIdx < _songNotes.length ? _songNotes[nextIdx] : null;
          final noteName = PianoConstants.getNoteName(midiNote);

          if (nextIdx >= _songNotes.length) {
            state = state.copyWith(
              currentStepNoteIndex: nextIdx,
              currentPositionMs: state.totalDurationMs,
              status: PlaybackStatus.completed,
              feedbackMessage: '🎉 Song Completed! Excellent playing!',
              isFeedbackPositive: true,
            );
            if (state.isRecording) {
              stopRecording();
            }
          } else {
            final nextName = nextNote != null ? PianoConstants.getNoteName(nextNote.midiNote) : '';
            state = state.copyWith(
              currentStepNoteIndex: nextIdx,
              currentPositionMs: nextNote?.startTimeMs ?? state.totalDurationMs,
              feedbackMessage: '✨ Perfect! [$noteName] ➔ Next: [$nextName]',
              isFeedbackPositive: true,
            );
          }
          _updateTargetNoteHighlights();
        } else {
          final pressedName = PianoConstants.getNoteName(midiNote);
          final expectedName = PianoConstants.getNoteName(expectedNote.midiNote);
          state = state.copyWith(
            feedbackMessage: '⚠️ You played $pressedName. Look for glowing key $expectedName!',
            isFeedbackPositive: false,
          );
        }
      }
    }
  }

  void _updateTargetNoteHighlights() {
    if (state.mode == TrainerMode.professional || _songNotes.isEmpty) {
      state = state.copyWith(
        activeTargetNotes: {},
        previewTargetNotes: {},
      );
      return;
    }

    if (state.mode == TrainerMode.stepByStep) {
      if (state.currentStepNoteIndex < _songNotes.length) {
        final active = {_songNotes[state.currentStepNoteIndex].midiNote};
        final preview = <int>{};
        if (state.currentStepNoteIndex + 1 < _songNotes.length) {
          preview.add(_songNotes[state.currentStepNoteIndex + 1].midiNote);
        }
        state = state.copyWith(
          activeTargetNotes: active,
          previewTargetNotes: preview,
        );
      } else {
        state = state.copyWith(
          activeTargetNotes: {},
          previewTargetNotes: {},
        );
      }
      return;
    }

    // Auto-Play & Standard mode
    const previewWindowMs = 1500;
    final pos = state.currentPositionMs;

    final active = <int>{};
    final preview = <int>{};

    for (final note in _songNotes) {
      if (note.startTimeMs <= pos && note.endTimeMs >= pos) {
        active.add(note.midiNote);
      } else if (note.startTimeMs > pos && note.startTimeMs <= pos + previewWindowMs) {
        preview.add(note.midiNote);
      }
    }

    state = state.copyWith(
      activeTargetNotes: active,
      previewTargetNotes: preview,
    );
  }
}

final evaluatePerformanceUseCaseProvider = Provider<EvaluatePerformanceUseCase>((ref) {
  return EvaluatePerformanceUseCase();
});

final pianoTrainerProvider =
    NotifierProvider<PianoTrainerNotifier, LearningSessionState>(PianoTrainerNotifier.new);
