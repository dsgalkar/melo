import 'dart:math';
import '../models/midi_note_event.dart';

class PerformanceEvaluationResult {
  final double accuracyPercent;
  final double avgTimingDeviationMs;
  final int correctNotes;
  final int missedNotes;
  final int extraNotes;
  final int totalNotes;
  final int score;
  final String grade;

  const PerformanceEvaluationResult({
    required this.accuracyPercent,
    required this.avgTimingDeviationMs,
    required this.correctNotes,
    required this.missedNotes,
    required this.extraNotes,
    required this.totalNotes,
    required this.score,
    required this.grade,
  });
}

class EvaluatePerformanceUseCase {
  PerformanceEvaluationResult execute({
    required List<MidiNoteEvent> targetNotes,
    required List<UserNotePress> userPresses,
  }) {
    if (targetNotes.isEmpty) {
      return const PerformanceEvaluationResult(
        accuracyPercent: 100.0,
        avgTimingDeviationMs: 0.0,
        correctNotes: 0,
        missedNotes: 0,
        extraNotes: 0,
        totalNotes: 0,
        score: 0,
        grade: 'S',
      );
    }

    final totalTarget = targetNotes.length;
    final matchedTargetIndices = <int>{};
    final matchedUserIndices = <int>{};
    final deviations = <double>[];

    int correctCount = 0;
    int points = 0;

    // Tolerance window for timing matching (up to 400ms)
    const int maxToleranceMs = 400;

    for (int pIdx = 0; pIdx < userPresses.length; pIdx++) {
      final press = userPresses[pIdx];
      int bestTargetIdx = -1;
      int minDelta = 999999;

      for (int tIdx = 0; tIdx < targetNotes.length; tIdx++) {
        if (matchedTargetIndices.contains(tIdx)) continue;
        final target = targetNotes[tIdx];

        if (target.midiNote == press.midiNote) {
          final delta = (target.startTimeMs - press.timestampMs).abs();
          if (delta <= maxToleranceMs && delta < minDelta) {
            minDelta = delta;
            bestTargetIdx = tIdx;
          }
        }
      }

      if (bestTargetIdx != -1) {
        matchedTargetIndices.add(bestTargetIdx);
        matchedUserIndices.add(pIdx);
        deviations.add(minDelta.toDouble());
        correctCount++;

        // Scoring: 1000 for perfect (<100ms), 700 for good (<250ms), 400 for ok
        if (minDelta < 100) {
          points += 1000;
        } else if (minDelta < 250) {
          points += 700;
        } else {
          points += 400;
        }
      }
    }

    final missedCount = totalTarget - correctCount;
    final extraCount = max(0, userPresses.length - matchedUserIndices.length);

    final accuracy = (correctCount / totalTarget) * 100.0;
    final avgDeviation = deviations.isEmpty
        ? 0.0
        : deviations.reduce((a, b) => a + b) / deviations.length;

    // Grade calculation
    String grade;
    if (accuracy >= 95.0 && (avgDeviation < 120 || deviations.isEmpty)) {
      grade = 'S';
    } else if (accuracy >= 85.0) {
      grade = 'A';
    } else if (accuracy >= 70.0) {
      grade = 'B';
    } else if (accuracy >= 50.0) {
      grade = 'C';
    } else {
      grade = 'D';
    }

    return PerformanceEvaluationResult(
      accuracyPercent: double.parse(accuracy.toStringAsFixed(1)),
      avgTimingDeviationMs: double.parse(avgDeviation.toStringAsFixed(1)),
      correctNotes: correctCount,
      missedNotes: missedCount,
      extraNotes: extraCount,
      totalNotes: totalTarget,
      score: points,
      grade: grade,
    );
  }
}
