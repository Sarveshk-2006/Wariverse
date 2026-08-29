import 'package:flutter/foundation.dart';
import '../models/unified_service_item.dart';
import '../models/models_exports.dart';
import '../repositories/service_repository.dart';

class ServicesProvider extends ChangeNotifier {
  ServicesProvider({required ServiceRepository serviceRepo})
      : _serviceRepo = serviceRepo;

  final ServiceRepository _serviceRepo;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isFromMock = false;
  String _activeCategory = 'all';
  String _searchQuery = '';
  bool _openOnly = false;
  String _sortBy = 'distance'; // distance, queue, rating

  UnifiedServiceItem? _selectedService;
  List<UnifiedServiceItem> _allItems = [];

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isFromMock => _isFromMock;
  String get activeCategory => _activeCategory;
  String get searchQuery => _searchQuery;
  bool get openOnly => _openOnly;
  String get sortBy => _sortBy;
  UnifiedServiceItem? get selectedService => _selectedService;

  List<UnifiedServiceItem> get filteredServices {
    var list = List<UnifiedServiceItem>.from(_allItems);

    // Category filter
    if (_activeCategory != 'all') {
      list = list.where((item) => item.categoryKey == _activeCategory).toList();
    }

    // Open only filter
    if (_openOnly) {
      list = list.where((item) => item.availableNow).toList();
    }

    // Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((item) {
        final matchesName = item.name.toLowerCase().contains(q);
        final matchesCat = item.categoryLabel.toLowerCase().contains(q);
        final matchesSub = item.subtext?.toLowerCase().contains(q) ?? false;
        final matchesTag = item.tags.any((t) => t.toLowerCase().contains(q));
        return matchesName || matchesCat || matchesSub || matchesTag;
      }).toList();
    }

    // Sorting
    if (_sortBy == 'distance') {
      list.sort((a, b) => (a.distanceM ?? 9999).compareTo(b.distanceM ?? 9999));
    } else if (_sortBy == 'queue') {
      list.sort((a, b) => (a.queueMinutes ?? 9999).compareTo(b.queueMinutes ?? 9999));
    } else if (_sortBy == 'rating') {
      list.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
    }

    return list;
  }

  void setActiveCategory(String categoryKey) {
    if (_activeCategory != categoryKey) {
      _activeCategory = categoryKey;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOpenOnly(bool value) {
    _openOnly = value;
    notifyListeners();
  }

  void setSortBy(String option) {
    _sortBy = option;
    notifyListeners();
  }

  void selectService(UnifiedServiceItem? item) {
    _selectedService = item;
    notifyListeners();
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final results = await Future.wait([
        _serviceRepo.getFoodCentres(lat: 17.6741, lon: 75.3279),
        _serviceRepo.getWaterPoints(lat: 17.6741, lon: 75.3279),
        _serviceRepo.getMedicalLocations(),
        _serviceRepo.getToilets(),
        _serviceRepo.getShelters(),
        _serviceRepo.getWellnessCentres(),
      ]);

      final foodRes = results[0] as ({List<FoodCentre> items, bool isFromMock});
      final waterRes = results[1] as ({List<WaterPoint> items, bool isFromMock});
      final medRes = results[2] as ({List<MedicalLocation> items, bool isFromMock});
      final toiletRes = results[3] as ({List<ToiletPoint> items, bool isFromMock});
      final shelterRes = results[4] as ({List<Shelter> items, bool isFromMock});
      final wellnessRes = results[5] as ({List<WellnessCentre> items, bool isFromMock});

      _isFromMock = foodRes.isFromMock || waterRes.isFromMock;

      final items = <UnifiedServiceItem>[];
      for (final f in foodRes.items) {
        items.add(UnifiedServiceItem.fromFood(f));
      }
      for (final w in waterRes.items) {
        items.add(UnifiedServiceItem.fromWater(w));
      }
      for (final m in medRes.items) {
        items.add(UnifiedServiceItem.fromMedical(m));
      }
      for (final t in toiletRes.items) {
        items.add(UnifiedServiceItem.fromToilet(t));
      }
      for (final s in shelterRes.items) {
        items.add(UnifiedServiceItem.fromShelter(s));
      }
      for (final wc in wellnessRes.items) {
        items.add(UnifiedServiceItem.fromWellness(wc));
      }

      _allItems = items;
    } catch (_) {
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadServices();
}
