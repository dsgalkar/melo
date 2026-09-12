import 'midi_note_event.dart';

class AttemptRecord {
  final String id;
  final String songId;
  final String songTitle;
  final String fileName;
  final String filePath;
  final int attemptNumber;
  final DateTime timestamp;
  final double accuracyPercent;
  final double avgTimingDeviationMs;
  final int correctNotes;
  final int missedNotes;
  final int extraNotes;
  final int totalNotes;
  final int score;
  final String grade; // S, A, B, C, D
  final List<UserNotePress> playedNotes;

  const AttemptRecord({
    required this.id,
    required this.songId,
    required this.songTitle,
    required this.fileName,
    required this.filePath,
    required this.attemptNumber,
    required this.timestamp,
    required this.accuracyPercent,
    required this.avgTimingDeviationMs,
    required this.correctNotes,
    required this.missedNotes,
    required this.extraNotes,
    required this.totalNotes,
    required this.score,
    required this.grade,
    this.playedNotes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'songId': songId,
    'songTitle': songTitle,
    'fileName': fileName,
    'filePath': filePath,
    'attemptNumber': attemptNumber,
    'timestamp': timestamp.toIso8601String(),
    'accuracyPercent': accuracyPercent,
    'avgTimingDeviationMs': avgTimingDeviationMs,
    'correctNotes': correctNotes,
    'missedNotes': missedNotes,
    'extraNotes': extraNotes,
    'totalNotes': totalNotes,
    'score': score,
    'grade': grade,
    'playedNotes': playedNotes.map((e) => e.toJson()).toList(),
  };

  factory AttemptRecord.fromJson(Map<String, dynamic> json) => AttemptRecord(
    id: json['id'] as String,
    songId: json['songId'] as String,
    songTitle: json['songTitle'] as String? ?? 'Untitled',
    fileName: json['fileName'] as String? ?? '',
    filePath: json['filePath'] as String? ?? '',
    attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
    accuracyPercent: (json['accuracyPercent'] as num?)?.toDouble() ?? 0.0,
    avgTimingDeviationMs: (json['avgTimingDeviationMs'] as num?)?.toDouble() ?? 0.0,
    correctNotes: (json['correctNotes'] as num?)?.toInt() ?? 0,
    missedNotes: (json['missedNotes'] as num?)?.toInt() ?? 0,
    extraNotes: (json['extraNotes'] as num?)?.toInt() ?? 0,
    totalNotes: (json['totalNotes'] as num?)?.toInt() ?? 0,
    score: (json['score'] as num?)?.toInt() ?? 0,
    grade: json['grade'] as String? ?? 'C',
    playedNotes: (json['playedNotes'] as List<dynamic>?)
            ?.map((e) => UserNotePress.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
