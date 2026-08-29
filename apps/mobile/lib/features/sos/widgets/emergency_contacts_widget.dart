import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/emergency_contact.dart';
import '../../../providers/sos_provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';

import 'package:url_launcher/url_launcher.dart';

/// Interactive Emergency Contacts Management & Automated SMS Dispatch Widget.
/// Extracted & ported from WoShield2 EmergencyContactActivity.
class EmergencyContactsWidget extends StatefulWidget {
  const EmergencyContactsWidget({super.key});

  @override
  State<EmergencyContactsWidget> createState() => _EmergencyContactsWidgetState();
}

class _EmergencyContactsWidgetState extends State<EmergencyContactsWidget> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final String _relationship = 'Family';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);
    final contacts = sosProvider.emergencyContacts;

    return WariCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.contact_phone_rounded, color: WariColors.primary, size: 20),
                  SizedBox(width: WariSpacing.xs),
                  Text('Emergency Contacts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: WariColors.primary),
                onPressed: () => _showAddContactDialog(context, sosProvider),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Emergency SMS alerts with live location will be sent to these contacts.',
            style: TextStyle(fontSize: 11, color: WariColors.textSecondary),
          ),
          const SizedBox(height: WariSpacing.sm),

          if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No emergency contacts added yet. Tap + to add.', style: TextStyle(fontSize: 11, color: WariColors.textMuted)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              itemBuilder: (ctx, i) {
                final c = contacts[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: WariColors.background,
                      borderRadius: BorderRadius.circular(WariSpacing.sm),
                      border: Border.all(color: WariColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('${c.phoneNumber} • ${c.relationship}', style: const TextStyle(fontSize: 11, color: WariColors.textSecondary)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.sms_rounded, color: WariColors.primary, size: 18),
                              tooltip: 'Send Test SMS to ${c.name}',
                              onPressed: () async {
                                final cleanPhone = c.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
                                final msg = 'TEST EMERGENCY ALERT!\nI am testing WariVerse WoShield emergency SOS alert to my contact ${c.name}.';
                                final uri = Uri(
                                  scheme: 'sms',
                                  path: cleanPhone,
                                  queryParameters: <String, String>{'body': msg},
                                );
                                try {
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not open Messages app: $e')),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: WariColors.danger, size: 18),
                              onPressed: () => sosProvider.deleteEmergencyContact(c.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, SosProvider provider) {
    _nameController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Contact Name', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (10 digits)', prefixIcon: Icon(Icons.phone)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final phone = _phoneController.text.trim();
                if (name.isNotEmpty && phone.isNotEmpty) {
                  provider.addEmergencyContact(
                    EmergencyContact(
                      id: 'cnt_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      phoneNumber: phone,
                      relationship: _relationship,
                      createdAt: DateTime.now().toIso8601String(),
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Contact'),
            ),
          ],
        );
      },
    );
  }
}
