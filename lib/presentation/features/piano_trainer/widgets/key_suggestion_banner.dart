import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/piano_constants.dart';
import '../../../../domain/models/learning_session_state.dart';
import '../../../../domain/models/midi_note_event.dart';

class KeySuggestionBanner extends StatelessWidget {
  final LearningSessionState state;
  final List<MidiNoteEvent> songNotes;

  const KeySuggestionBanner({
    super.key,
    required this.state,
    required this.songNotes,
  });

  @override
  Widget build(BuildContext context) {
    if (songNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentIdx = state.currentStepNoteIndex.clamp(0, songNotes.length - 1);
    final targetNote = songNotes.isNotEmpty ? songNotes[currentIdx] : null;
    final nextNote1 = (currentIdx + 1 < songNotes.length) ? songNotes[currentIdx + 1] : null;
    final nextNote2 = (currentIdx + 2 < songNotes.length) ? songNotes[currentIdx + 2] : null;

    final targetMidi = targetNote?.midiNote ?? 60;
    final targetName = PianoConstants.getNoteName(targetMidi);
    final targetSolfege = PianoConstants.getSolfege(targetMidi);
    final isBlack = PianoConstants.isBlackKey(targetMidi);
    final qwertyKey = PianoConstants.getQwertyKeyForMidi(targetMidi);

    final progress = (currentIdx + 1) / (songNotes.isNotEmpty ? songNotes.length : 1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.activeTargetNotes.isNotEmpty
              ? AppColors.primaryGold.withValues(alpha: 0.6)
              : AppColors.surfaceBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Prominent Target Key Suggestion Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGold, AppColors.primaryAmber],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      targetName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      targetSolfege,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.75),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // 2. Middle Explanation & Computer Keyboard Hint
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          isBlack ? 'BLACK KEY' : 'WHITE KEY',
                          style: TextStyle(
                            color: isBlack ? AppColors.neonPurple : AppColors.neonCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (qwertyKey != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'Key: [ $qwertyKey ]',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Live Feedback or Guidance Message
                    if (state.feedbackMessage != null && state.feedbackMessage!.isNotEmpty)
                      Text(
                        state.feedbackMessage!,
                        style: TextStyle(
                          color: state.isFeedbackPositive
                              ? AppColors.neonGreen
                              : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        state.mode == TrainerMode.stepByStep
                            ? '👉 Press the glowing green key [ $targetName ] on piano'
                            : (state.mode == TrainerMode.autoPlay
                                ? '🎵 Auto-playing notes • Observe finger positions'
                                : '⭐ Pro Mode • Play along with melody'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // 3. Upcoming Notes Preview
              if (nextNote1 != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NEXT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            PianoConstants.getNoteName(nextNote1.midiNote),
                            style: const TextStyle(
                              color: AppColors.primaryGold,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (nextNote2 != null) ...[
                            const Text(' ➔ ', style: TextStyle(color: Colors.white24, fontSize: 10)),
                            Text(
                              PianoConstants.getNoteName(nextNote2.midiNote),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // 4. Progress bar & Step counter
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Note ${currentIdx + 1} / ${songNotes.length} (${(progress * 100).toInt()}%)',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
