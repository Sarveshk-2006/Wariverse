import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/offline_map_provider.dart';
import '../../../services/offline_map_search_service.dart';

/// Interactive Offline Search Bottom Sheet allowing pilgrims to search downloaded services offline.
class OfflineSearchSheet extends StatefulWidget {
  const OfflineSearchSheet({super.key});

  @override
  State<OfflineSearchSheet> createState() => _OfflineSearchSheetState();
}

class _OfflineSearchSheetState extends State<OfflineSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<OfflineSearchResult> _searchResults = [];
  String _selectedCategoryFilter = 'ALL';

  final List<Map<String, String>> _categories = [
    {'key': 'ALL', 'label': 'All Services'},
    {'key': 'water', 'label': '💧 Water'},
    {'key': 'medical', 'label': '🏥 Medical'},
    {'key': 'toilet', 'label': '🧼 Toilets'},
    {'key': 'food', 'label': '🍛 Food'},
    {'key': 'shelter', 'label': '🛖 Shelters'},
    {'key': 'wellness', 'label': '💆 Wellness'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(OfflineMapProvider offlineProvider, MapProvider mapProvider, String query) {
    final userPos = mapProvider.userLocation;
    final results = offlineProvider.searchOffline(
      query.isEmpty ? _selectedCategoryFilter : query,
      userLat: userPos.latitude,
      userLon: userPos.longitude,
    );

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final offlineProvider = Provider.of<OfflineMapProvider>(context);
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final snapshot = offlineProvider.activeSnapshot;

    return Container(
      padding: EdgeInsets.only(
        top: WariSpacing.md,
        left: WariSpacing.md,
        right: WariSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + WariSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.lg)),
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
          const SizedBox(height: WariSpacing.sm),

          // Offline Banner Header
          Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: WariColors.warning, size: 22),
              const SizedBox(width: WariSpacing.xs),
              Expanded(
                child: Text(
                  'Offline Search · Map Saved (${snapshot?.relativeAgeString ?? 'recently'})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: WariColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (q) => _performSearch(offlineProvider, mapProvider, q),
            decoration: InputDecoration(
              hintText: 'Search "water", "medical", "toilet", "food", "shelter"...',
              prefixIcon: const Icon(Icons.search_rounded, color: WariColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch(offlineProvider, mapProvider, '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: WariColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: WariSpacing.md, vertical: WariSpacing.sm),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(WariSpacing.md),
                borderSide: const BorderSide(color: WariColors.border),
              ),
            ),
          ),
          const SizedBox(height: WariSpacing.sm),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategoryFilter == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: WariSpacing.xs),
                  child: FilterChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryFilter = cat['key']!;
                      });
                      _performSearch(offlineProvider, mapProvider, _searchController.text);
                    },
                    selectedColor: WariColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? WariColors.primary : WariColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: WariSpacing.sm),

          // Search Results
          if (_searchResults.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(WariSpacing.lg),
              child: Text(
                _searchController.text.isEmpty
                    ? 'Type a service name above or tap a category filter.'
                    : 'No offline service matching "${_searchController.text}" found in downloaded package.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: WariColors.textSecondary, fontSize: 13),
              ),
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, index) => const Divider(height: 1, color: WariColors.border),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: WariSpacing.xs, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: WariColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        item.category.substring(0, 1),
                        style: const TextStyle(color: WariColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${item.subtitle} • ${item.statusInfo}',
                      style: const TextStyle(fontSize: 12, color: WariColors.textSecondary),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.distanceKm != null)
                          Text(
                            '${item.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.primary, fontSize: 13),
                          ),
                        Text(
                          'Snapshot ${item.snapshotTimestamp}',
                          style: const TextStyle(fontSize: 10, color: WariColors.textSecondary),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
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
