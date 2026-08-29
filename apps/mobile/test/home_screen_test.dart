import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'test_helpers.dart';

import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/providers/ngo_distribution_provider.dart';

import 'package:mobile/providers/virtual_dindi_provider.dart';
import 'package:mobile/providers/incident_provider.dart';
import 'package:mobile/providers/nearby_services_provider.dart';
import 'package:mobile/providers/map_provider.dart';
import 'package:mobile/repositories/crowd_repository.dart';
import 'package:mobile/repositories/service_repository.dart';
import 'package:mobile/repositories/sos_repository.dart';

void main() {
  Widget buildTestableApp() {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final serviceRepo = ServiceRepository(apiService);
    final sosRepo = SosRepository(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ServiceRepository>.value(value: serviceRepo),
        Provider<SosRepository>.value(value: sosRepo),
        ChangeNotifierProvider<QrProvider>(create: (_) => QrProvider()),
        ChangeNotifierProvider<NgoDistributionProvider>(create: (_) => NgoDistributionProvider()),
        ChangeNotifierProvider<VirtualDindiProvider>(create: (_) => VirtualDindiProvider()),
        ChangeNotifierProvider<IncidentProvider>(create: (_) => IncidentProvider()),
        ChangeNotifierProvider<NearbyServicesProvider>(create: (_) => NearbyServicesProvider()),
        ChangeNotifierProvider<MapProvider>(
          create: (_) => MapProvider(
            serviceRepo: serviceRepo,
            crowdRepo: CrowdRepository(apiService),
            sosRepo: sosRepo,
          ),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('Home screen renders devotional greeting and header elements', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Palkhi Route'), findsOneWidget);
    expect(find.text('Digital Pilgrim ID'), findsOneWidget);
    expect(find.text('Show e-ID QR'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Home screen renders crowd status card and quick actions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('My Dindi'), findsWidgets);
    expect(find.text('Live Map'), findsWidgets);
    expect(find.text('Smart SOS'), findsWidgets);
    expect(find.text('Lost & Found'), findsWidgets);
    expect(find.text('Community'), findsWidgets);
    expect(find.text('Annadan'), findsWidgets);
    expect(find.text('Water'), findsWidgets);
    expect(find.text('Medical'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Home screen renders nearest services section', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Nearby Services'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Digital Pilgrim ID QR modal opens and closes correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Tap Show e-ID QR button
    await tester.tap(find.text('Show e-ID QR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Digital Pilgrim Identity Card'), findsOneWidget);

    // Close QR modal using close button
    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Digital Pilgrim Identity Card'), findsNothing);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
