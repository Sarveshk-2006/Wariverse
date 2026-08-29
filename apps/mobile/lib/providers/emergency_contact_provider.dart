import 'package:flutter/foundation.dart';
import '../models/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';

class EmergencyContactProvider extends ChangeNotifier {
  final EmergencyContactRepository _repo;

  EmergencyContactProvider(this._repo) {
    loadContacts();
  }

  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;
  bool _isFromMock = false;
  String? _errorMessage;

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  bool get isFromMock => _isFromMock;
  String? get errorMessage => _errorMessage;

  bool get canAddMore => _contacts.length < 5;

  Future<void> loadContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.getContacts();
      _contacts = res.contacts;
      _isFromMock = res.isFromMock;
    } catch (e) {
      _errorMessage = 'Failed to load emergency contacts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    required int priority,
  }) async {
    if (_contacts.length >= 5) {
      _errorMessage = 'Maximum 5 emergency contacts permitted.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.addContact(
        name: name,
        phoneNumber: phoneNumber,
        relationship: relationship,
        priority: priority,
      );
      _contacts.add(res.contact);
      _contacts.sort((a, b) => a.priority.compareTo(b.priority));
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add contact: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteContact(String contactId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repo.deleteContact(contactId);
      _contacts.removeWhere((c) => c.id == contactId);
    } catch (e) {
      _errorMessage = 'Failed to delete contact: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
