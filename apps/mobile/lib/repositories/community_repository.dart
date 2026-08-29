import '../services/api_service.dart';
import '../models/models_exports.dart';

class CommunityRepository {
  CommunityRepository(this._api);

  final ApiService _api;

  Future<({List<CommunityPost> posts, bool isFromMock})> getPosts({
    double? lat,
    double? lon,
    double radiusKm = 5.0,
  }) async {
    final query = lat != null
        ? {'lat': '$lat', 'lon': '$lon', 'radius_km': '$radiusKm'}
        : null;
    try {
      final data = await _api.get('/community/posts', query: query);
      final posts = (data as List<dynamic>)
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      return (posts: posts, isFromMock: false);
    } catch (_) {
      return (posts: <CommunityPost>[], isFromMock: false);
    }
  }

  Future<CommunityPost> createPost(CommunityPost post) async {
    final data = await _api.post('/community/posts', post.toJson());
    return CommunityPost.fromJson(data as Map<String, dynamic>);
  }

  Future<void> upvotePost(String id) async {
    try {
      await _api.post('/community/posts/$id/upvote', {});
    } catch (_) {}
  }
}
