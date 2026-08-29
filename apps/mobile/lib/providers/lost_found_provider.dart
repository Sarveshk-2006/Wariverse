import 'package:flutter/material.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';
import '../core/errors/app_exception.dart';

class LostFoundProvider extends ChangeNotifier {
  LostFoundProvider({required LostFoundRepository repository})
      : _repository = repository;

  final LostFoundRepository _repository;

  List<LostPerson> _persons = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isFromMock = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _activeFilter = 'ALL'; // ALL, MISSING, FOUND

  List<LostPerson> get persons => _persons;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isFromMock => _isFromMock;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get activeFilter => _activeFilter;

  List<LostPerson> get filteredPersons {
    return _persons.where((p) {
      if (_activeFilter == 'MISSING' && !p.isMissing) return false;
      if (_activeFilter == 'FOUND' && p.isMissing) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          (p.description?.toLowerCase().contains(q) ?? false) ||
          (p.emergencyContact?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> loadLostPersons() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getLostPersons();
      _persons = res.persons;
      _isFromMock = res.isFromMock;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load lost & found records.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<bool> reportLostPerson({
    required String name,
    int? age,
    String? gender,
    String? description,
    String? emergencyContact,
    String? bloodGroup,
    required String reportedBy,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPerson = LostPerson(
        id: '',
        name: name,
        age: age,
        gender: gender,
        description: description,
        reportedBy: reportedBy,
        emergencyContact: emergencyContact,
        bloodGroup: bloodGroup,
        status: 'MISSING',
        createdAt: DateTime.now(),
      );

      final result = await _repository.reportLostPerson(newPerson);
      _persons.insert(0, result);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit report. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsFound(String id) async {
    try {
      final updated = await _repository.markAsFound(id);
      final index = _persons.indexWhere((p) => p.id == id);
      if (index != -1) {
        _persons[index] = updated;
        notifyListeners();
      }
    } catch (_) {}
  }
}
