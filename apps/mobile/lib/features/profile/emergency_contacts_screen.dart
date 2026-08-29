import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/emergency_contact_provider.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyContactProvider>(context);

    return Scaffold(
      backgroundColor: WariColors.background,
      appBar: AppBar(
        title: Text('Emergency Contacts', style: WariTypography.titleLarge),
        backgroundColor: WariColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WariSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent banner
            Container(
              padding: const EdgeInsets.all(WariSpacing.md),
              decoration: BoxDecoration(
                color: WariColors.warningLight,
                borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                border: Border.all(color: WariColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: WariColors.warningDark, size: 28),
                  const SizedBox(width: WariSpacing.sm),
                  Expanded(
                    child: Text(
                      'These contacts (up to 5) will be alerted during an emergency alert with your live GPS location.',
                      style: WariTypography.bodyMedium.copyWith(color: WariColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('YOUR CONTACTS (${provider.contacts.length}/5)', style: WariTypography.labelLarge),
                if (provider.canAddMore)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary),
                    onPressed: () => _showAddContactDialog(context, provider),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Contact'),
                  ),
              ],
            ),
            const SizedBox(height: WariSpacing.md),

            if (provider.isLoading)
              const WariLoadingIndicator(message: 'Loading contacts...')
            else if (provider.contacts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(WariSpacing.xl),
                decoration: BoxDecoration(
                  color: WariColors.surface,
                  borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.contact_phone_outlined, size: 48, color: WariColors.slate400),
                    const SizedBox(height: WariSpacing.sm),
                    Text('No emergency contacts added yet', style: WariTypography.titleMedium),
                    const SizedBox(height: WariSpacing.xs),
                    Text('Add family members or close friends who can assist in emergency.', style: WariTypography.bodySmall),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.contacts.length,
                separatorBuilder: (ctx, index) => const SizedBox(height: WariSpacing.sm),
                itemBuilder: (context, index) {
                  final contact = provider.contacts[index];
                  return Container(
                    padding: const EdgeInsets.all(WariSpacing.md),
                    decoration: BoxDecoration(
                      color: WariColors.surface,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                      border: Border.all(color: WariColors.slate200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: WariColors.warningLight,
                          child: Text('${contact.priority}', style: WariTypography.titleMedium.copyWith(color: WariColors.primary)),
                        ),
                        const SizedBox(width: WariSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.name, style: WariTypography.titleMedium),
                              Text('${contact.relationship} • ${contact.phoneNumber}', style: WariTypography.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: WariColors.danger),
                          onPressed: () => provider.deleteContact(contact.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, EmergencyContactProvider provider) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final int selectedPriority = provider.contacts.length + 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: WariSpacing.base,
          right: WariSpacing.base,
          top: WariSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ADD EMERGENCY CONTACT', style: WariTypography.titleLarge),
            const SizedBox(height: WariSpacing.md),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: WariSpacing.sm),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number (+91)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: WariSpacing.sm),
            TextField(
              controller: relCtrl,
              decoration: const InputDecoration(labelText: 'Relationship (Son, Daughter, Friend, Spouse)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: WariSpacing.base),
            WariPrimaryButton(
              label: 'SAVE CONTACT',
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  final ok = await provider.addContact(
                    name: nameCtrl.text,
                    phoneNumber: phoneCtrl.text,
                    relationship: relCtrl.text.isEmpty ? 'Family' : relCtrl.text,
                    priority: selectedPriority,
                  );
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: WariSpacing.base),
          ],
        ),
      ),
    );
  }
}
