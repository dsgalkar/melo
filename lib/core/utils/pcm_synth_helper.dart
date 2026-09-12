import 'dart:math';
import 'dart:typed_data';

class PcmSynthHelper {
  static const int sampleRate = 22050; // 22.05 kHz for fast generation and crisp clarity
  static final Map<int, Uint8List> _wavCache = {};

  /// Generate or retrieve cached WAV bytes for a given MIDI note (21 to 108)
  static Uint8List getPianoWave(int midiNote, {double durationSeconds = 1.0}) {
    if (_wavCache.containsKey(midiNote)) {
      return _wavCache[midiNote]!;
    }

    final wavBytes = _generatePianoWav(midiNote, durationSeconds);
    _wavCache[midiNote] = wavBytes;
    return wavBytes;
  }

  /// Synthesize acoustic piano timbre with hammer transient and harmonic overtones
  static Uint8List _generatePianoWav(int midiNote, double durationSeconds) {
    final numSamples = (sampleRate * durationSeconds).toInt();
    final frequency = 440.0 * pow(2.0, (midiNote - 69) / 12.0);

    // 16-bit PCM = 2 bytes per sample
    final pcmData = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Exponential decay envelope (faster decay for higher notes)
      final decayRate = 3.0 + (midiNote / 30.0);
      final envelope = exp(-decayRate * t);

      // Attack ramp (5ms to prevent audio clicks)
      final attack = min(1.0, t / 0.005);

      // Acoustic piano harmonic series
      double sample = 0.0;
      // Fundamental
      sample += 0.50 * sin(2 * pi * frequency * t);
      // 2nd harmonic (octave)
      sample += 0.25 * sin(2 * pi * frequency * 2 * t) * exp(-1.5 * t);
      // 3rd harmonic
      sample += 0.15 * sin(2 * pi * frequency * 3 * t) * exp(-2.5 * t);
      // 4th harmonic
      sample += 0.08 * sin(2 * pi * frequency * 4 * t) * exp(-3.5 * t);
      // 5th harmonic
      sample += 0.04 * sin(2 * pi * frequency * 5 * t) * exp(-4.5 * t);

      // Subtle hammer strike transient in first 10ms
      if (t < 0.01) {
        final hammerNoise = (Random(i).nextDouble() * 2 - 1) * (1.0 - t / 0.01) * 0.15;
        sample += hammerNoise;
      }

      final amplitude = (sample * attack * envelope).clamp(-1.0, 1.0);
      pcmData[i] = (amplitude * 32767).toInt();
    }

    // Build standard 44-byte RIFF WAV file
    return _buildWavHeader(pcmData.buffer.asUint8List(), sampleRate, 1, 16);
  }

  static Uint8List _buildWavHeader(
    Uint8List pcmBytes,
    int sampleRate,
    int numChannels,
    int bitsPerSample,
  ) {
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final subChunk2Size = pcmBytes.length;
    final chunkSize = 36 + subChunk2Size;

    final header = ByteData(44);

    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, chunkSize, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // "data" sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, subChunk2Size, Endian.little);

    final wav = Uint8List(44 + pcmBytes.length);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, wav.length, pcmBytes);
    return wav;
  }
}
