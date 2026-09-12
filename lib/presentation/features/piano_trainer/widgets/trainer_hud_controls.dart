import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/learning_session_state.dart';

class TrainerHudControls extends StatelessWidget {
  final LearningSessionState state;
  final ValueChanged<TrainerMode> onModeChanged;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onReset;
  final VoidCallback onToggleLabels;
  final VoidCallback onToggleDeskCamera;
  final VoidCallback onToggleRecording;
  final Function(int start, int end) onOctaveChanged;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;

  const TrainerHudControls({
    super.key,
    required this.state,
    required this.onModeChanged,
    required this.onSpeedChanged,
    required this.onTogglePlayPause,
    required this.onReset,
    required this.onToggleLabels,
    required this.onToggleDeskCamera,
    required this.onToggleRecording,
    required this.onOctaveChanged,
    required this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = state.status == PlaybackStatus.playing;
    final is3Octaves = (state.endMidiNote - state.startMidiNote) < 40;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 1.2),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // 1. Play / Pause / Reset
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onTogglePlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.primaryGold,
                  size: 32,
                ),
                tooltip: isPlaying ? 'Pause' : 'Play',
              ),
              IconButton(
                onPressed: onReset,
                icon: const Icon(Icons.replay, color: Colors.white70, size: 22),
                tooltip: 'Restart Song',
              ),
            ],
          ),

          // 2. Training Mode Chips
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeChip(
                  label: 'Step-by-Step',
                  mode: TrainerMode.stepByStep,
                  icon: Icons.touch_app,
                ),
                _buildModeChip(
                  label: 'Auto-Play',
                  mode: TrainerMode.autoPlay,
                  icon: Icons.music_note,
                ),
                _buildModeChip(
                  label: 'Pro',
                  mode: TrainerMode.professional,
                  icon: Icons.star_border,
                ),
              ],
            ),
          ),

          // 3. Playback Speed Selector
          PopupMenuButton<double>(
            initialValue: state.playbackSpeed,
            onSelected: onSpeedChanged,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.surfaceBorder),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x Speed', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 0.75, child: Text('0.75x Speed', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 1.0, child: Text('1.0x Normal', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 1.25, child: Text('1.25x Speed', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 1.5, child: Text('1.5x Speed', style: TextStyle(color: Colors.white))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: AppColors.neonCyan, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${state.playbackSpeed}x',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 4. Octave Range (3 vs 5 octaves)
          GestureDetector(
            onTap: () {
              if (is3Octaves) {
                // Expand to 5 octaves: C2 (36) to B6 (95)
                onOctaveChanged(36, 95);
              } else {
                // 3 octaves: C3 (48) to B5 (83)
                onOctaveChanged(48, 83);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.piano, color: Colors.white70, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    is3Octaves ? '3 Octaves' : '5 Octaves',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // 5. Desk Camera AR Mode Toggle
          GestureDetector(
            onTap: onToggleDeskCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: state.isDeskCameraMode
                    ? AppColors.primaryGold.withValues(alpha: 0.25)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.isDeskCameraMode ? AppColors.primaryGold : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isDeskCameraMode ? Icons.camera_alt : Icons.camera_alt_outlined,
                    color: state.isDeskCameraMode ? AppColors.primaryGold : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Desk AR',
                    style: TextStyle(
                      color: state.isDeskCameraMode ? AppColors.primaryGold : Colors.white,
                      fontSize: 12,
                      fontWeight: state.isDeskCameraMode ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Record Attempt Button
          GestureDetector(
            onTap: onToggleRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.isRecording
                    ? AppColors.error.withValues(alpha: 0.25)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.isRecording ? AppColors.error : AppColors.surfaceBorder,
                  width: state.isRecording ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isRecording ? AppColors.error : Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    state.isRecording ? 'REC (${state.recordedPresses.length})' : 'Record',
                    style: TextStyle(
                      color: state.isRecording ? AppColors.error : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Fullscreen Toggle Button
          IconButton(
            onPressed: onToggleFullscreen,
            icon: Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: isFullscreen ? AppColors.primaryGold : Colors.white70,
              size: 26,
            ),
            tooltip: isFullscreen ? 'Exit Full Screen' : 'Full Screen Mode (Maximize Keys)',
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required TrainerMode mode,
    required IconData icon,
  }) {
    final isSelected = state.mode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.black : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
