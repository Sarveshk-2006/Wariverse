import 'package:flutter/material.dart';
import '../models/models_exports.dart';
import '../features/shell/wari_app_shell.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/sos/sos_screen.dart';
import '../features/services/services_screen.dart';
import '../features/lost_found/lost_found_screen.dart';
import '../features/community/community_screen.dart';
import '../features/dindi/dindi_overview_screen.dart';
import '../features/dindi/dindi_schedule_screen.dart';
import '../features/dindi/dindi_qr_scanner_screen.dart';
import '../features/dindi/digital_dindi_pass_screen.dart';
import '../features/dindi/dindi_live_route_screen.dart';
import '../features/dindi/dindi_community_screen.dart';
import '../features/dindi/dindi_palkhi_voice_screen.dart';
import '../features/dindi/abhangavali_screen.dart';
import '../features/dindi/abhang_detail_screen.dart';
import '../features/dindi/varkari_health_shield_screen.dart';
import '../features/cleanwari/cleanwari_qr_scanner_screen.dart';
import '../features/cleanwari/cleanwari_report_screen.dart';
import '../features/cleanwari/cleanwari_report_status_screen.dart';
import '../features/cleanwari/cleanwari_cleaner_screen.dart';
import '../features/cleanwari/cleanwari_task_detail_screen.dart';
import '../features/placeholders/profile_placeholder.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen(), settings: settings);

      case AppRoutes.shell:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['tabIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => WariAppShell(initialTabIndex: initialTab),
          settings: settings,
        );

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen(), settings: settings);

      case AppRoutes.map:
        return MaterialPageRoute(builder: (_) => const MapScreen(), settings: settings);

      case AppRoutes.alerts:
      case AppRoutes.sosStatus:
        return MaterialPageRoute(builder: (_) => const SosScreen(), settings: settings);

      case AppRoutes.services:
        return MaterialPageRoute(builder: (_) => const ServicesScreen(), settings: settings);

      case AppRoutes.lostFound:
        return MaterialPageRoute(builder: (_) => const LostFoundScreen(), settings: settings);

      case AppRoutes.community:
        return MaterialPageRoute(builder: (_) => const CommunityScreen(), settings: settings);

      case AppRoutes.dindi:
        return MaterialPageRoute(builder: (_) => const DindiOverviewScreen(), settings: settings);

      case AppRoutes.dindiSchedule:
        final dindiId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => DindiScheduleScreen(dindiId: dindiId),
          settings: settings,
        );

      case AppRoutes.dindiJoin:
        return MaterialPageRoute(builder: (_) => const DindiQrScannerScreen(), settings: settings);

      case AppRoutes.dindiPass:
        return MaterialPageRoute(builder: (_) => const DigitalDindiPassScreen(), settings: settings);

      case AppRoutes.dindiLiveRoute:
        final dindiId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => DindiLiveRouteScreen(dindiId: dindiId),
          settings: settings,
        );

      case AppRoutes.dindiCommunity:
        final dindiId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => DindiCommunityScreen(dindiId: dindiId),
          settings: settings,
        );

      case AppRoutes.dindiPalkhiVoice:
        final dindiId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => DindiPalkhiVoiceScreen(dindiId: dindiId),
          settings: settings,
        );

      case AppRoutes.abhangavali:
        return MaterialPageRoute(builder: (_) => const AbhangavaliScreen(), settings: settings);

      case AppRoutes.abhangDetail:
        final abhang = settings.arguments as Abhang;
        return MaterialPageRoute(
          builder: (_) => AbhangDetailScreen(abhang: abhang),
          settings: settings,
        );

      case AppRoutes.varkariHealthShield:
        return MaterialPageRoute(builder: (_) => const VarkariHealthShieldScreen(), settings: settings);

      case AppRoutes.cleanWariScanner:
        return MaterialPageRoute(builder: (_) => const CleanWariQrScannerScreen(), settings: settings);

      case AppRoutes.cleanWariReport:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CleanWariReportScreen(
            toiletId: args['toiletId'] as String,
            toiletQrCode: args['toiletQrCode'] as String,
            toiletName: args['toiletName'] as String,
          ),
          settings: settings,
        );

      case AppRoutes.cleanWariReportStatus:
        final report = settings.arguments as CleanlinessReport;
        return MaterialPageRoute(
          builder: (_) => CleanWariReportStatusScreen(report: report),
          settings: settings,
        );

      case AppRoutes.cleanWariCleaner:
        return MaterialPageRoute(builder: (_) => const CleanWariCleanerScreen(), settings: settings);

      case AppRoutes.cleanWariTask:
        final report = settings.arguments as CleanlinessReport;
        return MaterialPageRoute(
          builder: (_) => CleanWariTaskDetailScreen(report: report),
          settings: settings,
        );

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePlaceholder(), settings: settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('WariVerse AI')),
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
