import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_midi_pro/dart_midi_pro.dart';
import 'package:melo/domain/use_cases/parse_midi_use_case.dart';
import 'package:melo/domain/use_cases/evaluate_performance_use_case.dart';
import 'package:melo/domain/models/midi_note_event.dart';

void main() {
  group('ParseMidiUseCase Tests', () {
    test('parses synthetic MIDI bytes into note sequence accurately', () {
      final header = MidiHeader(format: 1, numTracks: 1, ticksPerBeat: 480);
      final noteOn = NoteOnEvent()
        ..noteNumber = 60 // Middle C (C4)
        ..velocity = 90
        ..deltaTime = 0;
      final noteOff = NoteOffEvent()
        ..noteNumber = 60
        ..velocity = 0
        ..deltaTime = 480; // 1 beat

      final end = EndOfTrackEvent()..deltaTime = 0;

      final midiFile = MidiFile([[noteOn, noteOff, end]], header);
      final writer = MidiWriter();
      final bytes = Uint8List.fromList(writer.writeMidiToBuffer(midiFile));

      final useCase = ParseMidiUseCase();
      final result = useCase.parseSync(bytes);

      expect(result.notes.length, 1);
      expect(result.notes.first.midiNote, 60);
      expect(result.notes.first.startTimeMs, 0);
      expect(result.notes.first.durationMs, greaterThanOrEqualTo(400));
    });
  });

  group('EvaluatePerformanceUseCase Tests', () {
    test('calculates 100% accuracy and S grade on perfect match', () {
      final targetNotes = [
        const MidiNoteEvent(midiNote: 60, velocity: 80, startTimeMs: 0, durationMs: 400),
        const MidiNoteEvent(midiNote: 62, velocity: 80, startTimeMs: 500, durationMs: 400),
        const MidiNoteEvent(midiNote: 64, velocity: 80, startTimeMs: 1000, durationMs: 400),
      ];

      final userPresses = [
        const UserNotePress(midiNote: 60, timestampMs: 10),
        const UserNotePress(midiNote: 62, timestampMs: 515),
        const UserNotePress(midiNote: 64, timestampMs: 995),
      ];

      final evaluator = EvaluatePerformanceUseCase();
      final result = evaluator.execute(
        targetNotes: targetNotes,
        userPresses: userPresses,
      );

      expect(result.accuracyPercent, 100.0);
      expect(result.correctNotes, 3);
      expect(result.missedNotes, 0);
      expect(result.extraNotes, 0);
      expect(result.grade, 'S');
      expect(result.avgTimingDeviationMs, lessThan(20.0));
    });
  });
}
