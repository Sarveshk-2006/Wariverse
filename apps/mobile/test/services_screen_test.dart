import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'test_helpers.dart';

import 'package:mobile/features/services/services_screen.dart';

void main() {
  Widget buildTestableApp() {
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
        home: const ServicesScreen(),
      ),
    );
  }

  testWidgets('Services screen renders search, categories, and service cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.text('All Services'), findsOneWidget);
    expect(find.text('Annadan Food'), findsWidgets);
    expect(find.text('Water Station'), findsWidgets);
    expect(find.text('Medical Camp'), findsWidgets);

    addTearDown(() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Filtering by category updates visible service list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Tap Food category chip
    await tester.tap(find.text('Annadan Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Annadan Food'), findsWidgets);

    // Tap Water category chip
    await tester.tap(find.text('Water Station').first);
    await tester.pumpAndSettle();

    expect(find.text('Water Station'), findsWidgets);

    addTearDown(() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Search query filters services and displays empty state when no match', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Enter search query
    await tester.enterText(find.byType(TextField), 'NonExistentServiceXYZ');
    await tester.pumpAndSettle();

    expect(find.text('No Matching Services Found'), findsOneWidget);

    // Reset search
    await tester.tap(find.text('Reset Search & Filters'));
    await tester.pumpAndSettle();

    // Clear focus before test completion
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    addTearDown(() async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
