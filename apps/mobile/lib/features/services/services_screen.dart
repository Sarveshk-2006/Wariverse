import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/services_provider.dart';
import '../../repositories/service_repository.dart';
import '../../services/api_service.dart';
import 'widgets/service_category_chips.dart';
import 'widgets/service_card.dart';
import 'widgets/service_detail_bottom_sheet.dart';

/// Main Pilgrim Services & Utilities Hub screen for WariVerse AI.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<ServicesProvider>(
      create: (_) => ServicesProvider(
        serviceRepo: ServiceRepository(apiService),
      ),
      child: const _ServicesScreenContent(),
    );
  }
}

class _ServicesScreenContent extends StatefulWidget {
  const _ServicesScreenContent();

  @override
  State<_ServicesScreenContent> createState() => _ServicesScreenContentState();
}

class _ServicesScreenContentState extends State<_ServicesScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ServicesProvider>(context, listen: false).loadServices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServicesProvider>(context);

    return Scaffold(
      backgroundColor: WariColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Search & Filter Controls Header
              Container(
                color: WariColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: WariSpacing.base,
                  vertical: WariSpacing.xs,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search food, water, medical, toilets, shelters...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: WariColors.slate100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => provider.setSearchQuery(val),
                    ),
                    const SizedBox(height: WariSpacing.xs),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Switch.adaptive(
                              value: provider.openOnly,
                              activeTrackColor: WariColors.success,
                              onChanged: (val) => provider.setOpenOnly(val),
                            ),
                            Text(
                              'Open Only',
                              style: WariTypography.labelSmall.copyWith(
                                color: provider.openOnly ? WariColors.success : WariColors.textSecondary,
                                fontWeight: provider.openOnly ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: provider.sortBy,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.sort, size: 18),
                          items: const [
                            DropdownMenuItem(value: 'distance', child: Text('Sort by Distance', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'queue', child: Text('Sort by Queue Time', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'rating', child: Text('Sort by Rating', style: TextStyle(fontSize: 11))),
                          ],
                          onChanged: (val) {
                            if (val != null) provider.setSortBy(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: WariSpacing.xs),
              const ServiceCategoryChips(),
              const SizedBox(height: WariSpacing.xs),

              if (provider.isFromMock)
                const OfflineBanner(message: 'Demo Mode — Showing nearest Pandharpur service facilities'),

              // Content Body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  color: WariColors.primary,
                  child: _buildServiceList(provider),
                ),
              ),
            ],
          ),

          // Service Detail Bottom Sheet Overlay
          if (provider.selectedService != null)
            Positioned(
              left: WariSpacing.base,
              right: WariSpacing.base,
              bottom: WariSpacing.base,
              child: SafeArea(
                child: ServiceDetailBottomSheet(
                  item: provider.selectedService!,
                  onClose: () => provider.selectService(null),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceList(ServicesProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(WariSpacing.base),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariSkeletonCard(height: 110),
        ),
      );
    }

    if (provider.hasError) {
      return WariErrorState(
        message: 'Unable to load services. Please pull down to retry.',
        onRetry: () => provider.loadServices(),
      );
    }

    final services = provider.filteredServices;

    if (services.isEmpty) {
      return WariEmptyState(
        icon: Icons.search_off,
        title: 'No Matching Services Found',
        subtitle: 'Try clearing your search query or switching categories.',
        actionLabel: 'Reset Search & Filters',
        onAction: () {
          _searchController.clear();
          provider.setSearchQuery('');
          provider.setOpenOnly(false);
          provider.setActiveCategory('all');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WariSpacing.base),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
          child: ServiceCard(
            item: item,
            onTap: () => provider.selectService(item),
          ),
        );
      },
    );
  }
}
