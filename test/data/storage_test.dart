import 'package:flutter_test/flutter_test.dart';
import 'package:melo/data/services/file_storage_service.dart';
import 'package:melo/domain/models/song_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileStorageService & BackupRestoreService Tests', () {
    test('sanitizes song folder names safely', () {
      final service = FileStorageService();
      final sanitized = service.sanitizeName('Moonlight Sonata: Op. 27 / No. 2?');
      expect(sanitized, isNot(contains(':')));
      expect(sanitized, isNot(contains('/')));
      expect(sanitized, isNot(contains('?')));
      expect(sanitized, isNot(contains(' ')));
    });

    test('saves and retrieves attempts in memory / storage', () async {
      final service = FileStorageService();
      final song = SongModel(
        id: 'test_song_1',
        title: 'Test Song',
        folderPath: '/VirtualPiano/Test_Song',
        originalMidiPath: '/VirtualPiano/Test_Song/original.mid',
        createdAt: DateTime.now(),
      );

      final attempt = await service.saveAttempt(
        song: song,
        attemptNumber: 1,
        accuracyPercent: 92.5,
        avgTimingDeviationMs: 45.0,
        correctNotes: 25,
        missedNotes: 2,
        extraNotes: 1,
        totalNotes: 27,
        score: 22000,
        grade: 'A',
        playedNotes: [],
      );

      expect(attempt.attemptNumber, 1);
      expect(attempt.accuracyPercent, 92.5);
      expect(attempt.grade, 'A');
      expect(attempt.fileName, startsWith('attempt_'));
      expect(attempt.fileName, endsWith('_#1.json'));
    });
  });
}
