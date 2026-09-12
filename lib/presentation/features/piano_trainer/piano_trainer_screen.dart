import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/audio_synth_service.dart';
import '../../../domain/models/learning_session_state.dart';
import '../../../domain/models/song_model.dart';
import '../../providers/piano_trainer_provider.dart';
import '../../providers/song_providers.dart';
import '../analysis/performance_analysis_dialog.dart';
import 'widgets/desk_camera_overlay.dart';
import 'widgets/falling_notes_waterfall.dart';
import 'widgets/key_suggestion_banner.dart';
import 'widgets/screen_recorder_panel.dart';
import 'widgets/trainer_hud_controls.dart';
import 'widgets/virtual_piano_widget.dart';

class PianoTrainerScreen extends ConsumerStatefulWidget {
  final SongModel song;

  const PianoTrainerScreen({super.key, required this.song});

  @override
  ConsumerState<PianoTrainerScreen> createState() => _PianoTrainerScreenState();
}

class _PianoTrainerScreenState extends ConsumerState<PianoTrainerScreen> {
  double _deskTiltAngle = 0.28;
  double _deskOpacity = 0.92;
  bool _showDeskGuide = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pianoTrainerProvider.notifier).loadSong(widget.song);
    });
  }

  void _handleToggleRecording() async {
    final notifier = ref.read(pianoTrainerProvider.notifier);
    final state = ref.read(pianoTrainerProvider);

    if (state.isRecording) {
      final attempt = await notifier.stopRecording();
      if (attempt != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PerformanceAnalysisDialog(
            attempt: attempt,
            onTryAgain: () {
              notifier.reset();
              notifier.startRecording();
            },
          ),
        );
      }
    } else {
      notifier.startRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Performance recording started! Play along with the song.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pianoTrainerProvider);
    final notifier = ref.read(pianoTrainerProvider.notifier);
    final songNotes = notifier.songNotes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${songNotes.length} notes • ${widget.song.difficulty} • ${(widget.song.durationMs / 1000).toStringAsFixed(0)}s',
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryGold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Audio Engine Switch (Synthesized vs Studio Samples)
          Consumer(
            builder: (context, ref, _) {
              final audioService = ref.watch(audioSynthServiceProvider);
              final isStudio = audioService.engineMode == AudioEngineMode.studioSamples;
              return Tooltip(
                message: isStudio ? 'Audio: Studio Samples (REST CDN)' : 'Audio: Offline Fast Synth',
                child: IconButton(
                  icon: Icon(
                    isStudio ? Icons.album : Icons.graphic_eq,
                    color: isStudio ? AppColors.neonCyan : Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      audioService.setEngineMode(
                        isStudio ? AudioEngineMode.synthesized : AudioEngineMode.studioSamples,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isStudio ? 'Switched to Offline Procedural Synth' : 'Switched to Studio Samples (REST Cache)',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Desk Camera Settings Sheet
          if (state.isDeskCameraMode)
            IconButton(
              icon: const Icon(Icons.tune, color: AppColors.primaryGold),
              tooltip: 'Desk Perspective & Opacity',
              onPressed: () => _showDeskSettingsSheet(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Controls
            TrainerHudControls(
              state: state,
              onModeChanged: notifier.setMode,
              onSpeedChanged: notifier.setPlaybackSpeed,
              onTogglePlayPause: () {
                if (state.status == PlaybackStatus.playing) {
                  notifier.pause();
                } else {
                  notifier.play();
                }
              },
              onReset: notifier.reset,
              onToggleLabels: notifier.toggleNoteLabels,
              onToggleDeskCamera: notifier.toggleDeskCameraMode,
              onToggleRecording: _handleToggleRecording,
              onOctaveChanged: notifier.setOctaveRange,
            ),

            // Target Key Suggestion & Guidance Banner
            KeySuggestionBanner(
              state: state,
              songNotes: songNotes,
            ),

            // Main Interactive Stage
            Expanded(
              child: Stack(
                children: [
                  DeskCameraOverlay(
                    isCameraActive: state.isDeskCameraMode,
                    tiltAngle: _deskTiltAngle,
                    opacity: _deskOpacity,
                    showDeskGuide: _showDeskGuide,
                    child: Column(
                      children: [
                        // 1. Falling Notes Waterfall
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF090B0E),
                            ),
                            child: FallingNotesWaterfall(
                              notes: songNotes,
                              currentPositionMs: state.currentPositionMs,
                              startMidiNote: state.startMidiNote,
                              endMidiNote: state.endMidiNote,
                            ),
                          ),
                        ),

                        // 2. CustomPainter Virtual Piano
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, -4),
                                ),
                              ],
                            ),
                            child: VirtualPianoWidget(
                              startMidiNote: state.startMidiNote,
                              endMidiNote: state.endMidiNote,
                              currentlyPressedKeys: state.currentlyPressedKeys,
                              activeTargetNotes: state.activeTargetNotes,
                              previewTargetNotes: state.previewTargetNotes,
                              showNoteLabels: state.showNoteLabels,
                              onNotePressed: (note) => notifier.onUserKeyPress(note),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Screen / Session Recording Active HUD
                  ScreenRecorderPanel(
                    isRecording: state.isRecording,
                    notesCount: state.recordedPresses.length,
                    elapsedMs: state.currentPositionMs,
                    onStopRecording: _handleToggleRecording,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeskSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desk AR & Perspective Settings',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Desk 3D Tilt Angle', style: TextStyle(color: Colors.white70)),
                  Text('${(_deskTiltAngle * 180 / 3.1415).toStringAsFixed(0)}°', style: const TextStyle(color: AppColors.primaryGold)),
                ],
              ),
              Slider(
                value: _deskTiltAngle,
                min: 0.0,
                max: 0.6,
                activeColor: AppColors.primaryGold,
                onChanged: (v) {
                  setSheetState(() => _deskTiltAngle = v);
                  setState(() => _deskTiltAngle = v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Piano Opacity', style: TextStyle(color: Colors.white70)),
                  Text('${(_deskOpacity * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.neonCyan)),
                ],
              ),
              Slider(
                value: _deskOpacity,
                min: 0.4,
                max: 1.0,
                activeColor: AppColors.neonCyan,
                onChanged: (v) {
                  setSheetState(() => _deskOpacity = v);
                  setState(() => _deskOpacity = v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Desk Placement Reticle', style: TextStyle(color: Colors.white70)),
                value: _showDeskGuide,
                activeTrackColor: AppColors.primaryGold,
                onChanged: (v) {
                  setSheetState(() => _showDeskGuide = v);
                  setState(() => _showDeskGuide = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
