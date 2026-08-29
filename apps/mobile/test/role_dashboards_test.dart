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

void main() {
  Widget buildTestableApp({UserRole role = UserRole.VARKARI}) {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final sosRepo = SosRepository(apiService);
    final sosProvider = SosProvider(sosRepo: sosRepo);

    final userProvider = UserProvider(authRepository)..initDefaultDemoUser();
    userProvider.switchRole(role);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SosRepository>.value(value: sosRepo),
        ChangeNotifierProvider<SosProvider>.value(value: sosProvider),
        ChangeNotifierProvider<QrProvider>(create: (_) => QrProvider()),
        ChangeNotifierProvider<NgoDistributionProvider>(create: (_) => NgoDistributionProvider()),
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
    await tester.pumpAndSettle();

    expect(find.textContaining('Role: VARKARI'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(find.text('Volunteer'), findsWidgets);
    expect(find.text('STATUS: AVAILABLE'), findsOneWidget);
    expect(find.text('Active SOS'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Police role routes to consolidated Command Center dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.POLICE));
    await tester.pumpAndSettle();

    expect(find.text('Command Center Admin'), findsWidgets);
    expect(find.text('Red Crowd Zones'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Medical role routes to consolidated Command Center dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.MEDICAL_TEAM));
    await tester.pumpAndSettle();

    expect(find.text('Command Center Admin'), findsWidgets);
    expect(find.text('Active SOS'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('NGO dashboard renders food and shelter capacity progress bars', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.NGO));
    await tester.pumpAndSettle();

    expect(find.text('NGO Coordinator'), findsWidgets);
    expect(find.textContaining('Food'), findsWidgets);
    expect(find.textContaining('Shelter'), findsWidgets);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('Admin Command Center dashboard renders multi-kpi analytics stats', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp(role: UserRole.ADMIN));
    await tester.pumpAndSettle();

    expect(find.text('COMMAND CENTER ADMIN'), findsWidgets);
    expect(find.text('Active Varkaris'), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
