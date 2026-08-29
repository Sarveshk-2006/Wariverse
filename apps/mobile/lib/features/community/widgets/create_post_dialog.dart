import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/community_provider.dart';
import '../../../providers/user_provider.dart';

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  PostType _selectedType = PostType.GENERAL;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CommunityProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Container(
      padding: EdgeInsets.only(
        left: WariSpacing.base,
        right: WariSpacing.base,
        top: WariSpacing.base,
        bottom: MediaQuery.of(context).viewInsets.bottom + WariSpacing.base,
      ),
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(WariSpacing.radiusLg)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Share Community Update', style: WariTypography.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.sm),

              DropdownButtonFormField<PostType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Update Category *',
                  isDense: true,
                ),
                items: PostType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: WariSpacing.sm),

              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Update Message *',
                  hintText: 'Share useful info for fellow pilgrims (e.g. Fresh tea serving at Wakhari, path clear...)',
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: WariSpacing.base),

              if (provider.hasError) ...[
                Text(
                  provider.errorMessage!,
                  style: WariTypography.caption.copyWith(color: WariColors.danger),
                ),
                const SizedBox(height: WariSpacing.xs),
              ],

              WariPrimaryButton(
                label: 'Publish Update',
                isLoading: provider.isSubmitting,
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final navigator = Navigator.of(context);
                    final user = userProvider.currentUser;
                    final role = userProvider.currentRole;
                    final isOfficialRole = role == UserRole.VOLUNTEER || role == UserRole.POLICE || role == UserRole.ADMIN;

                    final success = await provider.createPost(
                      authorId: user?.userId ?? 'demo-user',
                      authorName: user?.displayName ?? 'Wari Pilgrim',
                      postType: _selectedType,
                      message: _messageController.text.trim(),
                      isVerified: isOfficialRole,
                    );
                    if (success && mounted) {
                      navigator.pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
