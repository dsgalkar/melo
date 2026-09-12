import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/file_picker_util.dart';
import '../../../core/widgets/melo_logo_widget.dart';
import '../../providers/song_providers.dart';
import '../backup/backup_restore_dialog.dart';
import 'widgets/mp3_converter_banner.dart';
import 'widgets/song_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _uploadMidiFile() async {
    try {
      final picked = await FilePickerUtil.pickFile(
        allowedExtensions: ['mid', 'midi'],
      );

      if (picked == null) return;

      final title = picked.name.replaceAll(RegExp(r'\.(mid|midi)$', caseSensitive: false), '');

      final notifier = ref.read(songListProvider.notifier);
      final song = await notifier.addMidiSong(title, picked.bytes);

      if (mounted && song != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added "${song.title}" (${song.noteCount} notes) to Song Library!',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.neonGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const MeloLogoWidget(size: 36, fontSize: 20),
        actions: [
          // Backup & Restore
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: AppColors.primaryGold),
            tooltip: 'Backup & Restore ZIP',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const BackupRestoreDialog(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.read(songListProvider.notifier).loadSongs(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MP3 to MIDI External Tool CTA Banner
              const Mp3ConverterBanner(),
              const SizedBox(height: 20),

              // Upload MIDI CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _uploadMidiFile,
                  icon: const Icon(Icons.file_upload_outlined, size: 22),
                  label: const Text(
                    '+ Upload MIDI File (.mid)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Search and Library Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SONG LIBRARY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stored in /VirtualPiano/',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search songs by title...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Song List View
              songsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primaryGold),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text('Error loading songs: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                ),
                data: (songs) {
                  final filtered = songs.where((s) {
                    if (_searchQuery.isEmpty) return true;
                    return s.title.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.piano, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          const Text(
                            'No songs found',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Upload a .mid file above or convert an MP3!',
                            style: TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => SongCard(song: filtered[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
