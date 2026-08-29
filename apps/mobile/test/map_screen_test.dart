import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/shell/wari_app_shell.dart';
import 'test_helpers.dart';

import 'package:mobile/providers/sos_provider.dart';
import 'package:mobile/providers/map_provider.dart';
import 'package:mobile/repositories/repositories_exports.dart';

import 'package:mobile/providers/offline_map_provider.dart';
import 'package:mobile/providers/ngo_distribution_provider.dart';
import 'package:mobile/providers/virtual_dindi_provider.dart';
import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/providers/incident_provider.dart';
import 'package:mobile/providers/nearby_services_provider.dart';

void main() {
  Widget buildTestableApp() {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final sosRepo = SosRepository(apiService);
    final sosProvider = SosProvider(sosRepo: sosRepo);
    final serviceRepo = ServiceRepository(apiService);
    final crowdRepo = CrowdRepository(apiService);
    final mapProvider = MapProvider(
      serviceRepo: serviceRepo,
      crowdRepo: crowdRepo,
      sosRepo: sosRepo,
    );

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SosRepository>.value(value: sosRepo),
        Provider<ServiceRepository>.value(value: serviceRepo),
        Provider<CrowdRepository>.value(value: crowdRepo),
        ChangeNotifierProvider<SosProvider>.value(value: sosProvider),
        ChangeNotifierProvider<MapProvider>.value(value: mapProvider),
        ChangeNotifierProvider<OfflineMapProvider>(create: (_) => OfflineMapProvider()),
        ChangeNotifierProvider<NgoDistributionProvider>(create: (_) => NgoDistributionProvider()),
        ChangeNotifierProvider<VirtualDindiProvider>(create: (_) => VirtualDindiProvider()),
        ChangeNotifierProvider<QrProvider>(create: (_) => QrProvider()),
        ChangeNotifierProvider<IncidentProvider>(create: (_) => IncidentProvider()),
        ChangeNotifierProvider<NearbyServicesProvider>(create: (_) => NearbyServicesProvider()),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => TooltipVisibility(visible: false, child: child!),
        home: WariAppShell(
          initialTabIndex: 1,
          tileProvider: TestTileProvider(),
        ),
      ),
    );
  }

  testWidgets('Map screen renders filter bar and floating action controls', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Everything'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Water'), findsWidgets);
    expect(find.text('Medical'), findsWidgets);
    expect(find.text('Report Issue'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Report Issue button opens Crowdsourced Route Issue bottom sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Report Issue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('⚠️ Report Route Issue'), findsOneWidget);
    expect(find.text('Muddy / Flooded'), findsOneWidget);
    expect(find.text('Path Blocked'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('⚠️ Report Route Issue'), findsNothing);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
