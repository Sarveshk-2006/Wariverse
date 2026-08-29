import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/models_exports.dart';
import '../repositories/abhang_repository.dart';

/// State provider for offline Abhangavali hymnbook search and reading.
class AbhangProvider extends ChangeNotifier {
  final AbhangRepository _repository;

  AbhangProvider({required AbhangRepository repository}) : _repository = repository;

  List<Abhang> _allAbhangs = [];
  List<Abhang> _filteredAbhangs = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  double _fontSizeScale = 1.0;
  bool _isLoading = false;

  List<Abhang> get abhangs => UnmodifiableListView(_filteredAbhangs);
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  double get fontSizeScale => _fontSizeScale;
  bool get isLoading => _isLoading;

  /// Loads all offline Abhangs.
  Future<void> loadAbhangs() async {
    _isLoading = true;
    notifyListeners();

    _allAbhangs = await _repository.fetchAbhangs();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  /// Searches Abhangs locally.
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Filters Abhangs by author/category.
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Adjusts text size scale (A+ / A-).
  void adjustFontSize(double delta) {
    _fontSizeScale = (_fontSizeScale + delta).clamp(0.85, 1.6);
    notifyListeners();
  }

  /// Toggles favorite status locally.
  void toggleFavorite(String abhangId) {
    _allAbhangs = _allAbhangs.map((a) {
      if (a.id == abhangId) {
        return a.copyWith(isFavorite: !a.isFavorite);
      }
      return a;
    }).toList();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = _allAbhangs;

    if (_selectedCategory != 'All') {
      result = result.where((a) => a.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((a) {
        return a.titleMarathi.toLowerCase().contains(q) ||
            a.titleEnglish.toLowerCase().contains(q) ||
            a.author.toLowerCase().contains(q) ||
            a.marathiText.toLowerCase().contains(q);
      }).toList();
    }

    _filteredAbhangs = result;
  }
}
