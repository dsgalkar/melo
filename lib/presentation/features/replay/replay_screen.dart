import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/attempt_record.dart';
import '../../providers/song_providers.dart';
import '../piano_trainer/widgets/virtual_piano_painter.dart';

class ReplayScreen extends ConsumerStatefulWidget {
  final AttemptRecord attempt;

  const ReplayScreen({super.key, required this.attempt});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  Timer? _timer;
  int _currentPosMs = 0;
  bool _isPlaying = false;
  final double _speed = 1.0;
  int _totalDurationMs = 0;
  final Set<int> _activeKeys = {};

  @override
  void initState() {
    super.initState();
    if (widget.attempt.playedNotes.isNotEmpty) {
      _totalDurationMs = widget.attempt.playedNotes.map((n) => n.timestampMs + n.durationMs).reduce((a, b) => a > b ? a : b);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _play() {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);

    const tickMs = 25;
    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      final step = (tickMs * _speed).round();
      final newPos = _currentPosMs + step;

      if (newPos >= _totalDurationMs) {
        _pause();
        setState(() {
          _currentPosMs = _totalDurationMs;
          _activeKeys.clear();
        });
        return;
      }

      // Check for note triggers in window
      final audioService = ref.read(audioSynthServiceProvider);
      final active = <int>{};

      for (final note in widget.attempt.playedNotes) {
        if (note.timestampMs >= _currentPosMs && note.timestampMs < newPos) {
          audioService.playNote(note.midiNote, velocity: note.velocity);
        }
        if (newPos >= note.timestampMs && newPos <= (note.timestampMs + note.durationMs)) {
          active.add(note.midiNote);
        }
      }

      setState(() {
        _currentPosMs = newPos;
        _activeKeys
          ..clear()
          ..addAll(active);
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isPlaying = false);
  }

  void _seek(int ms) {
    setState(() {
      _currentPosMs = ms.clamp(0, _totalDurationMs);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int ms) {
    final s = (ms / 1000).floor();
    final min = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REPLAY: ${widget.attempt.songTitle}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Attempt #${widget.attempt.attemptNumber} • ${widget.attempt.accuracyPercent}% Accuracy • Grade ${widget.attempt.grade}',
              style: const TextStyle(fontSize: 11, color: AppColors.primaryGold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Visual Replay Canvas
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF090B0E),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Text(
                        'Active Keys: ${_activeKeys.isEmpty ? "None" : _activeKeys.join(", ")}',
                        style: const TextStyle(color: AppColors.neonCyan, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Replay Piano Keyboard
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 2)),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: VirtualPianoPainter(
                  startMidiNote: 48, // C3
                  endMidiNote: 83,   // B5
                  currentlyPressedKeys: _activeKeys,
                  activeTargetNotes: {},
                  previewTargetNotes: {},
                  showNoteLabels: true,
                ),
              ),
            ),
          ),

          // Scrubber and Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(_formatTime(_currentPosMs), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _totalDurationMs > 0 ? (_currentPosMs / _totalDurationMs).clamp(0.0, 1.0) : 0.0,
                        activeColor: AppColors.primaryGold,
                        inactiveColor: AppColors.surfaceBorder,
                        onChanged: (val) {
                          _seek((val * _totalDurationMs).round());
                        },
                      ),
                    ),
                    Text(_formatTime(_totalDurationMs), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white70),
                      onPressed: () => _seek(_currentPosMs - 10000),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 42,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: AppColors.primaryGold,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white70),
                      onPressed: () => _seek(_currentPosMs + 10000),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
