import 'dart:async';
import '../models/models_exports.dart';

/// Abstraction boundary for Palkhi Voice live audio sessions.
abstract class AudioSessionService {
  Future<void> connect(String dindiId);
  Future<void> disconnect();
  Stream<DindiAudioStatus> get statusStream;
  DindiAudioStatus get currentStatus;
  void dispose();
}

/// Controlled demo audio session service for WariVerse AI.
class DemoAudioSessionService implements AudioSessionService {
  final StreamController<DindiAudioStatus> _statusController = StreamController<DindiAudioStatus>.broadcast();
  DindiAudioStatus _status = DindiAudioStatus.OFFLINE;

  @override
  Stream<DindiAudioStatus> get statusStream => _statusController.stream;

  @override
  DindiAudioStatus get currentStatus => _status;

  @override
  Future<void> connect(String dindiId) async {
    _status = DindiAudioStatus.CONNECTING;
    _statusController.add(_status);

    await Future.delayed(const Duration(milliseconds: 800));
    _status = DindiAudioStatus.LIVE;
    _statusController.add(_status);
  }

  @override
  Future<void> disconnect() async {
    _status = DindiAudioStatus.OFFLINE;
    _statusController.add(_status);
  }

  @override
  void dispose() {
    _statusController.close();
  }
}
