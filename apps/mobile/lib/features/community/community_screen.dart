import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/community_provider.dart';
import '../../repositories/community_repository.dart';
import '../../services/api_service.dart';
import 'widgets/community_post_card.dart';
import 'widgets/create_post_dialog.dart';

/// Main Pilgrim Community Feed screen for WariVerse AI.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<CommunityProvider>(
      create: (_) => CommunityProvider(
        repository: CommunityRepository(apiService),
      )..loadPosts(),
      child: const _CommunityScreenContent(),
    );
  }
}

class _CommunityScreenContent extends StatelessWidget {
  const _CommunityScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CommunityProvider>(context);

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: const Text('Wari Pilgrim Community Feed'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const CreatePostDialog(),
            ),
          );
        },
        backgroundColor: WariColors.primary,
        icon: const Icon(Icons.edit_note),
        label: const Text('Post Update'),
      ),
      body: Column(
        children: [
          // Category Filters
          Container(
            color: WariColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: WariSpacing.base,
              vertical: WariSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Updates', provider),
                  const SizedBox(width: WariSpacing.xs),
                  _buildFilterChip('VERIFIED', 'Verified Only', provider),
                  const SizedBox(width: WariSpacing.xs),
                  _buildFilterChip('ALERTS', 'Route & Safety Warnings', provider),
                  const SizedBox(width: WariSpacing.xs),
                  _buildFilterChip('SERVICES', 'Food, Water & Shelter', provider),
                ],
              ),
            ),
          ),

          if (provider.isFromMock)
            const OfflineBanner(message: 'Demo Mode — Showing live community updates along Wari route'),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadPosts(),
              color: WariColors.primary,
              child: _buildFeed(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, CommunityProvider provider) {
    final isSel = provider.activeCategory == key;
    return ChoiceChip(
      selected: isSel,
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      selectedColor: WariColors.primaryLight,
      onSelected: (_) => provider.setActiveCategory(key),
    );
  }

  Widget _buildFeed(CommunityProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(WariSpacing.base),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: WariSpacing.sm),
          child: WariSkeletonCard(height: 100),
        ),
      );
    }

    if (provider.hasError) {
      return WariErrorState(
        message: 'Unable to load community feed. Pull down to refresh.',
        onRetry: () => provider.loadPosts(),
      );
    }

    final posts = provider.filteredPosts;

    if (posts.isEmpty) {
      return WariEmptyState(
        icon: Icons.campaign_outlined,
        title: 'No Updates in Selected Category',
        subtitle: 'Be the first to share an update with fellow pilgrims!',
        actionLabel: 'Reset Category Filter',
        onAction: () => provider.setActiveCategory('ALL'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WariSpacing.base),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WariSpacing.sm),
          child: CommunityPostCard(
            post: post,
            onUpvote: () => provider.upvotePost(post.id),
          ),
        );
      },
    );
  }
}
