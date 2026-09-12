import '../../domain/models/attempt_record.dart';
import '../../domain/models/midi_note_event.dart';
import '../../domain/models/song_model.dart';
import '../services/file_storage_service.dart';

class AttemptRepository {
  final FileStorageService _storageService;

  AttemptRepository(this._storageService);

  Future<List<AttemptRecord>> getAttemptsForSong(String songFolderPath) async {
    return _storageService.listAttempts(songFolderPath);
  }

  Future<AttemptRecord> recordAttempt({
    required SongModel song,
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
    final existing = await getAttemptsForSong(song.folderPath);
    final attemptNumber = existing.length + 1;

    return _storageService.saveAttempt(
      song: song,
      attemptNumber: attemptNumber,
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
  }
}
