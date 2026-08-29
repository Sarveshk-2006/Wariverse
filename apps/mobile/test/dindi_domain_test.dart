import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/providers/dindi_provider.dart';
import 'package:mobile/providers/cleanwari_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/repositories/dindi_repository.dart';
import 'package:mobile/repositories/weather_repository.dart';
import 'package:mobile/repositories/cleanwari_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/cleanwari_qr_parser.dart';
import 'package:mobile/services/cleanwari_dispatch_service.dart';
import 'package:mobile/features/cleanwari/cleanwari_qr_scanner_screen.dart';
import 'package:mobile/features/cleanwari/cleanwari_report_screen.dart';
import 'package:mobile/features/cleanwari/cleanwari_cleaner_screen.dart';
import 'test_helpers.dart';

void main() {
  Widget buildTestableApp(Widget child) {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final weatherRepository = WeatherRepository(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<WeatherRepository>.value(value: weatherRepository),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
        ChangeNotifierProvider<DindiProvider>(
          create: (_) => DindiProvider(repository: DindiRepository(apiService))..loadDindis(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('CleanWari IoT Domain & Parser Logic Tests', () {
    test('CleanWariQrParser parses valid toilet QR payloads and rejects invalid inputs', () {
      expect(CleanWariQrParser.parseToiletPayload('cleanwari:toilet:toilet-001'), 'toilet-001');
      expect(CleanWariQrParser.parseToiletPayload('invalid_text'), isNull);
      expect(CleanWariQrParser.parseToiletPayload(''), isNull);
      expect(CleanWariQrParser.isValidPayload('cleanwari:toilet:t-10'), true);
    });

    test('CleanWariDispatchService calculates priority and prevents duplicate reports', () {
      expect(CleanWariDispatchService.calculatePriority(CleanlinessIssueType.NO_WATER), CleanlinessReportPriority.HIGH);
      expect(CleanWariDispatchService.calculatePriority(CleanlinessIssueType.OVERFLOW), CleanlinessReportPriority.HIGH);
      expect(CleanWariDispatchService.calculatePriority(CleanlinessIssueType.NEEDS_CLEANING), CleanlinessReportPriority.MEDIUM);
      expect(CleanWariDispatchService.calculatePriority(CleanlinessIssueType.OTHER), CleanlinessReportPriority.LOW);

      final reports = [
        CleanlinessReport(
          id: '1',
          toiletId: 't-1',
          toiletQrCode: 'cleanwari:toilet:t-1',
          toiletName: 'Facility 1',
          reporterId: 'u-1',
          issueType: CleanlinessIssueType.NO_WATER,
          description: '',
          reportedAt: DateTime.now(),
          status: CleanlinessReportStatus.ASSIGNED,
          priority: CleanlinessReportPriority.HIGH,
        ),
      ];

      expect(CleanWariDispatchService.isDuplicateReport(reports, 't-1', CleanlinessIssueType.NO_WATER), true);
      expect(CleanWariDispatchService.isDuplicateReport(reports, 't-1', CleanlinessIssueType.OVERFLOW), false);
    });

    test('CleanWariProvider submits report and executes task lifecycle', () async {
      final apiService = ApiService(client: MockTestHttpClient());
      final repo = CleanWariRepository(apiService);
      final provider = CleanWariProvider(repository: repo);

      final report = await provider.submitReport(
        toiletId: 'toilet-001',
        toiletQrCode: 'cleanwari:toilet:toilet-001',
        toiletName: 'Pandharpur Halt 03',
        reporterId: 'varkari-001',
        issueType: CleanlinessIssueType.NO_WATER,
        description: 'Water tank empty',
      );

      expect(report, isNotNull);
      expect(report!.status, CleanlinessReportStatus.ASSIGNED);

      await provider.startCleaning(report.id);
      expect(provider.activeReport?.status, CleanlinessReportStatus.IN_PROGRESS);

      await provider.resolveTask(report.id, 'Refilled water tank.');
      expect(provider.activeReport?.status, CleanlinessReportStatus.RESOLVED);
    });
  });

  group('CleanWari UI Screens Tests', () {
    testWidgets('CleanWariQrScannerScreen renders camera viewfinder and demo QR selector chips', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const CleanWariQrScannerScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('CleanWari QR Scanner'), findsOneWidget);
      expect(find.textContaining('Toilet #01'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('CleanWariReportScreen renders facility header and issue choice tiles', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const CleanWariReportScreen(
        toiletId: 'toilet-001',
        toiletQrCode: 'cleanwari:toilet:toilet-001',
        toiletName: 'Pandharpur Halt 03',
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('Report Issue'), findsWidgets);
      expect(find.text('Pandharpur Halt 03'), findsOneWidget);
      expect(find.textContaining('No Water'), findsOneWidget);
      expect(find.textContaining('SUBMIT CLEANLINESS REPORT'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('CleanWariCleanerScreen renders operational dashboard for staff', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const CleanWariCleanerScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('CleanWari Staff Operations'), findsWidgets);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
