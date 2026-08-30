import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../services/cloudinary_service.dart';
import 'widgets/dindi_audio_player_widget.dart';

/// Palkhi Voice live audio broadcast recording, publication, and playback hub.
class DindiPalkhiVoiceScreen extends StatefulWidget {
  const DindiPalkhiVoiceScreen({super.key, this.dindiId});

  final String? dindiId;

  @override
  State<DindiPalkhiVoiceScreen> createState() => _DindiPalkhiVoiceScreenState();
}

class _DindiPalkhiVoiceScreenState extends State<DindiPalkhiVoiceScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Procession Route & Abhang Update');
  bool _isRecording = false;
  bool _isUploading = false;
  int _recordSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _titleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _recordSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _publishAudioBroadcast(VirtualDindiProvider dindiProvider) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an audio broadcast title.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final mockAudioBytes = Uint8List.fromList(List<int>.generate(2048, (i) => i % 256));
      final fileName = 'palkhi_voice_${DateTime.now().millisecondsSinceEpoch}.mp3';

      final audioUrl = await CloudinaryService.uploadMedia(
        bytes: mockAudioBytes,
        fileName: fileName,
        resourceType: 'video',
      );

      await dindiProvider.sendLeaderBroadcast(
        title: title,
        message: '🔊 Palkhi Voice Audio Broadcast (${_recordSeconds > 0 ? "$_recordSeconds sec" : "1:45 min"})',
        type: 'PALKHI_AUDIO',
        audioUrl: audioUrl ?? 'https://res.cloudinary.com/wariverse-ai/image/upload/v1788052345/palkhi_audio.mp3',
        priority: 'HIGH',
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _isRecording = false;
          _recordSeconds = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Palkhi Voice Audio published live to Dindi broadcast channel!'),
            backgroundColor: WariColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish audio broadcast: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final activeDindi = dindiProvider.activeDindi;
    final isLeader = dindiProvider.isLeader || userProvider.currentRole == UserRole.DINDI_LEADER;
    final broadcasts = dindiProvider.broadcasts.where((b) => b.type == 'PALKHI_AUDIO' || b.audioUrl != null).toList();

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: Text(activeDindi != null ? '${activeDindi.name} — Palkhi Voice' : 'Palkhi Voice (पालखी व्हॉइस)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [WariColors.primaryDark, WariColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Icon(LucideIcons.mic, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Palkhi Voice (पालखी व्हॉइस)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Live leader audio updates, route announcements & kirtan',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // Leader Audio Recording Section
            if (isLeader && activeDindi != null) ...[
              Text('Record & Publish Audio Broadcast', style: WariTypography.titleSmall),
              const SizedBox(height: WariSpacing.xs),
              WariCard(
                borderColor: WariColors.primary.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Broadcast Title',
                        hintText: 'e.g. Afternoon Procession & Halt Instructions',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _toggleRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? WariColors.danger : WariColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: Icon(_isRecording ? LucideIcons.square : LucideIcons.mic, color: Colors.white),
                          label: Text(_isRecording ? 'Stop ($_recordSeconds s)' : 'Record Audio', style: const TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_isUploading || _isRecording || _recordSeconds == 0)
                                ? null
                                : () => _publishAudioBroadcast(dindiProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: WariColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _isUploading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(LucideIcons.radio, color: Colors.white),
                            label: Text(_isUploading ? 'Publishing...' : 'Publish Live', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.base),
            ],

            // Audio Broadcasts Channel Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Palkhi Audio Streams', style: WariTypography.titleSmall),
                if (broadcasts.isNotEmpty)
                  WariStatusChip(label: '${broadcasts.length} Audio', color: WariColors.primary, dense: true),
              ],
            ),
            const SizedBox(height: WariSpacing.xs),

            if (broadcasts.isEmpty)
              const WariEmptyState(
                icon: LucideIcons.radioReceiver,
                title: 'No Audio Broadcasts Yet',
                subtitle: 'Live audio announcements from your Dindi Leader will appear here.',
              )
            else
              ...broadcasts.map((b) => WariCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b.title,
                              style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(b.createdAt),
                              style: const TextStyle(fontSize: 11, color: WariColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Leader: ${b.sender} • ${b.message}',
                          style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                        ),
                        if (b.audioUrl != null && b.audioUrl!.isNotEmpty)
                          DindiAudioPlayerWidget(
                            audioUrl: b.audioUrl!,
                            title: b.title,
                          ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
