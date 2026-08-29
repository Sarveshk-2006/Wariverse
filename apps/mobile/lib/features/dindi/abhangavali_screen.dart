import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/abhang_provider.dart';
import '../../repositories/abhang_repository.dart';

/// Offline Marathi/English devotional Abhangavali hymnbook screen.
class AbhangavaliScreen extends StatelessWidget {
  const AbhangavaliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AbhangProvider>(
      create: (_) => AbhangProvider(
        repository: AbhangRepository(),
      )..loadAbhangs(),
      child: const _AbhangavaliContent(),
    );
  }
}

class _AbhangavaliContent extends StatelessWidget {
  const _AbhangavaliContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AbhangProvider>(context);

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Digital Abhangavali (अभंगगाथा)'),
      ),
      body: Column(
        children: [
          // Prominent Offline Availability Banner
          const OfflineBanner(message: 'OFFLINE • AVAILABLE WITHOUT INTERNET'),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WariSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Marathi or English abhang...',
                      prefixIcon: const Icon(Icons.search, color: WariColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                      ),
                    ),
                    onChanged: (val) => provider.search(val),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Vitthal', 'Tukaram', 'Dnyaneshwar', 'Prayer'].map((cat) {
                        final isSelected = provider.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: WariSpacing.xs),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => provider.setCategory(cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: WariSpacing.base),

                  const SectionHeader(
                    title: 'Devotional Abhangs (पवित्र अभंग)',
                    subtitle: 'Classic Marathi hymns with English meaning',
                  ),
                  const SizedBox(height: WariSpacing.sm),

                  if (provider.abhangs.isEmpty)
                    const WariEmptyState(
                      icon: Icons.menu_book,
                      title: 'No Abhangs Found',
                      subtitle: 'Try searching another title or select "All" categories.',
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.abhangs.length,
                      itemBuilder: (context, index) {
                        final abhang = provider.abhangs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
                          child: WariCard(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.abhangDetail,
                              arguments: abhang,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(WariSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: WariColors.primaryLight,
                                    borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                                  ),
                                  child: const Text('♪', style: TextStyle(fontSize: 20, color: WariColors.primaryDark)),
                                ),
                                const SizedBox(width: WariSpacing.xs),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        abhang.titleMarathi,
                                        style: WariTypography.titleMedium.copyWith(color: WariColors.primaryDark),
                                      ),
                                      Text(
                                        '${abhang.titleEnglish} · ${abhang.author}',
                                        style: WariTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: WariColors.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
