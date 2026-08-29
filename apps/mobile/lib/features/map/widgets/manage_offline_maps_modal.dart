import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/offline_map_provider.dart';
import '../../../repositories/repositories_exports.dart';
import '../../../services/api_service.dart';

/// Modal bottom sheet allowing users to view, refresh, delete, and re-download saved offline maps.
class ManageOfflineMapsModal extends StatelessWidget {
  const ManageOfflineMapsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineProvider = Provider.of<OfflineMapProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final serviceRepo = ServiceRepository(apiService);
    final crowdRepo = CrowdRepository(apiService);
    final sosRepo = SosRepository(apiService);

    final snapshots = offlineProvider.savedSnapshots;

    return Container(
      padding: EdgeInsets.only(
        top: WariSpacing.lg,
        left: WariSpacing.lg,
        right: WariSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + WariSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WariColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: WariSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_zip_rounded, color: WariColors.primary, size: 28),
                  SizedBox(width: WariSpacing.sm),
                  Text(
                    'Manage Offline Maps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: WariColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          const Text(
            'Saved Wari map snapshots available for offline viewing without active internet connectivity.',
            style: TextStyle(
              fontSize: 13,
              color: WariColors.textSecondary,
            ),
          ),
          const SizedBox(height: WariSpacing.md),

          if (snapshots.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(WariSpacing.xl),
              decoration: BoxDecoration(
                color: WariColors.background,
                borderRadius: BorderRadius.circular(WariSpacing.md),
                border: Border.all(color: WariColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_download_outlined, size: 48, color: WariColors.slate400),
                  SizedBox(height: WariSpacing.sm),
                  Text(
                    'No Offline Maps Downloaded Yet',
                    style: TextStyle(fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                  ),
                  SizedBox(height: WariSpacing.xs),
                  Text(
                    'Tap "Download Offline Map" on the Live Map screen to save Wari routes and service locations for offline use.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: WariColors.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: snapshots.length,
                separatorBuilder: (_, index) => const SizedBox(height: WariSpacing.sm),
                itemBuilder: (context, index) {
                  final snapshot = snapshots[index];
                  final isActive = offlineProvider.activeSnapshot?.snapshotId == snapshot.snapshotId;

                  return Container(
                    padding: const EdgeInsets.all(WariSpacing.md),
                    decoration: BoxDecoration(
                      color: isActive ? WariColors.primary.withValues(alpha: 0.05) : WariColors.background,
                      borderRadius: BorderRadius.circular(WariSpacing.md),
                      border: Border.all(
                        color: isActive ? WariColors.primary : WariColors.border,
                        width: isActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                snapshot.routeName,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive)
                              const WariStatusChip(label: 'ACTIVE', color: WariColors.success),
                          ],
                        ),
                        const SizedBox(height: WariSpacing.xs),
                        Text(
                          'Downloaded: ${snapshot.formattedDownloadedAt} (${snapshot.relativeAgeString})',
                          style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                        ),
                        const SizedBox(height: WariSpacing.xs),
                        Row(
                          children: [
                            WariStatusChip(label: '${snapshot.totalElementCount} elements', color: WariColors.info),
                            const SizedBox(width: WariSpacing.xs),
                            WariStatusChip(label: '~${snapshot.estimatedSizeMb.toStringAsFixed(1)} MB', color: WariColors.accent),
                          ],
                        ),
                        const SizedBox(height: WariSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await offlineProvider.downloadOfflineSnapshot(
                                  serviceRepo: serviceRepo,
                                  crowdRepo: crowdRepo,
                                  sosRepo: sosRepo,
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Update / Refresh', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: WariSpacing.xs),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: WariColors.danger, size: 20),
                              onPressed: () async {
                                await offlineProvider.deleteSnapshot(snapshot.snapshotId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
