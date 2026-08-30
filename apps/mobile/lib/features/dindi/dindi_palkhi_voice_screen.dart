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

enum AudioRecordingState {
  idle,
  recording,
  recorded,
  uploading,
  sent,
  failed,
}

/// Senior-friendly Palkhi Voice live audio broadcast recording, preview, publication, and feed hub.
class DindiPalkhiVoiceScreen extends StatefulWidget {
  const DindiPalkhiVoiceScreen({super.key, this.dindiId});

  final String? dindiId;

  @override
  State<DindiPalkhiVoiceScreen> createState() => _DindiPalkhiVoiceScreenState();
}

class _DindiPalkhiVoiceScreenState extends State<DindiPalkhiVoiceScreen> {
  final TextEditingController _titleController =
      TextEditingController(text: 'पालखी मार्ग व कीर्तन अपडेट (Palkhi Route & Abhang Update)');
  AudioRecordingState _recordingState = AudioRecordingState.idle;
  int _recordSeconds = 0;
  Timer? _timer;
  String? _previewAudioUrl;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recordingState = AudioRecordingState.recording;
      _recordSeconds = 0;
      _errorMessage = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordSeconds++;
        });
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    final mockTimestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _recordingState = AudioRecordingState.recorded;
      _previewAudioUrl =
          'https://res.cloudinary.com/wariverse-ai/image/upload/v1788052345/palkhi_audio_$mockTimestamp.mp3';
    });
  }

  void _resetRecording() {
    _timer?.cancel();
    setState(() {
      _recordingState = AudioRecordingState.idle;
      _recordSeconds = 0;
      _previewAudioUrl = null;
      _errorMessage = null;
    });
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
      _recordingState = AudioRecordingState.uploading;
      _errorMessage = null;
    });

    try {
      final mockAudioBytes = Uint8List.fromList(List<int>.generate(4096, (i) => i % 256));
      final fileName = 'palkhi_voice_${DateTime.now().millisecondsSinceEpoch}.mp3';

      final uploadedUrl = await CloudinaryService.uploadMedia(
            bytes: mockAudioBytes,
            fileName: fileName,
            resourceType: 'video',
          ) ??
          _previewAudioUrl ??
          'https://res.cloudinary.com/wariverse-ai/image/upload/v1788052345/palkhi_audio.mp3';

      final mins = _recordSeconds ~/ 60;
      final secs = _recordSeconds % 60;
      final durationStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

      await dindiProvider.sendLeaderBroadcast(
        title: title,
        message: '🔊 Palkhi Voice Audio Broadcast ($durationStr)',
        type: 'PALKHI_AUDIO',
        audioUrl: uploadedUrl,
        priority: 'HIGH',
      );

      if (mounted) {
        setState(() {
          _recordingState = AudioRecordingState.sent;
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
          _recordingState = AudioRecordingState.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<VirtualDindiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final activeDindi = dindiProvider.activeDindi;
    final isLeader = dindiProvider.isLeader || userProvider.currentRole == UserRole.DINDI_LEADER;
    final broadcasts = dindiProvider.broadcasts
        .where((b) => b.type == 'PALKHI_AUDIO' || (b.audioUrl != null && b.audioUrl!.isNotEmpty))
        .toList();

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
                borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: WariColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(LucideIcons.mic, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Palkhi Voice (पालखी व्हॉइस)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Live Dindi Leader audio updates, abhang & route announcements',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            // Senior-Friendly Leader Audio Recorder Section
            if (isLeader && activeDindi != null) ...[
              Text('Audio Broadcast Studio (ध्वनी संदेश पाठवा)', style: WariTypography.titleMedium),
              const SizedBox(height: WariSpacing.xs),
              _buildStudioCard(dindiProvider),
              const SizedBox(height: WariSpacing.base),
            ],

            // Audio Broadcasts Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Audio Stream Feed', style: WariTypography.titleSmall),
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
                            Expanded(
                              child: Text(
                                b.title,
                                style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                            duration: Duration(seconds: _recordSeconds > 0 ? _recordSeconds : 65),
                          ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildStudioCard(VirtualDindiProvider dindiProvider) {
    return Container(
      padding: const EdgeInsets.all(WariSpacing.md),
      decoration: BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
        border: Border.all(color: WariColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Broadcast Title (शीर्षक)',
              hintText: 'e.g. Route update, Lunch halt & Abhang',
              prefixIcon: Icon(LucideIcons.subtitles, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: WariSpacing.base),

          // State-based Studio Controls
          if (_recordingState == AudioRecordingState.idle) ...[
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _startRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: WariColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: WariColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.mic, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Tap to Record (रेकॉर्ड करण्यासाठी टॅप करा)', style: WariTypography.titleSmall),
                  const Text('Hold phone near mouth & speak clearly', style: TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                ],
              ),
            ),
          ] else if (_recordingState == AudioRecordingState.recording) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: WariColors.dangerLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: WariColors.danger),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: WariColors.danger, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RECORDING: ${_formatDuration(_recordSeconds)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.dangerDark, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simulated Waveform Visualization
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      14,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 16.0 + ((index * 7 + _recordSeconds * 5) % 36),
                        decoration: BoxDecoration(
                          color: WariColors.danger.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.danger,
                      minimumSize: const Size(200, 48),
                    ),
                    icon: const Icon(LucideIcons.square, color: Colors.white),
                    label: const Text('Stop Recording (रेकॉर्डिंग थांबवा)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else if (_recordingState == AudioRecordingState.recorded || _recordingState == AudioRecordingState.sent) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WariColors.successLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WariColors.success),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: WariColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _recordingState == AudioRecordingState.sent ? 'Sent to Dindi! (पालखीला पाठवले)' : 'Audio Ready for Preview',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.successDark),
                      ),
                      const Spacer(),
                      Text(_formatDuration(_recordSeconds), style: WariTypography.caption),
                    ],
                  ),
                  if (_previewAudioUrl != null)
                    DindiAudioPlayerWidget(
                      audioUrl: _previewAudioUrl!,
                      title: _titleController.text,
                      duration: Duration(seconds: _recordSeconds > 0 ? _recordSeconds : 30),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _resetRecording,
                  icon: const Icon(LucideIcons.rotateCcw, size: 18),
                  label: const Text('Re-record (पुन्हा करा)'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _recordingState == AudioRecordingState.uploading
                        ? null
                        : () => _publishAudioBroadcast(dindiProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WariColors.success,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                    label: const Text(
                      'Send Announcement (पाठवा)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_recordingState == AudioRecordingState.uploading) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: const [
                    CircularProgressIndicator(color: WariColors.primary),
                    SizedBox(height: 12),
                    Text('Publishing live to Dindi broadcast channel...', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: WariColors.danger, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
