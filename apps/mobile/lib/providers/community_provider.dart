import 'package:flutter/material.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';
import '../core/errors/app_exception.dart';

class CommunityProvider extends ChangeNotifier {
  CommunityProvider({required CommunityRepository repository})
      : _repository = repository;

  final CommunityRepository _repository;

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isFromMock = false;
  String? _errorMessage;

  String _activeCategory = 'ALL'; // ALL, VERIFIED, ALERTS, SERVICES, GENERAL

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isFromMock => _isFromMock;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  String get activeCategory => _activeCategory;

  List<CommunityPost> get filteredPosts {
    return _posts.where((p) {
      if (_activeCategory == 'VERIFIED' && !p.isVerified) return false;
      if (_activeCategory == 'ALERTS' &&
          p.postType != PostType.ROUTE_WARNING &&
          p.postType != PostType.WEATHER_WARNING &&
          p.postType != PostType.MEDICAL_HELP) {
        return false;
      }
      if (_activeCategory == 'SERVICES' &&
          p.postType != PostType.FOOD_AVAILABLE &&
          p.postType != PostType.WATER_AVAILABLE &&
          p.postType != PostType.SHELTER_AVAILABLE) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> loadPosts({double? lat, double? lon}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getPosts(lat: lat, lon: lon);
      _posts = res.posts;
      _isFromMock = res.isFromMock;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load community updates.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setActiveCategory(String cat) {
    _activeCategory = cat;
    notifyListeners();
  }

  Future<bool> createPost({
    required String authorId,
    required String authorName,
    required PostType postType,
    required String message,
    double latitude = 17.6741,
    double longitude = 75.3279,
    bool isVerified = false,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPost = CommunityPost(
        id: '',
        authorId: authorId,
        authorName: authorName,
        postType: postType,
        message: message,
        latitude: latitude,
        longitude: longitude,
        radiusKm: 5.0,
        isVerified: isVerified,
        upvotes: 0,
        createdAt: DateTime.now(),
      );

      final result = await _repository.createPost(newPost);
      _posts.insert(0, result);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to publish post. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> upvotePost(String id) async {
    final index = _posts.indexWhere((p) => p.id == id);
    if (index != -1) {
      final old = _posts[index];
      _posts[index] = CommunityPost(
        id: old.id,
        authorId: old.authorId,
        authorName: old.authorName,
        postType: old.postType,
        message: old.message,
        latitude: old.latitude,
        longitude: old.longitude,
        radiusKm: old.radiusKm,
        isVerified: old.isVerified,
        upvotes: old.upvotes + 1,
        createdAt: old.createdAt,
        expiresAt: old.expiresAt,
      );
      notifyListeners();
    }
    try {
      await _repository.upvotePost(id);
    } catch (_) {}
  }
}
