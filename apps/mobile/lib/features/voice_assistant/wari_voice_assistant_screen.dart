import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../providers/user_provider.dart';
import '../../providers/virtual_dindi_provider.dart';
import '../../navigation/app_routes.dart';

enum VoiceState {
  ready,
  listening,
  processing,
  speaking,
  error,
  permissionDenied,
}

/// Senior-Citizen Friendly WariVerse Voice-to-Voice AI Assistant Screen.
class WariVoiceAssistantScreen extends StatefulWidget {
  const WariVoiceAssistantScreen({super.key});

  @override
  State<WariVoiceAssistantScreen> createState() => _WariVoiceAssistantScreenState();
}

class _WariVoiceAssistantScreenState extends State<WariVoiceAssistantScreen> with TickerProviderStateMixin {
  VoiceState _state = VoiceState.ready;
  String _userSpokenText = '';
  String _aiResponseText = '';
  String _selectedLanguage = 'mr'; // 'mr' (Marathi) or 'en' (English)

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() async {
    setState(() {
      _state = VoiceState.listening;
      _userSpokenText = _selectedLanguage == 'mr' ? 'ऐकत आहे... बोला...' : 'Listening... Speak now...';
      _aiResponseText = '';
    });

    // Simulate voice audio capture for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    setState(() {
      _state = VoiceState.processing;
      _userSpokenText = _selectedLanguage == 'mr'
          ? '"माझी दिंडी आणि जवळचे पाणी केंद्र कुठे आहे?"'
          : '"Where is my Dindi and the nearest water point?"';
    });

    // Context-aware AI processing simulation
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final dindiProvider = Provider.of<VirtualDindiProvider>(context, listen: false);
    final activeDindi = dindiProvider.activeDindi;
    final dindiName = activeDindi?.name ?? 'Pandharpur Express Dindi (VDND-4107)';

    final response = _selectedLanguage == 'mr'
        ? 'माऊली, तुमची दिंडी "$dindiName" सुरक्षित अंतरावर आगेकूच करत आहे. ३०० मीटर अंतरावर पिण्याचे पाणी केंद्र उपलब्ध आहे. जय जय राम कृष्ण हरी!'
        : 'Mauli, your Dindi "$dindiName" is active and safe. The nearest drinking water kiosk is 300 meters ahead. Jai Jai Ram Krishna Hari!';

    setState(() {
      _state = VoiceState.speaking;
      _aiResponseText = response;
    });

    // Simulate audio playback for 4 seconds
    await Future.delayed(const Duration(milliseconds: 4000));
    if (!mounted) return;

    setState(() {
      _state = VoiceState.ready;
    });
  }

  void _stopInteraction() {
    setState(() {
      _state = VoiceState.ready;
      _userSpokenText = '';
      _aiResponseText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Voice Assistant (आवाज सहाय्यक)'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.languages),
            onSelected: (lang) => setState(() => _selectedLanguage = lang),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
              const PopupMenuItem(value: 'en', child: Text('English')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WariSpacing.base),
          child: Column(
            children: [
              // Greeting Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WariColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: WariColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: WariColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.bot, color: WariColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedLanguage == 'mr' ? 'राम कृष्ण हरी, ${user?.displayName ?? "वारकरी"}!' : 'Ram Krishna Hari, ${user?.displayName ?? "Pilgrim"}!',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedLanguage == 'mr' ? 'माईक दाबून बोला, मी उत्तरे देईन.' : 'Tap mic and ask any question naturally.',
                            style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Animated Voice Mic Button & Pulse Ring
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_state == VoiceState.listening || _state == VoiceState.speaking)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (ctx, child) => Container(
                              width: 150 * _pulseAnimation.value,
                              height: 150 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_state == VoiceState.listening ? WariColors.primary : WariColors.success).withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _state == VoiceState.ready ? _startListening : _stopInteraction,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _state == VoiceState.listening
                                    ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
                                    : _state == VoiceState.speaking
                                        ? [WariColors.success, WariColors.successDark]
                                        : [WariColors.primary, WariColors.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_state == VoiceState.listening ? WariColors.danger : WariColors.primary).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              _state == VoiceState.listening
                                  ? LucideIcons.mic
                                  : _state == VoiceState.speaking
                                      ? LucideIcons.volume2
                                      : _state == VoiceState.processing
                                          ? LucideIcons.loader2
                                          : LucideIcons.mic,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status Indicator
                    Text(
                      _state == VoiceState.listening
                          ? (_selectedLanguage == 'mr' ? '🎙️ ऐकत आहे...' : '🎙️ Listening...')
                          : _state == VoiceState.processing
                              ? (_selectedLanguage == 'mr' ? '⏳ विचार करत आहे...' : '⏳ Processing...')
                              : _state == VoiceState.speaking
                                  ? (_selectedLanguage == 'mr' ? '🔊 उत्तर देत आहे...' : '🔊 Speaking response...')
                                  : (_selectedLanguage == 'mr' ? '👉 बोलण्यासाठी मायक्रोफोन दाबा' : '👉 Tap mic to ask a question'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _state == VoiceState.listening
                            ? WariColors.danger
                            : _state == VoiceState.speaking
                                ? WariColors.success
                                : WariColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // User Spoken Prompt & AI Response Cards
              if (_userSpokenText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: WariColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WariColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.user, color: WariColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _userSpokenText,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WariColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (_aiResponseText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WariColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WariColors.success, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: WariColors.success.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(LucideIcons.sparkles, color: WariColors.success, size: 20),
                          SizedBox(width: 8),
                          Text('WariVerse AI Response', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.successDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiResponseText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Suggested Quick Voice Prompts
              if (_state == VoiceState.ready) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quick Prompts (सुचवलेले प्रश्न):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: WariColors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(LucideIcons.users, size: 14),
                      label: Text(_selectedLanguage == 'mr' ? 'माझी दिंडी कुठे आहे?' : 'Where is my Dindi?'),
                      onPressed: _startListening,
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.droplet, size: 14),
                      label: Text(_selectedLanguage == 'mr' ? 'जवळचे पाणी कुठे आहे?' : 'Where is water point?'),
                      onPressed: _startListening,
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.utensils, size: 14),
                      label: Text(_selectedLanguage == 'mr' ? 'अन्नछत्र कुठे आहे?' : 'Where is food centre?'),
                      onPressed: _startListening,
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.siren, size: 14),
                      label: Text(_selectedLanguage == 'mr' ? 'आपत्कालीन मदत ११२' : 'Emergency Help 112'),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.alerts),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
