import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models_exports.dart';
import '../../providers/user_provider.dart';
import '../home/home_screen.dart';
import 'dindi_leader_dashboard.dart';
import 'volunteer_dashboard.dart';
import 'police_dashboard.dart';
import 'medical_dashboard.dart';
import 'ngo_dashboard.dart';
import 'admin_dashboard.dart';

/// Centralized role-based operational dashboard renderer.
class RoleDashboardView extends StatelessWidget {
  const RoleDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final activeRole = userProvider.currentRole;

    switch (activeRole) {
      case UserRole.VARKARI:
        return const HomeScreen();
      case UserRole.DINDI_LEADER:
        return const DindiLeaderDashboard();
      case UserRole.VOLUNTEER:
        return const VolunteerDashboard();
      case UserRole.POLICE:
        return const PoliceDashboard();
      case UserRole.MEDICAL_TEAM:
        return const MedicalDashboard();
      case UserRole.NGO:
      case UserRole.SERVICE_PROVIDER:
      case UserRole.CLEANER:
        return const NgoDashboard();
      case UserRole.ADMIN:
        return const AdminDashboard();
    }
  }
}

