import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/models/song_model.dart';
import '../../domain/use_cases/parse_midi_use_case.dart';
import '../services/file_storage_service.dart';

class SongRepository {
  final FileStorageService storageService;
  final ParseMidiUseCase parseMidiUseCase;

  List<SongModel> _cachedSongs = [];

  SongRepository({
    required this.storageService,
    required this.parseMidiUseCase,
  });

  Future<Uint8List> getSongMidiBytes(SongModel song) async {
    return storageService.getSongMidiBytes(song);
  }

  Future<List<SongModel>> getSongs({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSongs.isNotEmpty) {
      return _cachedSongs;
    }

    final songs = await storageService.listSongs();
    
    // If empty on first launch, load bundled verified demo songs!
    if (songs.isEmpty) {
      final builtInSongs = await _seedDemoSongs();
      _cachedSongs = builtInSongs;
      return _cachedSongs;
    }

    _cachedSongs = songs;
    return _cachedSongs;
  }

  Future<SongModel> uploadMidiSong({
    required String title,
    required Uint8List bytes,
    String? difficultyOverride,
    bool isBuiltIn = false,
    String? customMidiPath,
  }) async {
    final parsed = await parseMidiUseCase.parseAsync(bytes);

    String difficulty = difficultyOverride ?? 'Medium';
    if (difficultyOverride == null) {
      if (parsed.notes.length < 50) {
        difficulty = 'Easy';
      } else if (parsed.notes.length > 250) {
        difficulty = 'Hard';
      }
    }

    final song = await storageService.createSongFolder(
      songName: title,
      midiBytes: bytes,
      durationMs: parsed.durationMs,
      noteCount: parsed.notes.length,
      bpm: parsed.bpm,
      difficulty: difficulty,
      isBuiltIn: isBuiltIn,
      customMidiPath: customMidiPath,
    );

    _cachedSongs.insert(0, song);
    return song;
  }

  Future<void> deleteSong(SongModel song) async {
    await storageService.deleteSong(song);
    _cachedSongs.removeWhere((s) => s.id == song.id);
  }

  Future<SongModel> renameSong(SongModel song, String newTitle) async {
    final updated = await storageService.renameSong(song, newTitle);
    final idx = _cachedSongs.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      _cachedSongs[idx] = updated;
    }
    return updated;
  }

  /// Seeds classic verified demo songs into /VirtualPiano/ from assets
  Future<List<SongModel>> _seedDemoSongs() async {
    final demoSongs = <SongModel>[];

    final demoList = [
      {'title': 'Für Elise', 'file': 'assets/demo_midi/fur_elise.mid', 'diff': 'Medium'},
      {'title': 'Ode to Joy', 'file': 'assets/demo_midi/ode_to_joy.mid', 'diff': 'Easy'},
      {'title': 'Canon in D', 'file': 'assets/demo_midi/canon_in_d.mid', 'diff': 'Medium'},
      {'title': 'Rondo Alla Turca', 'file': 'assets/demo_midi/rondo_alla_turca.mid', 'diff': 'Hard'},
      {'title': 'Minuet in G Major', 'file': 'assets/demo_midi/minuet_in_g.mid', 'diff': 'Medium'},
      {'title': 'Twinkle Twinkle Little Star', 'file': 'assets/demo_midi/twinkle_star.mid', 'diff': 'Easy'},
      {'title': 'Moonlight Sonata', 'file': 'assets/demo_midi/moonlight_sonata.mid', 'diff': 'Hard'},
    ];

    for (final item in demoList) {
      try {
        final byteData = await rootBundle.load(item['file']!);
        final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        final song = await uploadMidiSong(
          title: item['title']!,
          bytes: bytes,
          difficultyOverride: item['diff'],
          isBuiltIn: true,
          customMidiPath: item['file'],
        );
        demoSongs.add(song);
      } catch (e) {
        debugPrint('Failed to seed demo song ${item['title']}: $e');
      }
    }

    return demoSongs;
  }
}
