import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/shell/wari_app_shell.dart';
import 'package:mobile/navigation/app_router.dart';
import 'package:mobile/navigation/role_navigation_config.dart';
import 'test_helpers.dart';

import 'package:mobile/features/lost_found/lost_found_screen.dart';
import 'package:mobile/providers/sos_provider.dart';
import 'package:mobile/providers/map_provider.dart';
import 'package:mobile/repositories/repositories_exports.dart';

import 'package:mobile/providers/ngo_distribution_provider.dart';
import 'package:mobile/providers/offline_map_provider.dart';
import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/providers/virtual_dindi_provider.dart';
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

    final ngoProvider = NgoDistributionProvider();
    final offlineMapProvider = OfflineMapProvider();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SosRepository>.value(value: sosRepo),
        Provider<ServiceRepository>.value(value: serviceRepo),
        Provider<CrowdRepository>.value(value: crowdRepo),
        ChangeNotifierProvider<SosProvider>.value(value: sosProvider),
        ChangeNotifierProvider<MapProvider>.value(value: mapProvider),
        ChangeNotifierProvider<NgoDistributionProvider>.value(value: ngoProvider),
        ChangeNotifierProvider<OfflineMapProvider>.value(value: offlineMapProvider),
        ChangeNotifierProvider<QrProvider>(create: (_) => QrProvider()),
        ChangeNotifierProvider<VirtualDindiProvider>(create: (_) => VirtualDindiProvider()),
        ChangeNotifierProvider<IncidentProvider>(create: (_) => IncidentProvider()),
        ChangeNotifierProvider<NearbyServicesProvider>(
          create: (_) => NearbyServicesProvider(serviceRepo: serviceRepo),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => TooltipVisibility(visible: false, child: child!),
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: WariAppShell(tileProvider: TestTileProvider()),
      ),
    );
  }

  testWidgets('App shell loads and displays primary navigation tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('WariVerse'), findsWidgets);
    expect(find.text('HOME'), findsWidgets);
    expect(find.text('LIVE MAP'), findsWidgets);
    expect(find.text('SAFETY'), findsWidgets);
    expect(find.text('SERVICES'), findsWidgets);
    expect(find.text('PROFILE'), findsWidgets);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Tab switching changes active content placeholder', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Tap on Map tab
    await tester.tap(find.textContaining('MAP').last);
    await tester.pumpAndSettle();
    expect(find.text('Everything'), findsOneWidget);

    // Tap on SAFETY tab
    await tester.tap(find.textContaining('SAFETY').last);
    await tester.pumpAndSettle();
    expect(find.text('Emergency Help is One Tap Away'), findsWidgets);

    // Tap on SERVICES tab
    await tester.tap(find.textContaining('SERVICES').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Services'), findsWidgets);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Role switching updates UserProvider state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(WariAppShell));
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    expect(userProvider.currentRole, UserRole.VARKARI);

    userProvider.switchRole(UserRole.VOLUNTEER);
    await tester.pumpAndSettle();

    expect(userProvider.currentRole, UserRole.VOLUNTEER);
    expect(find.text('Volunteer'), findsWidgets);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Quick action tap navigates to detail route', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    final tileFinder = find.text('Lost & Found').first;
    await tester.tap(tileFinder);
    await tester.pumpAndSettle();

    expect(find.byType(LostFoundScreen), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('RoleNavigationConfig provides 5 distinct operational tabs for each of the 6 roles', () {
    final varkariTabs = RoleNavigationConfig.getTabsForRole(UserRole.VARKARI);
    expect(varkariTabs.length, 5);
    expect(varkariTabs.map((t) => t.label), containsAll(['HOME', 'LIVE MAP', 'SAFETY', 'SERVICES', 'PROFILE']));

    final dindiTabs = RoleNavigationConfig.getTabsForRole(UserRole.DINDI_LEADER);
    expect(dindiTabs.length, 5);
    expect(dindiTabs.map((t) => t.label), containsAll(['COMMAND', 'MY DINDI', 'LIVE MAP', 'MEMBERS', 'PROFILE']));

    final volunteerTabs = RoleNavigationConfig.getTabsForRole(UserRole.VOLUNTEER);
    expect(volunteerTabs.length, 5);
    expect(volunteerTabs.map((t) => t.label), containsAll(['RESPONSE QUEUE', 'LIVE MAP', 'ACTIVE TASK', 'HISTORY', 'PROFILE']));

    final ngoTabs = RoleNavigationConfig.getTabsForRole(UserRole.NGO);
    expect(ngoTabs.length, 3);
    expect(ngoTabs.map((t) => t.label), containsAll(['WEB DASHBOARD', 'SOS HISTORY', 'PROFILE']));

    final cleanerTabs = RoleNavigationConfig.getTabsForRole(UserRole.CLEANER);
    expect(cleanerTabs.length, 5);
    expect(cleanerTabs.map((t) => t.label), containsAll(['RESPONSE QUEUE', 'LIVE MAP', 'ACTIVE TASK', 'HISTORY', 'PROFILE']));

    final adminTabs = RoleNavigationConfig.getTabsForRole(UserRole.ADMIN);
    expect(adminTabs.length, 3);
    expect(adminTabs.map((t) => t.label), containsAll(['WEB DASHBOARD', 'SOS HISTORY', 'PROFILE']));
  });
}
