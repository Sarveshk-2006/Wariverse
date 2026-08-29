import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/wari_location_service.dart';
import 'package:mobile/repositories/emergency_contact_repository.dart';
import 'package:mobile/providers/emergency_contact_provider.dart';
import 'package:mobile/repositories/sos_repository.dart';
import 'package:mobile/providers/sos_provider.dart';
import 'package:mobile/models/models_exports.dart';
import 'test_helpers.dart';

void main() {
  group('Phase R2 — Location Service & Position Capture Tests', () {
    test('WariLocationService acquires position correctly', () async {
      final locService = WariLocationService();
      final pos = await locService.getCurrentPosition();

      expect(pos, isNotNull);
      expect(pos.timestamp, isNotNull);
      expect(pos.toJson().containsKey('latitude'), true);
      expect(pos.toJson().containsKey('status'), true);
    });
  });

  group('Phase R2 — Emergency Contacts Model & Logic Tests', () {
    test('EmergencyContact normalizes Indian +91 phone numbers', () {
      expect(EmergencyContact.normalizePhoneNumber('9876543210'), '+919876543210');
      expect(EmergencyContact.normalizePhoneNumber('+91 98765 43210'), '+919876543210');
      expect(EmergencyContact.normalizePhoneNumber('+919876543210'), '+919876543210');
    });

    test('EmergencyContactProvider enforces 5 contact maximum limit', () async {
      final apiService = ApiService(client: MockTestHttpClient());
      final repo = EmergencyContactRepository(apiService);
      final provider = EmergencyContactProvider(repo);

      for (int i = 1; i <= 5; i++) {
        final added = await provider.addContact(
          name: 'Contact $i',
          phoneNumber: '987654321$i',
          relationship: 'Family',
          priority: i,
        );
        expect(added, true);
      }

      expect(provider.contacts.length, 5);
      expect(provider.canAddMore, false);

      final sixthAdded = await provider.addContact(
        name: 'Contact 6',
        phoneNumber: '9876543216',
        relationship: 'Friend',
        priority: 6,
      );
      expect(sixthAdded, false);
    });
  });

  group('Phase R2 — SOS Realtime State Machine & Idempotency Tests', () {
    test('SosProvider triggers SOS and manages live state machine', () async {
      final apiService = ApiService(client: MockTestHttpClient());
      final sosRepo = SosRepository(apiService);
      final provider = SosProvider(sosRepo: sosRepo);

      expect(provider.uiState, SosUiState.idle);

      await provider.triggerSos(
        category: SOSCategory.MEDICAL,
        latitude: 18.5204,
        longitude: 73.8567,
        description: 'Test SOS trigger',
      );

      expect(provider.uiState, SosUiState.active);
      expect(provider.activeIncident, isNotNull);

      await provider.resolveActiveSOS();
      expect(provider.uiState, SosUiState.idle);
      expect(provider.activeIncident, isNull);
    });
  });
}
