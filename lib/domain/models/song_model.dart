class SongModel {
  final String id;
  final String title;
  final String folderPath;
  final String originalMidiPath;
  final int durationMs;
  final int noteCount;
  final double bpm;
  final int attemptsCount;
  final double bestAccuracy;
  final DateTime createdAt;
  final String difficulty;
  final bool isBuiltIn;

  const SongModel({
    required this.id,
    required this.title,
    required this.folderPath,
    required this.originalMidiPath,
    this.durationMs = 0,
    this.noteCount = 0,
    this.bpm = 120.0,
    this.attemptsCount = 0,
    this.bestAccuracy = 0.0,
    required this.createdAt,
    this.difficulty = 'Medium',
    this.isBuiltIn = false,
  });

  SongModel copyWith({
    String? id,
    String? title,
    String? folderPath,
    String? originalMidiPath,
    int? durationMs,
    int? noteCount,
    double? bpm,
    int? attemptsCount,
    double? bestAccuracy,
    DateTime? createdAt,
    String? difficulty,
    bool? isBuiltIn,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      folderPath: folderPath ?? this.folderPath,
      originalMidiPath: originalMidiPath ?? this.originalMidiPath,
      durationMs: durationMs ?? this.durationMs,
      noteCount: noteCount ?? this.noteCount,
      bpm: bpm ?? this.bpm,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'folderPath': folderPath,
    'originalMidiPath': originalMidiPath,
    'durationMs': durationMs,
    'noteCount': noteCount,
    'bpm': bpm,
    'attemptsCount': attemptsCount,
    'bestAccuracy': bestAccuracy,
    'createdAt': createdAt.toIso8601String(),
    'difficulty': difficulty,
    'isBuiltIn': isBuiltIn,
  };

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
    id: json['id'] as String,
    title: json['title'] as String,
    folderPath: json['folderPath'] as String? ?? '',
    originalMidiPath: json['originalMidiPath'] as String? ?? '',
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    noteCount: (json['noteCount'] as num?)?.toInt() ?? 0,
    bpm: (json['bpm'] as num?)?.toDouble() ?? 120.0,
    attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
    bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0.0,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    difficulty: json['difficulty'] as String? ?? 'Medium',
    isBuiltIn: json['isBuiltIn'] as bool? ?? false,
  );
}
