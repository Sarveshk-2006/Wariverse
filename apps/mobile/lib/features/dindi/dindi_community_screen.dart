import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../models/models_exports.dart';
import '../../navigation/app_routes.dart';
import '../../providers/dindi_provider.dart';
import '../../providers/dindi_community_provider.dart';
import '../../providers/user_provider.dart';
import '../../repositories/dindi_community_repository.dart';
import '../../services/api_service.dart';
import 'widgets/create_dindi_post_dialog.dart';

/// Private Dindi Community and Broadcast Hub screen.
class DindiCommunityScreen extends StatelessWidget {
  const DindiCommunityScreen({super.key, this.dindiId});

  final String? dindiId;

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider<DindiCommunityProvider>(
      create: (_) => DindiCommunityProvider(
        repository: DindiCommunityRepository(apiService),
      ),
      child: _DindiCommunityContent(overrideDindiId: dindiId),
    );
  }
}

class _DindiCommunityContent extends StatefulWidget {
  const _DindiCommunityContent({this.overrideDindiId});

  final String? overrideDindiId;

  @override
  State<_DindiCommunityContent> createState() => _DindiCommunityContentState();
}

class _DindiCommunityContentState extends State<_DindiCommunityContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCommunity();
    });
  }

  void _loadCommunity() {
    final dindiProvider = Provider.of<DindiProvider>(context, listen: false);
    final communityProvider = Provider.of<DindiCommunityProvider>(context, listen: false);

    final targetId = widget.overrideDindiId ?? dindiProvider.currentDindi?.id ?? 'dindi-001';
    communityProvider.loadCommunity(targetId);
  }

  @override
  Widget build(BuildContext context) {
    final dindiProvider = Provider.of<DindiProvider>(context);
    final communityProvider = Provider.of<DindiCommunityProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    final currentDindi = dindiProvider.currentDindi;
    final hasJoined = dindiProvider.hasJoinedDindi;

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: Text(currentDindi != null ? '${currentDindi.name} Feed' : 'Dindi Community (खाजगी चर्चा)'),
      ),
      body: Column(
        children: [
          if (dindiProvider.isFromMock)
            const OfflineBanner(message: 'Demo Mode — Private Dindi-scoped community feed'),

          Expanded(
            child: !hasJoined && widget.overrideDindiId == null
                ? _buildNonMemberGate(context)
                : _buildCommunityBody(context, provider: communityProvider, dindi: currentDindi, user: user),
          ),
        ],
      ),
      floatingActionButton: (hasJoined && user != null)
          ? FloatingActionButton.extended(
              heroTag: 'create_dindi_post_fab',
              backgroundColor: WariColors.primary,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Text('Post Update (पोस्ट)', style: WariTypography.labelSmall.copyWith(color: Colors.white)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dlgContext) => CreateDindiPostDialog(
                    userRole: user.userRole,
                    onSubmit: (content, type) {
                      if (currentDindi != null) {
                        communityProvider.createPost(
                          dindiId: currentDindi.id,
                          content: content,
                          type: type,
                          author: user,
                        );
                      }
                    },
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildNonMemberGate(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: WariCard(
          borderColor: WariColors.warning,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: WariColors.warningLight,
                child: Icon(Icons.lock_outline, color: WariColors.primaryDark, size: 32),
              ),
              const SizedBox(height: WariSpacing.base),
              Text(
                'Private Dindi Community',
                style: WariTypography.headlineSmall,
              ),
              const SizedBox(height: WariSpacing.xs),
              Text(
                'Join an official Wari Dindi to access its private communication feed and leader broadcasts.',
                style: WariTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.base),
              WariPrimaryButton(
                label: 'Join a Dindi (दिंडीत सामील व्हा)',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.dindiJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityBody(
    BuildContext context, {
    required DindiCommunityProvider provider,
    required Dindi? dindi,
    required AppUser? user,
  }) {
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
        message: provider.errorMessage ?? 'Unable to load Dindi community.',
        onRetry: () => _loadCommunity(),
      );
    }

    final broadcasts = provider.broadcasts;
    final posts = provider.posts;

    return RefreshIndicator(
      onRefresh: () async => _loadCommunity(),
      color: WariColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Broadcast Card
            if (broadcasts.isNotEmpty) ...[
              ...broadcasts.map((bc) => _buildBroadcastCard(bc)),
              const SizedBox(height: WariSpacing.base),
            ],

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Updates'),
                    selected: provider.selectedFilter == null,
                    onSelected: (_) => provider.filterByCategory(null),
                  ),
                  const SizedBox(width: WariSpacing.xs),
                  ...DindiPostType.values.map((type) {
                    final isSelected = provider.selectedFilter == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: WariSpacing.xs),
                      child: FilterChip(
                        label: Text(type.displayName.split(' ').first),
                        selected: isSelected,
                        onSelected: (_) => provider.filterByCategory(isSelected ? null : type),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.base),

            const SectionHeader(
              title: 'Community Updates (खाजगी चर्चा)',
              subtitle: 'Operational feed isolated for your Dindi members',
            ),
            const SizedBox(height: WariSpacing.sm),

            if (posts.isEmpty)
              const WariEmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No Updates Yet',
                subtitle: 'Important announcements and posts from your Dindi will appear here.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: WariSpacing.sm),
                    child: _buildPostCard(post),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastCard(DindiBroadcast bc) {
    return WariCard(
      borderColor: WariColors.primary,
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: WariColors.primaryDark, size: 22),
                  const SizedBox(width: WariSpacing.xs),
                  Text('📢 DINDI BROADCAST', style: WariTypography.titleMedium.copyWith(color: WariColors.primaryDark)),
                ],
              ),
              const WariStatusChip(
                label: 'OFFICIAL',
                color: WariColors.primary,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.xs),
          Text(
            bc.title,
            style: WariTypography.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            bc.message,
            style: WariTypography.bodyMedium,
          ),
          const SizedBox(height: WariSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By: ${bc.sender} (${bc.senderRole})',
                style: WariTypography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Active Notice',
                style: WariTypography.caption.copyWith(color: WariColors.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(DindiCommunityPost post) {
    return WariCard(
      borderColor: post.isSafetyAlert ? WariColors.danger : WariColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: post.isSafetyAlert ? WariColors.dangerLight : WariColors.primaryLight,
                    child: Icon(
                      post.isSafetyAlert ? Icons.warning : Icons.person,
                      size: 16,
                      color: post.isSafetyAlert ? WariColors.danger : WariColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: WariSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: WariTypography.titleSmall),
                          if (post.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: WariColors.primary),
                          ],
                        ],
                      ),
                      Text(post.authorRole, style: WariTypography.caption),
                    ],
                  ),
                ],
              ),
              WariStatusChip(
                label: post.postType.name,
                color: post.isSafetyAlert ? WariColors.danger : WariColors.info,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),
          Text(
            post.content,
            style: WariTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
