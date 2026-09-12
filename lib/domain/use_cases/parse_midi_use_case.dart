import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dart_midi_pro/dart_midi_pro.dart';
import '../models/midi_note_event.dart';

class ParsedMidiResult {
  final List<MidiNoteEvent> notes;
  final int durationMs;
  final double bpm;
  final int trackCount;

  const ParsedMidiResult({
    required this.notes,
    required this.durationMs,
    required this.bpm,
    required this.trackCount,
  });
}

class ParseMidiUseCase {
  /// Parse MIDI bytes asynchronously in an isolate to avoid blocking the main UI thread.
  Future<ParsedMidiResult> parseAsync(Uint8List bytes) async {
    return compute(_parseMidiInternal, bytes);
  }

  /// Synchronous fallback when running in non-isolate contexts
  ParsedMidiResult parseSync(Uint8List bytes) {
    return _parseMidiInternal(bytes);
  }
}

ParsedMidiResult _parseMidiInternal(Uint8List bytes) {
  final parser = MidiParser();
  final midiFile = parser.parseMidiFromBuffer(bytes);

  final ticksPerBeat = midiFile.header.ticksPerBeat ?? 480;
  double currentMicrosecondsPerBeat = 500000.0; // Default 120 BPM

  final allNotes = <MidiNoteEvent>[];
  int maxDurationMs = 0;

  // First pass: look for tempo events in track 0 (or all tracks)
  for (final track in midiFile.tracks) {
    for (final event in track) {
      if (event is SetTempoEvent) {
        if (event.microsecondsPerBeat > 0) {
          currentMicrosecondsPerBeat = event.microsecondsPerBeat.toDouble();
          break;
        }
      }
    }
  }

  final bpm = 60000000.0 / currentMicrosecondsPerBeat;

  // Process tracks
  for (int trackIdx = 0; trackIdx < midiFile.tracks.length; trackIdx++) {
    final track = midiFile.tracks[trackIdx];
    double currentMs = 0.0;
    double msPerTick = (currentMicrosecondsPerBeat / 1000.0) / ticksPerBeat;

    // Track open notes: noteNumber -> list of open note start times & velocities
    final openNotes = <int, List<_PendingNote>>{};

    for (final event in track) {
      final deltaTicks = event.deltaTime;
      currentMs += deltaTicks * msPerTick;

      if (event is SetTempoEvent) {
        if (event.microsecondsPerBeat > 0) {
          currentMicrosecondsPerBeat = event.microsecondsPerBeat.toDouble();
          msPerTick = (currentMicrosecondsPerBeat / 1000.0) / ticksPerBeat;
        }
      } else if (event is NoteOnEvent) {
        final noteNum = event.noteNumber;
        final vel = event.velocity;

        if (vel > 0) {
          // Note On
          openNotes.putIfAbsent(noteNum, () => []).add(
            _PendingNote(
              noteNumber: noteNum,
              velocity: vel,
              startTimeMs: currentMs.round(),
              trackIndex: trackIdx,
            ),
          );
        } else {
          // Note On with velocity 0 is Note Off
          _closeNote(openNotes, noteNum, currentMs.round(), allNotes);
        }
      } else if (event is NoteOffEvent) {
        final noteNum = event.noteNumber;
        _closeNote(openNotes, noteNum, currentMs.round(), allNotes);
      }
    }

    // Close any dangling open notes
    for (final noteList in openNotes.values) {
      for (final pending in noteList) {
        final duration = max(100, currentMs.round() - pending.startTimeMs);
        allNotes.add(
          MidiNoteEvent(
            midiNote: pending.noteNumber,
            velocity: pending.velocity,
            startTimeMs: pending.startTimeMs,
            durationMs: duration,
            trackIndex: pending.trackIndex,
          ),
        );
      }
    }
  }

  // Sort notes chronologically
  allNotes.sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

  if (allNotes.isNotEmpty) {
    maxDurationMs = allNotes.map((n) => n.endTimeMs).reduce(max);
  }

  return ParsedMidiResult(
    notes: allNotes,
    durationMs: maxDurationMs,
    bpm: double.parse(bpm.toStringAsFixed(1)),
    trackCount: midiFile.tracks.length,
  );
}

void _closeNote(
  Map<int, List<_PendingNote>> openNotes,
  int noteNum,
  int currentMs,
  List<MidiNoteEvent> results,
) {
  final list = openNotes[noteNum];
  if (list != null && list.isNotEmpty) {
    final pending = list.removeAt(0);
    final duration = max(60, currentMs - pending.startTimeMs);
    results.add(
      MidiNoteEvent(
        midiNote: pending.noteNumber,
        velocity: pending.velocity,
        startTimeMs: pending.startTimeMs,
        durationMs: duration,
        trackIndex: pending.trackIndex,
      ),
    );
  }
}

class _PendingNote {
  final int noteNumber;
  final int velocity;
  final int startTimeMs;
  final int trackIndex;

  _PendingNote({
    required this.noteNumber,
    required this.velocity,
    required this.startTimeMs,
    required this.trackIndex,
  });
}
