import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/sos_provider.dart';
import '../../providers/user_provider.dart';
import 'widgets/sos_idle_view.dart';
import 'widgets/sos_confirm_sheet.dart';
import 'widgets/active_sos_card.dart';
import 'widgets/offline_relay_card.dart';
import 'widgets/sos_incident_list_view.dart';

/// SOS & Emergency Services screen for WariVerse AI.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SosScreenContent();
  }
}

class _SosScreenContent extends StatelessWidget {
  const _SosScreenContent();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final sosProvider = Provider.of<SosProvider>(context);
    final activeRole = userProvider.currentRole;
    final isOperational = activeRole != UserRole.VARKARI;

    if (isOperational) {
      return DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: WariColors.background,
            appBar: const TabBar(
              indicatorColor: WariColors.danger,
              labelColor: WariColors.danger,
              unselectedLabelColor: WariColors.slate600,
              tabs: [
                Tab(icon: Icon(Icons.emergency), text: 'Trigger SOS'),
                Tab(icon: Icon(Icons.list_alt), text: 'Incident Feed'),
              ],
            ),
            body: TabBarView(
              children: [
                _buildSosMainFlow(sosProvider),
                const SosIncidentListView(),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: WariColors.background,
      body: _buildSosMainFlow(sosProvider),
    );
  }

  Widget _buildSosMainFlow(SosProvider sosProvider) {
    switch (sosProvider.uiState) {
      case SosUiState.idle:
      case SosUiState.cancelled:
      case SosUiState.failed:
        return const SosIdleView();
      case SosUiState.confirming:
        return Stack(
          children: [
            const SosIdleView(),
            Container(
              color: Colors.black45,
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: SosConfirmSheet(),
                ),
              ),
            ),
          ],
        );
      case SosUiState.gettingLocation:
        return const Scaffold(
          backgroundColor: WariColors.background,
          body: WariLoadingIndicator(message: 'Acquiring current GPS location accuracy...'),
        );
      case SosUiState.submitting:
        return const Scaffold(
          backgroundColor: WariColors.background,
          body: WariLoadingIndicator(message: 'Dispatching Emergency SOS & Finding Responder...'),
        );
      case SosUiState.active:
      case SosUiState.updatingLocation:
      case SosUiState.resolved:
        if (sosProvider.activeIncident != null) {
          return ActiveSosCard(incident: sosProvider.activeIncident!);
        }
        return const SosIdleView();
      case SosUiState.offlineQueued:
        return const OfflineRelayCard();
    }
  }
}
