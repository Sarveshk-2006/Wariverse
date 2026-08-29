import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../providers/lost_found_provider.dart';
import '../../../providers/user_provider.dart';

class ReportLostPersonDialog extends StatefulWidget {
  const ReportLostPersonDialog({super.key});

  @override
  State<ReportLostPersonDialog> createState() => _ReportLostPersonDialogState();
}

class _ReportLostPersonDialogState extends State<ReportLostPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodController = TextEditingController();

  String _gender = 'Male';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _bloodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LostFoundProvider>(context);
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
                  Text('Report Missing Person', style: WariTypography.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.sm),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter name of missing person',
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: WariSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        hintText: 'e.g. 45',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: WariSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _gender = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.sm),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Identifying Details & Last Seen Location',
                  hintText: 'Wearing saffron kurta near Wakhari Pandal...',
                  isDense: true,
                ),
              ),
              const SizedBox(height: WariSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        hintText: '+91 9876543210',
                        isDense: true,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Contact required' : null,
                    ),
                  ),
                  const SizedBox(width: WariSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _bloodController,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        hintText: 'O+',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
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
                label: 'Submit Missing Person Report',
                isLoading: provider.isSubmitting,
                backgroundColor: WariColors.accent,
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final navigator = Navigator.of(context);
                    final success = await provider.reportLostPerson(
                      name: _nameController.text.trim(),
                      age: int.tryParse(_ageController.text.trim()),
                      gender: _gender,
                      description: _descController.text.trim(),
                      emergencyContact: _phoneController.text.trim(),
                      bloodGroup: _bloodController.text.trim().isNotEmpty
                          ? _bloodController.text.trim()
                          : null,
                      reportedBy: userProvider.currentUser?.userId ?? 'demo-user',
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
