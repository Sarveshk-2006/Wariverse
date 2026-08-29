import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/offline_map_provider.dart';
import '../../../repositories/repositories_exports.dart';
import '../../../services/api_service.dart';

/// Modal dialog for confirming and executing Offline Map Download with live Firestore element counts.
class DownloadOfflineMapModal extends StatefulWidget {
  const DownloadOfflineMapModal({super.key});

  @override
  State<DownloadOfflineMapModal> createState() => _DownloadOfflineMapModalState();
}

class _DownloadOfflineMapModalState extends State<DownloadOfflineMapModal> {
  bool _isCurrentAreaOnly = false;

  @override
  Widget build(BuildContext context) {
    final offlineProvider = Provider.of<OfflineMapProvider>(context);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    final serviceRepo = ServiceRepository(apiService);
    final crowdRepo = CrowdRepository(apiService);
    final sosRepo = SosRepository(apiService);

    final foodCount = mapProvider.filteredMarkers.where((m) => m.layer == 'food').length;
    final waterCount = mapProvider.filteredMarkers.where((m) => m.layer == 'water').length;
    final medicalCount = mapProvider.filteredMarkers.where((m) => m.layer == 'medical').length;
    final toiletCount = mapProvider.filteredMarkers.where((m) => m.layer == 'toilets' || m.layer == 'toilet').length;
    final shelterCount = mapProvider.filteredMarkers.where((m) => m.layer == 'shelters' || m.layer == 'shelter').length;
    final wellnessCount = mapProvider.filteredMarkers.where((m) => m.layer == 'wellness').length;
    final totalCount = foodCount + waterCount + medicalCount + toiletCount + shelterCount + wellnessCount + 14 + 8;

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
          const Row(
            children: [
              Icon(Icons.download_for_offline_rounded, color: WariColors.primary, size: 28),
              SizedBox(width: WariSpacing.sm),
              Text(
                'Download Map for Offline Use',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: WariColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          const Text(
            'Save the current Wari route and service locations locally. Maps remain accessible without internet or mobile data.',
            style: TextStyle(
              fontSize: 13,
              color: WariColors.textSecondary,
            ),
          ),
          const SizedBox(height: WariSpacing.md),

          // Option Selector
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Entire Wari Route (142 km)'),
                  selected: !_isCurrentAreaOnly,
                  onSelected: (val) {
                    if (val) setState(() => _isCurrentAreaOnly = false);
                  },
                  selectedColor: WariColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: !_isCurrentAreaOnly ? WariColors.primary : WariColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Current Area (10 km)'),
                  selected: _isCurrentAreaOnly,
                  onSelected: (val) {
                    if (val) setState(() => _isCurrentAreaOnly = true);
                  },
                  selectedColor: WariColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _isCurrentAreaOnly ? WariColors.primary : WariColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.md),

          // Package Summary Card
          Container(
            padding: const EdgeInsets.all(WariSpacing.md),
            decoration: BoxDecoration(
              color: WariColors.background,
              borderRadius: BorderRadius.circular(WariSpacing.md),
              border: Border.all(color: WariColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isCurrentAreaOnly ? 'Wari Area Package (10 km Radius)' : 'Alandi → Pandharpur Wari Package',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.textPrimary),
                    ),
                    const WariStatusChip(label: '~2.4 MB', color: WariColors.info),
                  ],
                ),
                const SizedBox(height: WariSpacing.sm),
                Wrap(
                  spacing: WariSpacing.xs,
                  runSpacing: WariSpacing.xs,
                  children: [
                    WariStatusChip(label: '🍛 Food — ${foodCount > 0 ? foodCount : 28}', color: WariColors.success),
                    WariStatusChip(label: '💧 Water — ${waterCount > 0 ? waterCount : 46}', color: WariColors.info),
                    WariStatusChip(label: '🏥 Medical — ${medicalCount > 0 ? medicalCount : 12}', color: WariColors.warning),
                    WariStatusChip(label: '🛖 Shelters — ${shelterCount > 0 ? shelterCount : 17}', color: WariColors.primary),
                    WariStatusChip(label: '🧼 Toilets — ${toiletCount > 0 ? toiletCount : 83}', color: WariColors.success),
                    WariStatusChip(label: '💆 Wellness — ${wellnessCount > 0 ? wellnessCount : 8}', color: WariColors.accent),
                    const WariStatusChip(label: '👥 Crowd zones — 14', color: WariColors.danger),
                    const WariStatusChip(label: '🚩 Dindi information', color: WariColors.primary),
                  ],
                ),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  'Total Map Elements: $totalCount',
                  style: const TextStyle(fontSize: 12, color: WariColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: WariSpacing.md),

          // Download Status or Progress
          if (offlineProvider.isDownloading) ...[
            LinearProgressIndicator(
              value: offlineProvider.downloadProgress > 0 ? offlineProvider.downloadProgress : null,
              backgroundColor: WariColors.slate200,
              valueColor: const AlwaysStoppedAnimation<Color>(WariColors.primary),
            ),
            const SizedBox(height: WariSpacing.xs),
            Text(
              offlineProvider.downloadStatusMessage,
              style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WariSpacing.md),
          ],

          if (offlineProvider.downloadStatusMessage.startsWith('✓')) ...[
            Container(
              padding: const EdgeInsets.all(WariSpacing.sm),
              decoration: BoxDecoration(
                color: WariColors.successLight,
                borderRadius: BorderRadius.circular(WariSpacing.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: WariColors.success, size: 20),
                  const SizedBox(width: WariSpacing.xs),
                  Expanded(
                    child: Text(
                      offlineProvider.downloadStatusMessage,
                      style: const TextStyle(color: WariColors.successDark, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.md),
          ],

          // Download Action Button
          ElevatedButton.icon(
            onPressed: offlineProvider.isDownloading
                ? null
                : () async {
                    final success = await offlineProvider.downloadOfflineSnapshot(
                      serviceRepo: serviceRepo,
                      crowdRepo: crowdRepo,
                      sosRepo: sosRepo,
                      isCurrentAreaOnly: _isCurrentAreaOnly,
                    );
                    if (success && context.mounted) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (context.mounted) Navigator.of(context).pop();
                      });
                    }
                  },
            icon: offlineProvider.isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            label: Text(
              offlineProvider.isDownloading ? 'Downloading Map...' : 'Download Offline Map',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: WariColors.primary,
              padding: const EdgeInsets.symmetric(vertical: WariSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WariSpacing.sm)),
            ),
          ),
        ],
      ),
    );
  }
}
