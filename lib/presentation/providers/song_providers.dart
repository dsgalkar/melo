import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/attempt_repository.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/services/audio_synth_service.dart';
import '../../data/services/backup_restore_service.dart';
import '../../data/services/file_storage_service.dart';
import '../../domain/models/song_model.dart';
import '../../domain/use_cases/parse_midi_use_case.dart';

// Services
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final parseMidiUseCaseProvider = Provider<ParseMidiUseCase>((ref) {
  return ParseMidiUseCase();
});

final audioSynthServiceProvider = Provider<AudioSynthService>((ref) {
  final service = AudioSynthService();
  service.initCache();
  ref.onDispose(() => service.dispose());
  return service;
});

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  final storage = ref.watch(fileStorageServiceProvider);
  return BackupRestoreService(storage);
});

// Repositories
final songRepositoryProvider = Provider<SongRepository>((ref) {
  final storage = ref.watch(fileStorageServiceProvider);
  final parseUseCase = ref.watch(parseMidiUseCaseProvider);
  return SongRepository(
    storageService: storage,
    parseMidiUseCase: parseUseCase,
  );
});

final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  final storage = ref.watch(fileStorageServiceProvider);
  return AttemptRepository(storage);
});

// Song List Notifier
class SongListNotifier extends Notifier<AsyncValue<List<SongModel>>> {
  SongRepository get _repository => ref.read(songRepositoryProvider);

  @override
  AsyncValue<List<SongModel>> build() {
    Future.microtask(() => loadSongs());
    return const AsyncValue.loading();
  }

  Future<void> loadSongs({bool forceRefresh = false}) async {
    try {
      state = const AsyncValue.loading();
      final songs = await _repository.getSongs(forceRefresh: forceRefresh);
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SongModel?> addMidiSong(String title, dynamic bytes) async {
    try {
      final song = await _repository.uploadMidiSong(title: title, bytes: bytes);
      final current = state.value ?? [];
      state = AsyncValue.data([song, ...current]);
      return song;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSong(SongModel song) async {
    await _repository.deleteSong(song);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((s) => s.id != song.id).toList());
  }

  Future<void> renameSong(SongModel song, String newTitle) async {
    final updated = await _repository.renameSong(song, newTitle);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((s) => s.id == song.id ? updated : s).toList(),
    );
  }
}

final songListProvider =
    NotifierProvider<SongListNotifier, AsyncValue<List<SongModel>>>(SongListNotifier.new);
