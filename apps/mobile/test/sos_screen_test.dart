import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/sos/sos_screen.dart';
import 'package:mobile/providers/sos_provider.dart';
import 'package:mobile/repositories/sos_repository.dart';
import 'test_helpers.dart';

void main() {

  Widget buildTestableApp([SosProvider? customSosProvider]) {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final sosProvider = customSosProvider ??
        SosProvider(
          sosRepo: SosRepository(apiService),
        );

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
        ChangeNotifierProvider<SosProvider>.value(value: sosProvider),
      ],
      child: MaterialApp(
        builder: (context, child) => TooltipVisibility(visible: false, child: child!),
        home: const SosScreen(),
      ),
    );
  }

  testWidgets('SOS screen renders one-tap emergency trigger button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Emergency Help is One Tap Away'), findsOneWidget);
    expect(find.text('SOS'), findsWidgets);
    expect(find.text('Select Emergency Type'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Tapping SOS button opens confirmation sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap SOS button
    await tester.tap(find.text('SOS').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Confirm Emergency SOS'), findsOneWidget);
    expect(find.text('SEND SOS NOW'), findsOneWidget);

    // Tap CANCEL
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Confirm Emergency SOS'), findsNothing);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Submitting SOS displays active emergency state card', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    final apiService = ApiService(client: MockTestHttpClient());
    final sosProvider = SosProvider(sosRepo: SosRepository(apiService));

    await tester.pumpWidget(buildTestableApp(sosProvider));
    await tester.pumpAndSettle();

    // Tap SOS button
    await tester.tap(find.text('SOS').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap SEND SOS NOW
    await tester.tap(find.text('SEND SOS NOW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('SOS SENT & ACTIVE!'), findsOneWidget);
    expect(find.text('INCIDENT REF'), findsOneWidget);
    expect(find.text('Cancel SOS'), findsOneWidget);
    expect(find.text('Resolve SOS'), findsOneWidget);

    // Resolve SOS
    await tester.tap(find.text('Resolve SOS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Emergency Help is One Tap Away'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
