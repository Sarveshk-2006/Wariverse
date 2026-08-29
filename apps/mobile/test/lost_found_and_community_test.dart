import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/lost_found/lost_found_screen.dart';
import 'package:mobile/features/community/community_screen.dart';
import 'test_helpers.dart';

void main() {
  Widget buildTestableApp(Widget child) {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => TooltipVisibility(visible: false, child: child!),
        home: child,
      ),
    );
  }

  group('Lost & Found Recovery Module Tests', () {
    testWidgets('Lost & Found screen renders search bar, filters, and records', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const LostFoundScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Lost & Found Recovery'), findsOneWidget);
      expect(find.text('All Cases'), findsOneWidget);
      expect(find.text('Missing Only'), findsOneWidget);
      expect(find.text('Found / Reunited'), findsOneWidget);
      expect(find.text('Report Missing'), findsOneWidget);

      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('Filtering by status updates missing persons list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const LostFoundScreen()));
      await tester.pumpAndSettle();

      // Tap Missing Only filter
      await tester.tap(find.text('Missing Only'));
      await tester.pumpAndSettle();

      expect(find.text('Missing Only'), findsOneWidget);

      // Tap Found / Reunited filter
      await tester.tap(find.text('Found / Reunited'));
      await tester.pumpAndSettle();

      expect(find.text('Found / Reunited'), findsOneWidget);

      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('Opening Report Missing dialog displays form fields and validates empty submit', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const LostFoundScreen()));
      await tester.pumpAndSettle();

      // Open Report Missing sheet
      await tester.tap(find.text('Report Missing'));
      await tester.pumpAndSettle();

      expect(find.text('Report Missing Person'), findsOneWidget);
      expect(find.text('Submit Missing Person Report'), findsOneWidget);

      // Tap Submit without filling name
      await tester.tap(find.text('Submit Missing Person Report'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);

      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(const SizedBox());
      });
    });
  });

  group('Wari Pilgrim Community Feed Module Tests', () {
    testWidgets('Community screen renders category filters and feed items', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const CommunityScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Wari Pilgrim Community Feed'), findsOneWidget);
      expect(find.text('All Updates'), findsOneWidget);
      expect(find.text('Verified Only'), findsOneWidget);
      expect(find.text('Post Update'), findsOneWidget);

      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('Opening Create Post dialog displays dropdown and message field validation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestableApp(const CommunityScreen()));
      await tester.pumpAndSettle();

      // Open Create Post sheet
      await tester.tap(find.text('Post Update'));
      await tester.pumpAndSettle();

      expect(find.text('Share Community Update'), findsOneWidget);
      expect(find.text('Publish Update'), findsOneWidget);

      // Tap Submit without message
      await tester.tap(find.text('Publish Update'));
      await tester.pumpAndSettle();

      expect(find.text('Message is required'), findsOneWidget);

      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.pumpWidget(const SizedBox());
      });
    });
  });
}
