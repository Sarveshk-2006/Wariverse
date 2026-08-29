import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/shell/wari_app_shell.dart';
import 'package:mobile/navigation/app_router.dart';
import 'test_helpers.dart';

import 'package:mobile/features/lost_found/lost_found_screen.dart';
import 'package:mobile/providers/sos_provider.dart';
import 'package:mobile/providers/map_provider.dart';
import 'package:mobile/repositories/repositories_exports.dart';

import 'package:mobile/providers/ngo_distribution_provider.dart';
import 'package:mobile/providers/offline_map_provider.dart';
import 'package:mobile/providers/qr_provider.dart';

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

    expect(find.text('WariVerse AI'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.textContaining('Map'), findsWidgets);
    expect(find.textContaining('Alerts'), findsWidgets);
    expect(find.text('Services'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

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
    await tester.tap(find.textContaining('Map').last);
    await tester.pumpAndSettle();
    expect(find.text('Everything'), findsOneWidget);

    // Tap on Alerts & SOS tab
    await tester.tap(find.textContaining('Alerts').last);
    await tester.pumpAndSettle();
    expect(find.text('Emergency Help is One Tap Away'), findsWidgets);

    // Tap on Services tab
    await tester.tap(find.text('Services').last);
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
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    final tileFinder = find.text('Lost & Found').first;
    await tester.dragUntilVisible(tileFinder, find.byType(ListView).first, const Offset(0, -100));
    await tester.pumpAndSettle();

    await tester.tap(tileFinder);
    await tester.pumpAndSettle();

    expect(find.byType(LostFoundScreen), findsOneWidget);

    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
