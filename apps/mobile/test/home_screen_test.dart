import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/providers/home_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/qr_provider.dart';
import 'package:mobile/providers/virtual_dindi_provider.dart';
import 'package:mobile/repositories/crowd_repository.dart';
import 'package:mobile/repositories/weather_repository.dart';
import 'package:mobile/repositories/service_repository.dart';
import 'package:mobile/repositories/sos_repository.dart';
import 'package:mobile/repositories/admin_repository.dart';
import 'package:mobile/repositories/auth_repository.dart';
import 'package:mobile/services/api_service.dart';
import 'test_helpers.dart';

void main() {
  Widget buildTestableApp() {
    final apiService = ApiService(client: MockTestHttpClient());
    final authRepository = AuthRepository(apiService);
    final crowdRepo = CrowdRepository(apiService);
    final weatherRepo = WeatherRepository(apiService);
    final serviceRepo = ServiceRepository(apiService);
    final sosRepo = SosRepository(apiService);
    final adminRepo = AdminRepository(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..initDefaultDemoUser(),
        ),
        ChangeNotifierProvider<QrProvider>(
          create: (_) => QrProvider(),
        ),
        ChangeNotifierProvider<VirtualDindiProvider>(
          create: (_) => VirtualDindiProvider(),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(
            crowdRepo: crowdRepo,
            weatherRepo: weatherRepo,
            serviceRepo: serviceRepo,
            sosRepo: sosRepo,
            adminRepo: adminRepo,
          ),
        ),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('Home screen renders devotional greeting and header elements', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('WariVerse'), findsWidgets);
    expect(find.textContaining('GPS Active'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Home screen renders status card and quick actions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Quick Actions'), findsOneWidget);
    expect(find.text('SOS Emergency'), findsOneWidget);
    expect(find.text('Live Map'), findsWidgets);
    expect(find.text('Nearby Services'), findsWidgets);
    expect(find.text('My Dindi'), findsWidgets);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  testWidgets('Home screen renders nearest services section', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Essential Services Nearby'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
