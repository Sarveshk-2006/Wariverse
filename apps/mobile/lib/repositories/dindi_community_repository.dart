import '../models/models_exports.dart';
import '../services/api_service.dart';

/// Repository for Dindi-scoped private community posts and leader broadcasts.
class DindiCommunityRepository {
  final ApiService _apiService;

  final Map<String, List<DindiCommunityPost>> _localPostStore = {};
  final Map<String, List<DindiBroadcast>> _localBroadcastStore = {};

  DindiCommunityRepository(this._apiService) {
    _initMockData();
  }

  void _initMockData() {
    // Alandi Dindi #1
    _localBroadcastStore['dindi-001'] = [
      DindiBroadcast(
        id: 'bc-001',
        dindiId: 'dindi-001',
        sender: 'H.B.P. Sopanrao Maharaj',
        senderRole: 'Dindi Pramukh',
        title: 'Morning Departure Rescheduled (प्रस्थान वेळ बदल)',
        message: 'Alandi Palkhi batch morning departure will begin at 05:45 AM after Haripath Aarti.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        priority: 'HIGH',
      ),
    ];
    _localPostStore['dindi-001'] = [
      DindiCommunityPost(
        id: 'post-001-1',
        dindiId: 'dindi-001',
        authorId: 'vol-10',
        authorName: 'Suresh Patil',
        authorRole: 'VOLUNTEER',
        content: 'Saswad Annachhatra Pandal #3 meal distribution is active. Water refill available.',
        postType: DindiPostType.ANNOUNCEMENT,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isVerified: true,
        isPinned: true,
      ),
      DindiCommunityPost(
        id: 'post-001-2',
        dindiId: 'dindi-001',
        authorId: 'pilgrim-22',
        authorName: 'Rameshwar Shinde',
        authorRole: 'VARKARI',
        content: 'Flag bearer team leading the procession cleanly through Saswad Ghat section.',
        postType: DindiPostType.GENERAL,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isVerified: false,
      ),
    ];

    // Dehu Dindi #5
    _localBroadcastStore['dindi-002'] = [
      DindiBroadcast(
        id: 'bc-002',
        dindiId: 'dindi-002',
        sender: 'H.B.P. Eknathrao More',
        senderRole: 'Dindi Pramukh',
        title: 'Hadapsar Phata Diversion (हडपसर मार्ग बदल)',
        message: 'Procession will halt for 30 minutes at Hadapsar Phata for tea distribution.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        priority: 'MEDIUM',
      ),
    ];
    _localPostStore['dindi-002'] = [
      DindiCommunityPost(
        id: 'post-002-1',
        dindiId: 'dindi-002',
        authorId: 'vol-30',
        authorName: 'Anil Deshmukh',
        authorRole: 'VOLUNTEER',
        content: 'Akurdi tea halt completed cleanly. Moving towards Hadapsar.',
        postType: DindiPostType.ROUTE_UPDATE,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        isVerified: true,
      ),
    ];

    // Pandharpur Dindi #12
    _localPostStore['dindi-003'] = [
      DindiCommunityPost(
        id: 'post-003-1',
        dindiId: 'dindi-003',
        authorId: 'ngo-05',
        authorName: 'Vitthal Seva Trust',
        authorRole: 'NGO',
        content: 'Evening Abhang Kirtan will begin at Phaltan Dharamshala at 06:00 PM.',
        postType: DindiPostType.ANNOUNCEMENT,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isVerified: true,
      ),
    ];

    // Sant Sopandev Dindi #8
    _localPostStore['dindi-004'] = [
      DindiCommunityPost(
        id: 'post-004-1',
        dindiId: 'dindi-004',
        authorId: 'med-08',
        authorName: 'Dr. Kulkarni',
        authorRole: 'MEDICAL_TEAM',
        content: 'Ubh Ringan event at Wakhari Ground starting at 03:15 PM. Stay hydrated.',
        postType: DindiPostType.SAFETY_ALERT,
        createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
        isVerified: true,
      ),
    ];
  }

  /// Fetches private community posts strictly isolated by Dindi ID.
  Future<List<DindiCommunityPost>> fetchPosts(String dindiId) async {
    try {
      final res = await _apiService.get('/dindis/$dindiId/community');
      if (res is List) {
        return res.map((item) => DindiCommunityPost.fromJson(item as Map<String, dynamic>)).toList();
      }
      return _localPostStore[dindiId] ?? [];
    } catch (_) {
      // Backend Dindi authorization missing -> return strictly isolated local mock posts
      return _localPostStore[dindiId] ?? [];
    }
  }

  /// Fetches authoritative leader broadcasts strictly isolated by Dindi ID.
  Future<List<DindiBroadcast>> fetchBroadcasts(String dindiId) async {
    try {
      final res = await _apiService.get('/dindis/$dindiId/broadcasts');
      if (res is List) {
        return res.map((item) => DindiBroadcast.fromJson(item as Map<String, dynamic>)).toList();
      }
      return _localBroadcastStore[dindiId] ?? [];
    } catch (_) {
      return _localBroadcastStore[dindiId] ?? [];
    }
  }

  /// Adds a new post to the specified Dindi community feed.
  Future<DindiCommunityPost> createPost(DindiCommunityPost post) async {
    final list = _localPostStore[post.dindiId] ?? [];
    _localPostStore[post.dindiId] = [post, ...list];
    return post;
  }
}
