import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/wari_theme_exports.dart';

/// Interactive Audio Player Widget for Palkhi Voice & Dindi Leader Audio Broadcasts.
class DindiAudioPlayerWidget extends StatefulWidget {
  const DindiAudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.title = 'Palkhi Voice Audio',
    this.duration = const Duration(minutes: 1, seconds: 45),
  });

  final String audioUrl;
  final String title;
  final Duration duration;

  @override
  State<DindiAudioPlayerWidget> createState() => _DindiAudioPlayerWidgetState();
}

class _DindiAudioPlayerWidgetState extends State<DindiAudioPlayerWidget> {
  bool _isPlaying = false;
  double _currentPositionSeconds = 0.0;

  @override
  void dispose() {
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _simulatePlayback();
    }
  }

  void _simulatePlayback() async {
    while (_isPlaying && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isPlaying || !mounted) break;
      setState(() {
        _currentPositionSeconds += 0.5;
        if (_currentPositionSeconds >= widget.duration.inSeconds) {
          _currentPositionSeconds = 0.0;
          _isPlaying = false;
        }
      });
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.duration.inSeconds.toDouble();
    final progress = (totalSeconds > 0) ? (_currentPositionSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: WariColors.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: WariColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: WariColors.primaryDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                        activeTrackColor: WariColors.primary,
                        inactiveTrackColor: WariColors.border,
                        thumbColor: WariColors.primaryDark,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          setState(() {
                            _currentPositionSeconds = val * totalSeconds;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDuration(_currentPositionSeconds.toInt())} / ${_formatDuration(widget.duration.inSeconds)}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: WariColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
