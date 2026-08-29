import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../providers/lost_found_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/lost_found_repository.dart';
import '../../services/api_service.dart';
import 'widgets/lost_person_card.dart';
import 'widgets/report_lost_person_dialog.dart';

class LostFoundScreen extends StatelessWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<LostFoundProvider>(
      create: (_) => LostFoundProvider(
        repository: LostFoundRepository(apiService),
      ),
      child: const _LostFoundScreenContent(),
    );
  }
}

class _LostFoundScreenContent extends StatefulWidget {
  const _LostFoundScreenContent();

  @override
  State<_LostFoundScreenContent> createState() => _LostFoundScreenContentState();
}

class _LostFoundScreenContentState extends State<_LostFoundScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LostFoundProvider>(context, listen: false).loadLostPersons();
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
    final provider = Provider.of<LostFoundProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.currentRole;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Lost & Found Recovery'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const ReportLostPersonDialog(),
            ),
          );
        },
        backgroundColor: WariColors.accent,
        icon: const Icon(Icons.person_add),
        label: const Text('Report Missing'),
      ),
      body: Column(
        children: [
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
                    hintText: 'Search missing person by name, age, contact...',
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
                  children: [
                    _buildFilterChip('ALL', 'All Cases', provider),
                    const SizedBox(width: WariSpacing.xs),
                    _buildFilterChip('MISSING', 'Missing Only', provider),
                    const SizedBox(width: WariSpacing.xs),
                    _buildFilterChip('FOUND', 'Found / Reunited', provider),
                  ],
                ),
              ],
            ),
          ),

          if (provider.isFromMock)
            const OfflineBanner(message: 'Demo Mode — Showing local Pandharpur missing person cases'),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadLostPersons(),
              color: WariColors.primary,
              child: _buildList(provider, role),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, LostFoundProvider provider) {
    final isSel = provider.activeFilter == key;
    return ChoiceChip(
      selected: isSel,
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      selectedColor: WariColors.primaryLight,
      onSelected: (_) => provider.setActiveFilter(key),
    );
  }

  Widget _buildList(LostFoundProvider provider, UserRole role) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(WariSpacing.base),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariSkeletonCard(height: 120),
        ),
      );
    }

    if (provider.hasError) {
      return WariErrorState(
        message: 'Unable to load lost person records. Pull down to retry.',
        onRetry: () => provider.loadLostPersons(),
      );
    }

    final persons = provider.filteredPersons;

    if (persons.isEmpty) {
      return WariEmptyState(
        icon: Icons.person_search,
        title: 'No Missing Person Cases Found',
        subtitle: 'Try clearing your search term or filter parameters.',
        actionLabel: 'Reset Search',
        onAction: () {
          _searchController.clear();
          provider.setSearchQuery('');
          provider.setActiveFilter('ALL');
        },
      );
    }

    final canMarkFound = role == UserRole.VOLUNTEER || role == UserRole.POLICE || role == UserRole.ADMIN;

    return ListView.builder(
      padding: const EdgeInsets.all(WariSpacing.base),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final person = persons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
          child: LostPersonCard(
            person: person,
            onMarkFound: canMarkFound && person.isMissing
                ? () => provider.markAsFound(person.id)
                : null,
          ),
        );
      },
    );
  }
}
