import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/config/role_capabilities.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/dashboards/role_dashboard_view.dart';
import 'package:mobile/providers/sos_provider.dart';
import 'package:mobile/repositories/sos_repository.dart';
import 'test_helpers.dart';

import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/providers/ngo_distribution_provider.dart';

import 'package:mobile/providers/virtual_dindi_provider.dart';
import 'package:mobile/providers/incident_provider.dart';
import 'package:mobile/providers/nearby_services_provider.dart';

import 'package:mobile/providers/map_provider.dart';
import 'package:mobile/repositories/service_repository.dart';

import 'package:mobile/repositories/crowd_repository.dart';

void main() {
  Widget buildTestableApp({UserRole role = UserRole.VARKARI}) {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final sosRepo = SosRepository(apiService);
    final serviceRepo = ServiceRepository(apiService);
    final sosProvider = SosProvider(sosRepo: sosRepo);

    final userProvider = UserProvider(authRepository)..initDefaultDemoUser();
    userProvider.switchRole(role);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SosRepository>.value(value: sosRepo),
        Provider<ServiceRepository>.value(value: serviceRepo),
        ChangeNotifierProvider<SosProvider>.value(value: sosProvider),
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
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ],
      child: MaterialApp(
        builder: (context, child) => TooltipVisibility(visible: false, child: child!),
        home: const Scaffold(body: RoleDashboardView()),
      ),
    );
  }

  test('RoleCapabilities evaluates capability flags per role', () {
    final varkariCap = RoleCapabilities.of(UserRole.VARKARI);
    expect(varkariCap.canViewCrowd, true);
    expect(varkariCap.canManageIncidents, false);

    final volunteerCap = RoleCapabilities.of(UserRole.VOLUNTEER);
    expect(volunteerCap.canToggleVolunteerStatus, true);
    expect(volunteerCap.canManageIncidents, true);

    final policeCap = RoleCapabilities.of(UserRole.POLICE);
    expect(policeCap.canManageIncidents, true);

    final adminCap = RoleCapabilities.of(UserRole.ADMIN);
    expect(adminCap.canViewAnalytics, true);
    expect(adminCap.canManageResources, true);
  });

  testWidgets('Varkari dashboard renders devotional header and pilgrim cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.VARKARI));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Varkari'), findsWidgets);
    expect(find.textContaining('LIVE WARI RESOURCES'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Volunteer dashboard renders status toggle and incident response cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.VOLUNTEER));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Volunteer'), findsWidgets);
    expect(find.text('STATUS: AVAILABLE'), findsOneWidget);
    expect(find.text('Active SOS'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Police role routes to Volunteer operational dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.POLICE));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Volunteer'), findsWidgets);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Medical role routes to Volunteer operational dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.MEDICAL_TEAM));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Volunteer'), findsWidgets);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('NGO role displays Web Portal Redirection view on mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.NGO));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('WariVerse Operations Web'), findsOneWidget);
    expect(find.textContaining('OPEN OPERATIONS WEB PORTAL'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Admin role displays Web Portal Redirection view on mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.ADMIN));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('WariVerse Operations Web'), findsOneWidget);
    expect(find.textContaining('OPEN OPERATIONS WEB PORTAL'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
