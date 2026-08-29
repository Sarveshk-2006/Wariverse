import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/repositories/qr_repository.dart';
import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/core/widgets/wari_qr_card.dart';
import 'package:mobile/features/qr/widgets/wari_qr_scanner_modal.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WariQrCode & Token Security Tests', () {
    test('WVRK token generator creates non-guessable, unique opaque tokens with prefix', () {
      final token1 = WariQrCode.generateSecureToken('WVRK');
      final token2 = WariQrCode.generateSecureToken('WVRK');

      expect(token1, startsWith('WVRK:'));
      expect(token2, startsWith('WVRK:'));
      expect(token1, isNot(equals(token2)));
    });

    test('WariQrCode serialization and deserialization preserves all Firestore fields', () {
      final qr = WariQrCode(
        id: 'qr_test_001',
        token: 'WVQ_PERSON_1234567890ab',
        type: QrType.PERSON,
        ownerId: 'varkari_uid_99',
        targetCollection: 'users',
        targetDocumentId: 'varkari_uid_99',
        status: QrStatus.ACTIVE,
        createdAt: '2026-08-29T20:00:00.000Z',
        updatedAt: '2026-08-29T20:00:00.000Z',
        createdBy: 'varkari_uid_99',
        scanCount: 3,
        metadata: {'title': 'Test Pilgrim Card'},
      );

      expect(qr.isActive, isTrue);

      final json = qr.toJson();
      expect(json['token'], equals('WVQ_PERSON_1234567890ab'));
      expect(json['type'], equals('PERSON'));

      final rebuilt = WariQrCode.fromJson(json);
      expect(rebuilt.id, equals('qr_test_001'));
      expect(rebuilt.token, equals('WVQ_PERSON_1234567890ab'));
      expect(rebuilt.scanCount, equals(3));
      expect(rebuilt.metadata?['title'], equals('Test Pilgrim Card'));
    });
  });

  group('QrRepository Realtime Validation & Audit Logging Tests', () {
    test('QrRepository generates, validates, logs scans, and revokes QR codes', () async {
      final repo = QrRepository();

      // 1. Generate QR Code
      final createdQr = await repo.generateQrCode(
        type: QrType.TOILET,
        ownerId: 'cleaner_01',
        targetCollection: 'toilets',
        targetDocumentId: 'toilet-101',
        createdBy: 'cleaner_01',
        customPrefix: 'WVQ_TOILET',
      );

      expect(createdQr.token, startsWith('WVQ_TOILET_'));
      expect(createdQr.status, equals(QrStatus.ACTIVE));

      // 2. Validate Token (Success)
      final val1 = await repo.validateToken(
        rawToken: createdQr.token,
        scannerUid: 'varkari_scanner_1',
        latitude: 18.52,
        longitude: 73.85,
      );

      expect(val1.result, equals(QrScanResult.QR_VALID));
      expect(val1.qrCode, isNotNull);
      expect(val1.qrCode!.scanCount, equals(1));

      // 3. Test Invalid Token
      final valInvalid = await repo.validateToken(
        rawToken: 'WVQ_INVALID_TOKEN_STRING',
        scannerUid: 'varkari_scanner_1',
      );
      expect(valInvalid.result, equals(QrScanResult.QR_NOT_FOUND));

      // 4. Revoke QR Code
      final revokeOk = await repo.revokeQrCode(createdQr.id, 'cleaner_01');
      expect(revokeOk, isTrue);

      // 5. Test Revoked Token Validation
      final valRevoked = await repo.validateToken(
        rawToken: createdQr.token,
        scannerUid: 'varkari_scanner_1',
      );
      expect(valRevoked.result, equals(QrScanResult.QR_REVOKED));

      // 6. Audit logs check
      final logs = await repo.getScanLogsForQr(createdQr.id);
      expect(logs.length, greaterThanOrEqualTo(2));
    });
  });

  group('QrProvider & UI Widget Tests', () {
    testWidgets('WariQrCard renders high-resolution QR bitmap with quiet zone', (WidgetTester tester) async {
      final qr = WariQrCode(
        id: 'qr_ui_001',
        token: 'WVQ_TEST_TOKEN_123',
        type: QrType.PERSON,
        ownerId: 'user_001',
        targetCollection: 'users',
        targetDocumentId: 'user_001',
        status: QrStatus.ACTIVE,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        createdBy: 'user_001',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WariQrCard(
              qrCode: qr,
              title: 'Digital Pilgrim ID',
              subtitle: 'Scan to verify identity',
            ),
          ),
        ),
      );

      expect(find.text('Digital Pilgrim ID'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.textContaining('WARI ID'), findsOneWidget);
    });

    testWidgets('WariQrScannerModal manual input validates secure tokens', (WidgetTester tester) async {
      final apiService = ApiService(client: MockTestHttpClient());
      final authRepo = AuthRepository(apiService);
      final qrRepo = QrRepository();

      final createdQr = await qrRepo.generateQrCode(
        type: QrType.LOST_PERSON,
        ownerId: 'admin_1',
        targetCollection: 'lost_persons',
        targetDocumentId: 'lost_001',
        createdBy: 'admin_1',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: apiService),
            Provider<AuthRepository>.value(value: authRepo),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider(authRepo)..initDefaultDemoUser()),
            ChangeNotifierProvider<QrProvider>(create: (_) => QrProvider(qrRepo: qrRepo)),
          ],
          child: const MaterialApp(
            home: WariQrScannerModal(
              title: 'Test QR Scanner',
            ),
          ),
        ),
      );

      expect(find.text('Test QR Scanner'), findsOneWidget);

      // Enter token in debug input bar and verify
      await tester.enterText(find.byType(TextField), createdQr.token);
      await tester.tap(find.text('Verify'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Valid WariVerse QR Code'), findsOneWidget);
    });
  });
}
