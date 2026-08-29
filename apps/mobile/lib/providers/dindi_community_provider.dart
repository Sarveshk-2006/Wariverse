import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/dindi_community_repository.dart';

/// State provider for private Dindi community feeds and leader broadcasts.
class DindiCommunityProvider extends ChangeNotifier {
  final DindiCommunityRepository _repository;

  DindiCommunityProvider({required DindiCommunityRepository repository})
      : _repository = repository;

  List<DindiCommunityPost> _posts = [];
  List<DindiBroadcast> _broadcasts = [];

  DindiPostType? _selectedFilter;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  List<DindiCommunityPost> get posts {
    if (_selectedFilter == null) return UnmodifiableListView(_posts);
    return UnmodifiableListView(_posts.where((p) => p.postType == _selectedFilter));
  }

  List<DindiBroadcast> get broadcasts => UnmodifiableListView(_broadcasts);
  DindiPostType? get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  /// Loads private community feed and broadcasts strictly for the given Dindi ID.
  Future<void> loadCommunity(String dindiId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _repository.fetchPosts(dindiId);
      _broadcasts = await _repository.fetchBroadcasts(dindiId);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load Dindi community feed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets feed category filter.
  void filterByCategory(DindiPostType? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// Creates a new community post inside the active Dindi feed.
  Future<bool> createPost({
    required String dindiId,
    required String content,
    required DindiPostType type,
    required AppUser author,
  }) async {
    if (content.trim().isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final newPost = DindiCommunityPost(
        id: 'post-${DateTime.now().millisecondsSinceEpoch}',
        dindiId: dindiId,
        authorId: author.userId,
        authorName: author.displayName,
        authorRole: author.role,
        content: content.trim(),
        postType: type,
        createdAt: DateTime.now(),
        isVerified: author.userRole != UserRole.VARKARI,
        isPinned: type == DindiPostType.ANNOUNCEMENT,
      );

      final created = await _repository.createPost(newPost);
      _posts = [created, ..._posts];
      notifyListeners();
      return true;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not create post: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Centralized permission helpers.
  static bool canCreateAnnouncement(UserRole role) {
    return role == UserRole.VOLUNTEER ||
        role == UserRole.NGO ||
        role == UserRole.ADMIN ||
        role == UserRole.POLICE;
  }

  static bool canCreateSafetyAlert(UserRole role) {
    return role == UserRole.MEDICAL_TEAM ||
        role == UserRole.POLICE ||
        role == UserRole.VOLUNTEER ||
        role == UserRole.ADMIN;
  }
}
