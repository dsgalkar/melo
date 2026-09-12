import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/models/attempt_record.dart';
import '../../domain/models/midi_note_event.dart';
import '../../domain/models/song_model.dart';

class FileStorageService {
  Directory? _rootVirtualPianoDir;
  final Map<String, SongModel> _webSongCache = {};
  final Map<String, List<AttemptRecord>> _webAttemptsCache = {};
  final Map<String, Uint8List> _midiBytesCache = {};

  Future<Directory> getRootDirectory() async {
    if (_rootVirtualPianoDir != null) return _rootVirtualPianoDir!;

    if (kIsWeb) {
      _rootVirtualPianoDir = Directory('/VirtualPiano');
      return _rootVirtualPianoDir!;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final vpDir = Directory('${docDir.path}/VirtualPiano');
    if (!await vpDir.exists()) {
      await vpDir.create(recursive: true);
    }
    _rootVirtualPianoDir = vpDir;
    return vpDir;
  }

  String sanitizeName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim()
        .replaceAll(' ', '_');
  }

  /// Retrieve the binary MIDI bytes for a song across Web and Desktop
  Future<Uint8List> getSongMidiBytes(SongModel song) async {
    // 1. Check in-memory cache
    if (_midiBytesCache.containsKey(song.id)) {
      return _midiBytesCache[song.id]!;
    }
    if (_midiBytesCache.containsKey(song.originalMidiPath)) {
      return _midiBytesCache[song.originalMidiPath]!;
    }

    // 2. Check bundled Flutter asset path
    if (song.originalMidiPath.startsWith('assets/')) {
      try {
        final byteData = await rootBundle.load(song.originalMidiPath);
        final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        _midiBytesCache[song.id] = bytes;
        _midiBytesCache[song.originalMidiPath] = bytes;
        return bytes;
      } catch (e) {
        debugPrint('FileStorageService: error loading asset ${song.originalMidiPath}: $e');
      }
    }

    // 3. Check local filesystem if not web
    if (!kIsWeb) {
      try {
        final file = File(song.originalMidiPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _midiBytesCache[song.id] = bytes;
          _midiBytesCache[song.originalMidiPath] = bytes;
          return bytes;
        }
      } catch (e) {
        debugPrint('FileStorageService: error reading file ${song.originalMidiPath}: $e');
      }
    }

    return Uint8List(0);
  }

  /// Create a new song directory under `/VirtualPiano/<song_name>/`
  /// with `original.mid` and empty `attempts/` folder
  Future<SongModel> createSongFolder({
    required String songName,
    required Uint8List midiBytes,
    int durationMs = 0,
    int noteCount = 0,
    double bpm = 120.0,
    String difficulty = 'Medium',
    bool isBuiltIn = false,
    String? customMidiPath,
  }) async {
    final sanitized = sanitizeName(songName);
    final songId = '${sanitized}_${DateTime.now().millisecondsSinceEpoch}';

    // Store in bytes cache
    _midiBytesCache[songId] = midiBytes;

    if (kIsWeb) {
      final midiPath = customMidiPath ?? '/VirtualPiano/$sanitized/original.mid';
      final song = SongModel(
        id: songId,
        title: songName,
        folderPath: '/VirtualPiano/$sanitized',
        originalMidiPath: midiPath,
        durationMs: durationMs,
        noteCount: noteCount,
        bpm: bpm,
        createdAt: DateTime.now(),
        difficulty: difficulty,
        isBuiltIn: isBuiltIn,
      );
      _midiBytesCache[midiPath] = midiBytes;
      _webSongCache[songId] = song;
      return song;
    }

    final rootDir = await getRootDirectory();
    final songDir = Directory('${rootDir.path}/$sanitized');
    if (!await songDir.exists()) {
      await songDir.create(recursive: true);
    }

    final attemptsDir = Directory('${songDir.path}/attempts');
    if (!await attemptsDir.exists()) {
      await attemptsDir.create(recursive: true);
    }

    final midiFile = File('${songDir.path}/original.mid');
    await midiFile.writeAsBytes(midiBytes);

    final song = SongModel(
      id: songId,
      title: songName,
      folderPath: songDir.path,
      originalMidiPath: midiFile.path,
      durationMs: durationMs,
      noteCount: noteCount,
      bpm: bpm,
      createdAt: DateTime.now(),
      difficulty: difficulty,
      isBuiltIn: isBuiltIn,
    );

    // Save metadata.json
    final metaFile = File('${songDir.path}/metadata.json');
    await metaFile.writeAsString(jsonEncode(song.toJson()));

    return song;
  }

  /// Save an attempt as /VirtualPiano/song_name/attempts/attempt_YYYY-MM-DD_HH-mm_#N.json
  Future<AttemptRecord> saveAttempt({
    required SongModel song,
    required int attemptNumber,
    required double accuracyPercent,
    required double avgTimingDeviationMs,
    required int correctNotes,
    required int missedNotes,
    required int extraNotes,
    required int totalNotes,
    required int score,
    required String grade,
    required List<UserNotePress> playedNotes,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HH-mm').format(now);
    final fileName = 'attempt_${dateStr}_#$attemptNumber.json';
    final attemptId = '${song.id}_$attemptNumber';

    final record = AttemptRecord(
      id: attemptId,
      songId: song.id,
      songTitle: song.title,
      fileName: fileName,
      filePath: '${song.folderPath}/attempts/$fileName',
      attemptNumber: attemptNumber,
      timestamp: now,
      accuracyPercent: accuracyPercent,
      avgTimingDeviationMs: avgTimingDeviationMs,
      correctNotes: correctNotes,
      missedNotes: missedNotes,
      extraNotes: extraNotes,
      totalNotes: totalNotes,
      score: score,
      grade: grade,
      playedNotes: playedNotes,
    );

    if (kIsWeb) {
      _webAttemptsCache.putIfAbsent(song.id, () => []).add(record);
      return record;
    }

    final attemptsDir = Directory('${song.folderPath}/attempts');
    if (!await attemptsDir.exists()) {
      await attemptsDir.create(recursive: true);
    }

    final attemptFile = File('${attemptsDir.path}/$fileName');
    await attemptFile.writeAsString(jsonEncode(record.toJson()));

    return record;
  }

  /// List all songs from /VirtualPiano/
  Future<List<SongModel>> listSongs() async {
    if (kIsWeb) {
      return _webSongCache.values.toList();
    }

    final rootDir = await getRootDirectory();
    final entities = await rootDir.list().toList();
    final songs = <SongModel>[];

    for (final entity in entities) {
      if (entity is Directory) {
        final metaFile = File('${entity.path}/metadata.json');
        final midiFile = File('${entity.path}/original.mid');

        if (await metaFile.exists()) {
          try {
            final content = await metaFile.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            var song = SongModel.fromJson(json);

            // Update attempts count and best accuracy
            final attempts = await listAttempts(song.folderPath);
            double bestAcc = 0.0;
            for (final a in attempts) {
              if (a.accuracyPercent > bestAcc) bestAcc = a.accuracyPercent;
            }

            song = song.copyWith(
              attemptsCount: attempts.length,
              bestAccuracy: bestAcc,
            );
            songs.add(song);
          } catch (e) {
            debugPrint('Failed to parse metadata in ${entity.path}: $e');
          }
        } else if (await midiFile.exists()) {
          // Folder without metadata: create basic SongModel
          final dirName = entity.uri.pathSegments.reversed.skip(1).first;
          final song = SongModel(
            id: dirName,
            title: dirName.replaceAll('_', ' '),
            folderPath: entity.path,
            originalMidiPath: midiFile.path,
            createdAt: DateTime.now(),
          );
          songs.add(song);
        }
      }
    }

    // Sort by newest first
    songs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return songs;
  }

  /// List attempts inside a song's attempts folder
  Future<List<AttemptRecord>> listAttempts(String songFolderPath) async {
    if (kIsWeb) {
      return _webAttemptsCache[songFolderPath] ?? [];
    }

    final attemptsDir = Directory('$songFolderPath/attempts');
    if (!await attemptsDir.exists()) return [];

    final records = <AttemptRecord>[];
    final files = await attemptsDir.list().toList();

    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          records.add(AttemptRecord.fromJson(json));
        } catch (e) {
          debugPrint('Failed to parse attempt ${file.path}: $e');
        }
      }
    }

    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  /// Delete a song and its attempts folder
  Future<void> deleteSong(SongModel song) async {
    if (kIsWeb) {
      _webSongCache.remove(song.id);
      _webAttemptsCache.remove(song.id);
      return;
    }

    final dir = Directory(song.folderPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// Rename song
  Future<SongModel> renameSong(SongModel song, String newTitle) async {
    final sanitized = sanitizeName(newTitle);
    if (kIsWeb) {
      final updated = song.copyWith(title: newTitle);
      _webSongCache[song.id] = updated;
      return updated;
    }

    final oldDir = Directory(song.folderPath);
    final rootDir = await getRootDirectory();
    final newDir = Directory('${rootDir.path}/$sanitized');

    if (await oldDir.exists() && oldDir.path != newDir.path) {
      await oldDir.rename(newDir.path);
    }

    final updated = song.copyWith(
      title: newTitle,
      folderPath: newDir.path,
      originalMidiPath: '${newDir.path}/original.mid',
    );

    final metaFile = File('${newDir.path}/metadata.json');
    if (await metaFile.exists()) {
      await metaFile.writeAsString(jsonEncode(updated.toJson()));
    }

    return updated;
  }
}
