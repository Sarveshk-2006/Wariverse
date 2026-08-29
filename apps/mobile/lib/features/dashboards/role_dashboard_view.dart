import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';
import 'dindi_leader_dashboard.dart';
import 'volunteer_dashboard.dart';
import 'ngo_dashboard.dart';
import 'admin_dashboard.dart';

import '../cleanwari/cleanwari_cleaner_screen.dart';

/// Centralized role-based operational dashboard renderer.
class RoleDashboardView extends StatelessWidget {
  const RoleDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final activeRole = userProvider.currentRole;

    switch (activeRole) {
      case UserRole.VARKARI:
        if (userProvider.isVolunteerEnabled) {
          return const VolunteerDashboard();
        }
        return const HomeScreen();
      case UserRole.DINDI_LEADER:
        return const DindiLeaderDashboard();
      case UserRole.VOLUNTEER:
        return const VolunteerDashboard();
      case UserRole.POLICE:
      case UserRole.MEDICAL_TEAM:
      case UserRole.ADMIN:
        return const AdminDashboard();
      case UserRole.NGO:
      case UserRole.SERVICE_PROVIDER:
        return const NgoDashboard();
      case UserRole.CLEANER:
        return const CleanWariCleanerScreen();
    }
  }
}

