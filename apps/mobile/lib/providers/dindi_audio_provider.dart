import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/dindi_audio_repository.dart';
import '../services/audio_session_service.dart';

/// State provider for Palkhi Voice live audio sessions and audio schedule.
class DindiAudioProvider extends ChangeNotifier {
  final DindiAudioRepository _repository;
  final AudioSessionService _audioService;

  DindiAudioProvider({
    required DindiAudioRepository repository,
    required AudioSessionService audioService,
  })  : _repository = repository,
        _audioService = audioService {
    _statusSub = _audioService.statusStream.listen((status) {
      _audioStatus = status;
      notifyListeners();
    });
  }

  StreamSubscription<DindiAudioStatus>? _statusSub;
  DindiAudioSession? _activeSession;
  List<DindiAudioSession> _todaySchedule = [];

  DindiAudioStatus _audioStatus = DindiAudioStatus.OFFLINE;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  DindiAudioSession? get activeSession => _activeSession;
  List<DindiAudioSession> get todaySchedule => UnmodifiableListView(_todaySchedule);
  DindiAudioStatus get audioStatus => _audioStatus;
  bool get isAudioJoined => _audioStatus == DindiAudioStatus.LIVE;
  bool get isConnecting => _audioStatus == DindiAudioStatus.CONNECTING;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  /// Loads active audio session and schedule for a specific Dindi ID.
  Future<void> loadAudioSession(String dindiId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeSession = await _repository.fetchActiveSession(dindiId);
      _todaySchedule = await _repository.fetchTodaySchedule(dindiId);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Unable to load audio session: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connects to demo audio session.
  Future<void> joinLiveAudio() async {
    if (_activeSession == null) return;
    await _audioService.connect(_activeSession!.dindiId);
  }

  /// Disconnects from active audio session.
  Future<void> leaveLiveAudio() async {
    await _audioService.disconnect();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
