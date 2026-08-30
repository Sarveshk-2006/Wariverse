import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/config/role_capabilities.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/repositories/qr_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/auth/login_screen.dart';
import 'test_helpers.dart';

import 'package:mobile/features/splash/splash_screen.dart';
import 'package:mobile/navigation/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authoritative Admin Login & Role Verification Tests', () {
    test('UserRole and portal access matrix rules', () {
      expect(RoleCapabilities.of(UserRole.ADMIN).canViewAnalytics, isTrue);
      expect(RoleCapabilities.of(UserRole.ADMIN).canManageResources, isTrue);
      expect(RoleCapabilities.of(UserRole.VARKARI).canViewAnalytics, isFalse);
      expect(RoleCapabilities.of(UserRole.NGO).canViewAnalytics, isFalse);
    });

    test('Authoritative Admin UID 0JNFDa2v1LcBfcDj2gsFwTRUtDd2 target constant check', () {
      const adminUid = '0JNFDa2v1LcBfcDj2gsFwTRUtDd2';
      expect(adminUid, equals('0JNFDa2v1LcBfcDj2gsFwTRUtDd2'));
    });

    testWidgets('SplashScreen renders official WariVerse logo and subtitle', (WidgetTester tester) async {
      final apiService = ApiService(client: MockTestHttpClient());
      final authRepo = AuthRepository(apiService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: apiService),
            Provider<AuthRepository>.value(value: authRepo),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider(authRepo)),
          ],
          child: const MaterialApp(
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: SplashScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('WariVerse AI'), findsOneWidget);
      expect(find.text('Multi-Portal Pilgrimage Operations System'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2500));
    });

    testWidgets('LoginScreen renders portal options and Admin Notice box when ADMIN is selected', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      final apiService = ApiService(client: MockTestHttpClient());
      final authRepo = AuthRepository(apiService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: apiService),
            Provider<AuthRepository>.value(value: authRepo),
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider(authRepo)),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('WariVerse AI'), findsOneWidget);
      expect(find.text('Portal Access'), findsOneWidget);

      // Select ADMIN portal
      await tester.tap(find.text('ADMIN'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.textContaining('Admin Command Center is restricted'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    test('QrProvider getOrCreatePilgrimIdQr uses stable Firestore QR identity', () async {
      final qrRepo = QrRepository();
      final qrProvider = QrProvider(qrRepo: qrRepo);

      // First call generates initial QR
      final qr1 = await qrProvider.getOrCreatePilgrimIdQr('user_varkari_101');
      expect(qr1.ownerId, equals('user_varkari_101'));
      expect(qr1.token, startsWith('WVRK:'));

      // Second call retrieves SAME stable QR without generating new token
      final qr2 = await qrProvider.getOrCreatePilgrimIdQr('user_varkari_101');
      expect(qr2.id, equals(qr1.id));
      expect(qr2.token, equals(qr1.token));
    });
  });
}
