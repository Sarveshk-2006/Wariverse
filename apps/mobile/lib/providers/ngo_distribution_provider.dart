import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/models_exports.dart';
import '../repositories/ngo_distribution_repository.dart';
import '../services/onesignal_service.dart';

enum DistributionSortOption { distance, availability, endingSoon }

/// Provider for Real-Time NGO Resource Distributions & Aid Coordination.
class NgoDistributionProvider extends ChangeNotifier {
  final NgoDistributionRepository _repository;
  StreamSubscription<List<ResourceDistribution>>? _activeSub;
  StreamSubscription<List<ResourceDistribution>>? _ngoSub;

  List<ResourceDistribution> _allActiveDistributions = [];
  List<ResourceDistribution> _myNgoDistributions = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String _statusFilter = 'ALL'; // ALL, AVAILABLE_NOW, STARTING_SOON, NEARBY
  DistributionSortOption _sortOption = DistributionSortOption.availability;

  NgoDistributionProvider({NgoDistributionRepository? repository})
      : _repository = repository ?? NgoDistributionRepository() {
    _initSampleData();
    _startRealtimeListeners();
  }

  List<ResourceDistribution> get activeDistributions => _allActiveDistributions;
  List<ResourceDistribution> get myNgoDistributions => _myNgoDistributions;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String get statusFilter => _statusFilter;
  DistributionSortOption get sortOption => _sortOption;

  /// Filtered active distributions for Varkari pilgrims.
  List<ResourceDistribution> get filteredDistributions {
    var list = _allActiveDistributions.where((d) => d.isActive).toList();

    if (_selectedCategory != null && _selectedCategory != 'ALL') {
      list = list.where((d) => d.category.name.toUpperCase() == _selectedCategory!.toUpperCase()).toList();
    }

    if (_statusFilter == 'AVAILABLE_NOW') {
      list = list.where((d) => d.remainingQuantity > 0 && d.computedDistributionStatus == 'ACTIVE').toList();
    } else if (_statusFilter == 'STARTING_SOON') {
      list = list.where((d) => d.computedDistributionStatus == 'UPCOMING').toList();
    }

    if (_sortOption == DistributionSortOption.availability) {
      list.sort((a, b) => b.remainingQuantity.compareTo(a.remainingQuantity));
    } else if (_sortOption == DistributionSortOption.endingSoon) {
      list.sort((a, b) {
        if (a.endTime == null) return 1;
        if (b.endTime == null) return -1;
        return a.endTime!.compareTo(b.endTime!);
      });
    }

    return list;
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSortOption(DistributionSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void _startRealtimeListeners() {
    if (Firebase.apps.isEmpty) return;
    _activeSub?.cancel();
    _activeSub = _repository.streamActiveDistributions().listen((list) {
      if (list.isNotEmpty) {
        _allActiveDistributions = list;
        notifyListeners();
      }
    });
  }

  void bindNgoAccount(String ngoId) {
    if (Firebase.apps.isEmpty) return;
    _ngoSub?.cancel();
    _ngoSub = _repository.streamNgoDistributions(ngoId).listen((list) {
      if (list.isNotEmpty) {
        _myNgoDistributions = list;
        notifyListeners();
      }
    });
  }

  Future<ResourceDistribution> createDistribution(ResourceDistribution item) async {
    _isLoading = true;
    notifyListeners();

    final created = await _repository.createDistribution(item);
    _allActiveDistributions.insert(0, created);
    _myNgoDistributions.insert(0, created);

    if (created.severity == 'IMPORTANT' || created.severity == 'URGENT') {
      OneSignalService().sendDistributionAlert(
        title: created.title,
        body: '${created.category.displayName} available at ${created.locationName} (${created.quantity} ${created.unit}).',
        distributionId: created.id,
      );
    }

    _isLoading = false;
    notifyListeners();
    return created;
  }

  Future<void> updateQuantity(String distributionId, String ngoId, int newRemainingQuantity) async {
    await _repository.updateQuantity(distributionId, ngoId, newRemainingQuantity);
    _updateLocalItem(distributionId, (item) => item.copyWith(remainingQuantity: newRemainingQuantity));
  }

  Future<void> updateQueue(String distributionId, String ngoId, int currentQueue, int estWaitMinutes) async {
    await _repository.updateQueue(distributionId, ngoId, currentQueue: currentQueue, estWaitMinutes: estWaitMinutes);
    _updateLocalItem(distributionId, (item) => item.copyWith(currentQueue: currentQueue, estimatedQueueMinutes: estWaitMinutes));
  }

  Future<void> cancelDistribution(String distributionId, String ngoId) async {
    await _repository.cancelDistribution(distributionId, ngoId);
    _updateLocalItem(distributionId, (item) => item.copyWith(cancelledAt: DateTime.now()));
  }

  Future<void> completeDistribution(String distributionId, String ngoId) async {
    await _repository.completeDistribution(distributionId, ngoId);
    _updateLocalItem(distributionId, (item) => item.copyWith(remainingQuantity: 0, completedAt: DateTime.now()));
  }

  Future<void> adminVerifyDistribution(String distributionId, String adminUid, bool isVerified) async {
    await _repository.adminVerifyDistribution(distributionId, adminUid, isVerified);
    _updateLocalItem(distributionId, (item) => item.copyWith(isVerified: isVerified));
  }

  void _updateLocalItem(String id, ResourceDistribution Function(ResourceDistribution) transform) {
    final idxA = _allActiveDistributions.indexWhere((d) => d.id == id);
    if (idxA != -1) {
      _allActiveDistributions[idxA] = transform(_allActiveDistributions[idxA]);
    }
    final idxM = _myNgoDistributions.indexWhere((d) => d.id == id);
    if (idxM != -1) {
      _myNgoDistributions[idxM] = transform(_myNgoDistributions[idxM]);
    }
    notifyListeners();
  }

  void _initSampleData() {
    final now = DateTime.now();
    _allActiveDistributions = [
      ResourceDistribution(
        id: 'dist-001',
        ngoId: 'ngo-001',
        ngoName: 'Shivdharma Seva Trust',
        title: 'Free Mahaprasad & Tea Distribution',
        category: DistributionCategory.FOOD,
        subcategory: 'Meals & Tea',
        description: 'Hot khichdi mahaprasad and fresh tea for all Varkari pilgrims.',
        quantity: 1000,
        unit: 'meals',
        remainingQuantity: 650,
        latitude: 18.5204,
        longitude: 73.8567,
        locationName: 'Near Alandi Bus Stand Gate 2',
        address: 'Alandi Route, Pune',
        distributionDate: now,
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(hours: 3)),
        instructions: 'Please maintain a queue and follow volunteer instructions. Token distribution at counter.',
        servingCapacity: 500,
        currentQueue: 42,
        estimatedQueueMinutes: 10,
        tokensRequired: true,
        contactName: 'Rameshwar Patil',
        contactPhone: '+91 98220 12345',
        severity: 'IMPORTANT',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      ResourceDistribution(
        id: 'dist-002',
        ngoId: 'ngo-002',
        ngoName: 'Vitthal Kripa Hydration Trust',
        title: 'Cold Mineral Water & ORS Packets',
        category: DistributionCategory.WATER,
        subcategory: 'Drinking Water & ORS',
        description: 'Purified cold drinking water bottles and electrolyte ORS packets.',
        quantity: 2000,
        unit: 'bottles',
        remainingQuantity: 1400,
        latitude: 18.5220,
        longitude: 73.8580,
        locationName: 'Saswad Ringan Ground Corner',
        address: 'Saswad Highway',
        distributionDate: now,
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now.add(const Duration(hours: 5)),
        instructions: 'Free for all pilgrims. Reusable bottles can also be refilled.',
        servingCapacity: 1000,
        currentQueue: 15,
        estimatedQueueMinutes: 3,
        tokensRequired: false,
        contactName: 'Suresh Deshmukh',
        contactPhone: '+91 94220 54321',
        severity: 'NORMAL',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ),
      ResourceDistribution(
        id: 'dist-003',
        ngoId: 'ngo-001',
        ngoName: 'Shivdharma Seva Trust',
        title: 'Emergency Medical & Foot Care Camp',
        category: DistributionCategory.MEDICAL_SUPPLIES,
        subcategory: 'First-aid & Bandages',
        description: 'Blister treatment, foot massage, pain relief sprays, and basic medicines.',
        quantity: 500,
        unit: 'kits',
        remainingQuantity: 320,
        latitude: 18.5190,
        longitude: 73.8550,
        locationName: 'Hadapsar Pandal 4 Medical Tent',
        address: 'Hadapsar Bypass Road',
        distributionDate: now,
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 4)),
        instructions: 'Qualified doctors and medical volunteers on duty.',
        servingCapacity: 200,
        currentQueue: 8,
        estimatedQueueMinutes: 5,
        tokensRequired: false,
        contactName: 'Dr. Ananya Joshi',
        contactPhone: '+91 98900 11223',
        severity: 'URGENT',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 2)),
      ),
    ];
    _myNgoDistributions = List.from(_allActiveDistributions);
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _ngoSub?.cancel();
    super.dispose();
  }
}
