import '../models/models_exports.dart';
import '../services/api_service.dart';

/// Repository responsible for Dindi-scoped Palkhi Voice audio sessions.
class DindiAudioRepository {
  final ApiService _apiService;

  DindiAudioRepository(this._apiService);

  /// Fetches current active or scheduled audio session for a Dindi.
  Future<DindiAudioSession?> fetchActiveSession(String dindiId) async {
    try {
      final res = await _apiService.get('/dindis/$dindiId/audio-session');
      if (res is Map<String, dynamic>) {
        return DindiAudioSession.fromJson(res);
      }
      return _getMockSession(dindiId);
    } catch (_) {
      return _getMockSession(dindiId);
    }
  }

  /// Fetches today's audio broadcast schedule for a Dindi.
  Future<List<DindiAudioSession>> fetchTodaySchedule(String dindiId) async {
    return [
      DindiAudioSession(
        id: 'aud-01',
        dindiId: dindiId,
        title: 'Morning Haripath Aarti & Guidance',
        hostName: 'H.B.P. Sopanrao Maharaj',
        hostRole: 'Dindi Pramukh',
        description: 'Morning prayer and procession instructions for Ghat section.',
        status: DindiAudioStatus.ENDED,
        startedAt: DateTime.now().subtract(const Duration(hours: 4)),
        listenerCount: 145,
      ),
      DindiAudioSession(
        id: 'aud-02',
        dindiId: dindiId,
        title: 'Palkhi Live Kirtan & Abhang Chanting',
        hostName: 'H.B.P. Eknathrao More',
        hostRole: 'Kirtankar',
        description: 'Devotional kirtan during afternoon halt at Saswad Pandal.',
        status: DindiAudioStatus.LIVE,
        startedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        listenerCount: 188,
      ),
      DindiAudioSession(
        id: 'aud-03',
        dindiId: dindiId,
        title: 'Evening Route & Shelter Announcement',
        hostName: 'Suresh Patil',
        hostRole: 'Coordinator',
        description: 'Important shelter allotment and night camp announcements.',
        status: DindiAudioStatus.ENDED,
        startedAt: DateTime.now().add(const Duration(hours: 3)),
        listenerCount: 0,
      ),
    ];
  }

  DindiAudioSession _getMockSession(String dindiId) {
    return DindiAudioSession(
      id: 'active-$dindiId',
      dindiId: dindiId,
      title: 'Live Palkhi Kirtan & Route Guidance',
      hostName: 'H.B.P. Sopanrao Maharaj',
      hostRole: 'Dindi Pramukh',
      description: 'Live audio broadcast for procession batch guidance and kirtan.',
      status: DindiAudioStatus.LIVE,
      startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      listenerCount: 128,
      isDemo: true,
    );
  }
}
