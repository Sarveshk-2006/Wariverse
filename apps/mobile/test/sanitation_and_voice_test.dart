import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/models/cleanliness_report.dart';
import 'package:mobile/services/sanitation_priority_engine.dart';
import 'package:mobile/features/voice_assistant/wari_voice_assistant_screen.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/virtual_dindi_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'test_helpers.dart';

void main() {
  group('Sanitation Priority Engine & GPS Tests', () {
    test('Calculates CRITICAL priority for OVERFLOW issues', () {
      final priority = SanitationPriorityEngine.calculatePriority(
        issueType: CleanlinessIssueType.OVERFLOW,
        description: 'Water overflow hazard near main entrance',
      );
      expect(priority, CleanlinessReportPriority.CRITICAL);
    });

    test('Calculates HIGH priority for NO_WATER with urgency keywords', () {
      final priority = SanitationPriorityEngine.calculatePriority(
        issueType: CleanlinessIssueType.NO_WATER,
        description: 'Sanitation emergency block',
      );
      expect(priority == CleanlinessReportPriority.HIGH || priority == CleanlinessReportPriority.CRITICAL, isTrue);
    });

    test('Validates GPS coordinates correctly', () {
      expect(SanitationPriorityEngine.isValidCoordinate(18.5204, 73.8567), isTrue);
      expect(SanitationPriorityEngine.isValidCoordinate(0.0, 0.0), isFalse);
      expect(SanitationPriorityEngine.isValidCoordinate(null, 73.8567), isFalse);
      expect(SanitationPriorityEngine.isValidCoordinate(100.0, 73.8567), isFalse);
    });
  });

  group('Voice Assistant Widget Tests', () {
    testWidgets('WariVoiceAssistantScreen renders voice mic and greeting', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;

      final apiService = ApiService(client: MockTestHttpClient());
      final authRepo = AuthRepository(apiService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider(authRepo)..initDefaultDemoUser()),
            ChangeNotifierProvider<VirtualDindiProvider>(create: (_) => VirtualDindiProvider()),
          ],
          child: const MaterialApp(
            home: WariVoiceAssistantScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Voice Assistant'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
