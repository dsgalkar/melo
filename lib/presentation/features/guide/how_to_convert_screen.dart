import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/melo_logo_widget.dart';
import '../../../data/services/external_tools_service.dart';

class HowToConvertScreen extends StatelessWidget {
  const HowToConvertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('How to Convert MP3 to MIDI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderColor: AppColors.primaryGold.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const MeloLogoWidget(size: 48, showText: false),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Convert Any Song to Piano Notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Powered by Spotify Basic Pitch neural audio-to-MIDI transcription.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              '4 Easy Steps to Learn Any Song',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildStepCard(
              stepNumber: 1,
              title: 'Prepare Your MP3 or Audio Track',
              description:
                  'Have your MP3, WAV, or audio file ready on your phone, computer, or downloads folder. Piano solo or acoustic recordings yield the highest transcription fidelity.',
              icon: Icons.audio_file,
              accentColor: AppColors.neonCyan,
            ),
            const SizedBox(height: 12),

            _buildStepCard(
              stepNumber: 2,
              title: 'Open Spotify Basic Pitch',
              description:
                  'Tap the "Convert MP3 to MIDI" button below to open the official Spotify Basic Pitch website in your web browser. It is completely free and requires no account.',
              icon: Icons.open_in_browser,
              accentColor: AppColors.primaryGold,
            ),
            const SizedBox(height: 12),

            _buildStepCard(
              stepNumber: 3,
              title: 'Drop Audio & Download MIDI',
              description:
                  'Upload your MP3 on Basic Pitch. Within a few seconds, the neural model will detect all notes, timing, and velocities. Click the "Download MIDI" button to save your .mid file.',
              icon: Icons.download_for_offline,
              accentColor: AppColors.neonGreen,
            ),
            const SizedBox(height: 12),

            _buildStepCard(
              stepNumber: 4,
              title: 'Upload to Melo & Learn',
              description:
                  'Switch back to Melo, tap "+ Upload MIDI", and select your downloaded .mid file. Melo creates a dedicated folder under /VirtualPiano/ and generates your guided practice lessons!',
              icon: Icons.piano,
              accentColor: AppColors.neonPurple,
            ),
            const SizedBox(height: 30),

            // Launch CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                ),
                onPressed: () => ExternalToolsService.showBasicPitchRedirectDialog(context),
                icon: const Icon(Icons.bolt, size: 22),
                label: const Text(
                  'Convert MP3 to MIDI (Basic Pitch)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
