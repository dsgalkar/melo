import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/piano_constants.dart';
import '../../core/utils/pcm_synth_helper.dart';

enum AudioEngineMode {
  synthesized, // Instant offline procedural PCM synth
  studioSamples, // High fidelity studio piano samples with REST/CDN caching
}

class AudioSynthService {
  static const int _maxConcurrentPlayers = 10;
  final List<AudioPlayer> _players = [];
  int _currentPlayerIndex = 0;

  AudioEngineMode _engineMode = AudioEngineMode.synthesized;
  AudioEngineMode get engineMode => _engineMode;

  final Map<int, Uint8List> _sampleCache = {};
  String? _cacheDirectoryPath;

  // Free high-quality acoustic grand piano soundfont CDN
  static const String _soundfontBaseUrl =
      'https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/acoustic_grand_piano-mp3';

  AudioSynthService() {
    _initPlayers();
  }

  void _initPlayers() {
    for (int i = 0; i < _maxConcurrentPlayers; i++) {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      _players.add(player);
    }
  }

  Future<void> initCache() async {
    try {
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${dir.path}/VirtualPiano/.audio_cache');
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }
        _cacheDirectoryPath = cacheDir.path;
      }
    } catch (e) {
      debugPrint('AudioSynthService: cache init error: $e');
    }
  }

  void setEngineMode(AudioEngineMode mode) {
    _engineMode = mode;
  }

  /// Plays a piano note (MIDI note 21-108) with zero-latency response
  Future<void> playNote(int midiNote, {int velocity = 100}) async {
    if (midiNote < PianoConstants.minMidiNote || midiNote > PianoConstants.maxMidiNote) {
      return;
    }

    try {
      final player = _players[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _maxConcurrentPlayers;

      // Calculate volume scale from MIDI velocity (0-127)
      final volume = (velocity / 127.0).clamp(0.2, 1.0);
      await player.setVolume(volume);

      if (_engineMode == AudioEngineMode.studioSamples) {
        final sampleBytes = await _getOrFetchStudioSample(midiNote);
        if (sampleBytes != null) {
          await player.stop();
          await player.play(BytesSource(sampleBytes));
          return;
        }
      }

      // Default & fast procedural acoustic PCM synthesis
      final wavBytes = PcmSynthHelper.getPianoWave(midiNote);
      await player.stop();
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('Error playing note $midiNote: $e');
    }
  }

  /// REST / CDN fetch for high-fidelity studio acoustic sample with local disk cache
  Future<Uint8List?> _getOrFetchStudioSample(int midiNote) async {
    // 1. In-memory cache
    if (_sampleCache.containsKey(midiNote)) {
      return _sampleCache[midiNote];
    }

    final noteName = PianoConstants.getNoteName(midiNote);

    // 2. Disk cache
    if (_cacheDirectoryPath != null) {
      final cachedFile = File('$_cacheDirectoryPath/$noteName.mp3');
      if (await cachedFile.exists()) {
        final bytes = await cachedFile.readAsBytes();
        _sampleCache[midiNote] = bytes;
        return bytes;
      }
    }

    // 3. REST API / CDN download
    try {
      final uri = Uri.parse('$_soundfontBaseUrl/$noteName.mp3');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _sampleCache[midiNote] = bytes;

        if (_cacheDirectoryPath != null) {
          final cachedFile = File('$_cacheDirectoryPath/$noteName.mp3');
          await cachedFile.writeAsBytes(bytes);
        }
        return bytes;
      }
    } catch (e) {
      debugPrint('Soundfont CDN fetch fallback to synth: $e');
    }

    return null;
  }

  void stopAll() {
    for (final player in _players) {
      player.stop();
    }
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _players.clear();
  }
}
