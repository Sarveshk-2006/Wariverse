import '../services/api_service.dart';
import '../models/emergency_contact.dart';
import '../core/errors/app_exception.dart';
import '../core/config/env_config.dart';

/// Repository managing up to 5 emergency contacts per user.
class EmergencyContactRepository {
  EmergencyContactRepository(this._api);

  final ApiService _api;
  final List<EmergencyContact> _mockContacts = [];


  Future<({List<EmergencyContact> contacts, bool isFromMock})> getContacts() async {
    try {
      final data = await _api.get('/emergency-contacts');
      final List<EmergencyContact> list = (data as List<dynamic>)
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
      return (contacts: list, isFromMock: false);
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        return (contacts: List<EmergencyContact>.from(_mockContacts), isFromMock: true);
      }
      rethrow;
    }
  }

  Future<({EmergencyContact contact, bool isFromMock})> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    required int priority,
  }) async {
    final payload = {
      'name': name,
      'phone_number': EmergencyContact.normalizePhoneNumber(phoneNumber),
      'relationship_name': relationship,
      'priority': priority,
    };

    try {
      final data = await _api.post('/emergency-contacts', payload);
      final contact = EmergencyContact.fromJson(data as Map<String, dynamic>);
      return (contact: contact, isFromMock: false);
    } on AppException catch (e) {
      if (e.isMockFallbackEligible && EnvConfig.enableMockFallback) {
        final mock = EmergencyContact(
          id: 'mock-ec-${DateTime.now().millisecondsSinceEpoch}',
          userId: 'demo-user-1',
          name: name,
          phoneNumber: EmergencyContact.normalizePhoneNumber(phoneNumber),
          relationship: relationship,
          priority: priority,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _mockContacts.add(mock);
        return (contact: mock, isFromMock: true);
      }
      rethrow;
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      await _api.delete('/emergency-contacts/$contactId');
      _mockContacts.removeWhere((c) => c.id == contactId);
      return true;
    } catch (_) {
      _mockContacts.removeWhere((c) => c.id == contactId);
      return true;
    }
  }
}
