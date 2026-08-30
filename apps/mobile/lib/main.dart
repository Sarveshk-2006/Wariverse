import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/wari_theme_exports.dart';
import 'navigation/app_router.dart';
import 'navigation/app_routes.dart';
import 'providers/user_provider.dart';
import 'services/api_service.dart';
import 'services/onesignal_service.dart';
import 'services/notification_navigation_handler.dart';

import 'providers/sos_provider.dart';
import 'services/websocket_service.dart';

import 'providers/map_provider.dart';
import 'repositories/repositories_exports.dart';

import 'providers/ngo_distribution_provider.dart';
import 'providers/offline_map_provider.dart';
import 'providers/nearby_services_provider.dart';
import 'providers/qr_provider.dart';
import 'providers/virtual_dindi_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/cleanwari_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase Core Initialization (Intact)
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully — Project: wariverse-a8fca');
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // 2. OneSignal SDK Initialization
  await OneSignalService().initialize(appId: OneSignalService.defaultAppId);

  final apiService = ApiService();
  final authRepository = AuthRepository(apiService);
  final sosRepository = SosRepository(apiService);
  final serviceRepo = ServiceRepository(apiService);
  final crowdRepo = CrowdRepository(apiService);
  final incidentRepository = IncidentRepository();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SosRepository>.value(value: sosRepository),
        Provider<ServiceRepository>.value(value: serviceRepo),
        Provider<CrowdRepository>.value(value: crowdRepo),
        Provider<IncidentRepository>.value(value: incidentRepository),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authRepository)..loadSavedSession(),
        ),
        ChangeNotifierProvider<SosProvider>(
          create: (_) => SosProvider(
            sosRepo: sosRepository,
            wsService: WebSocketService(),
          ),
        ),
        ChangeNotifierProvider<MapProvider>(
          create: (_) => MapProvider(
            serviceRepo: serviceRepo,
            crowdRepo: crowdRepo,
            sosRepo: sosRepository,
          ),
        ),
        ChangeNotifierProvider<NgoDistributionProvider>(
          create: (_) => NgoDistributionProvider(),
        ),
        ChangeNotifierProvider<OfflineMapProvider>(
          create: (_) => OfflineMapProvider(),
        ),
        ChangeNotifierProvider<QrProvider>(
          create: (_) => QrProvider(),
        ),
        ChangeNotifierProvider<VirtualDindiProvider>(
          create: (_) => VirtualDindiProvider(),
        ),
        ChangeNotifierProvider<IncidentProvider>(
          create: (_) => IncidentProvider(repository: incidentRepository),
        ),
        Provider<CleanWariRepository>(
          create: (_) => CleanWariRepository(apiService),
        ),
        ChangeNotifierProvider<CleanWariProvider>(
          create: (ctx) => CleanWariProvider(
            repository: Provider.of<CleanWariRepository>(ctx, listen: false),
          ),
        ),
        ChangeNotifierProvider<NearbyServicesProvider>(
          create: (_) => NearbyServicesProvider(serviceRepo: serviceRepo),
        ),
      ],
      child: const WariVerseApp(),
    ),
  );
}

/// Root application widget for WariVerse AI mobile client.
class WariVerseApp extends StatefulWidget {
  const WariVerseApp({super.key});

  @override
  State<WariVerseApp> createState() => _WariVerseAppState();
}

class _WariVerseAppState extends State<WariVerseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _verificationDialogShown = false;
  late final OSPushSubscriptionObserver _subscriptionObserver;

  @override
  void initState() {
    super.initState();
    NotificationNavigationHandler().setNavigatorKey(_navigatorKey);
    _setupPushSubscriptionObserver();
  }

  void _setupPushSubscriptionObserver() {
    _subscriptionObserver = (state) {
      final currentId = state.current.id;
      _evaluateSubscriptionAndShowDialog(currentId);
    };

    OneSignalService().addSubscriptionObserver(_subscriptionObserver);

    // Evaluate current subscription ID immediately at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentId = OneSignalService().getSubscriptionId();
      _evaluateSubscriptionAndShowDialog(currentId);
    });
  }

  void _evaluateSubscriptionAndShowDialog(String? subscriptionId) {
    if (_verificationDialogShown) return;
    if (!OneSignalService.isServerAssignedSubscriptionId(subscriptionId)) return;

    _verificationDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context == null || !mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Your OneSignal SDK integration is complete!'),
          content: const Text(
            'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                OneSignalService().requestPermission();
              },
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    OneSignalService().removeSubscriptionObserver(_subscriptionObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: WariTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
