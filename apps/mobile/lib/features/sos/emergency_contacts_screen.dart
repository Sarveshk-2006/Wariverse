import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../repositories/sos_repository.dart';
import '../../services/api_service.dart';

import '../../providers/user_provider.dart';

/// Screen for managing up to 5 emergency contacts.
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late SosRepository _repo;
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relationship = 'Family';
  int _priority = 1;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiService>(context, listen: false);
    _repo = SosRepository(api);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.currentUser?.userId;
    final data = await _repo.getEmergencyContacts(userId: userId);
    if (!mounted) return;
    setState(() {
      _contacts = data;
      _isLoading = false;
      _priority = (_contacts.length + 1).clamp(1, 5);
    });
  }

  Future<void> _addContact() async {
    if (_contacts.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 emergency contacts allowed (Priority 1-5)')),
        );
      }
      return;
    }

    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter contact name and phone number')),
        );
      }
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId;

      await _repo.addEmergencyContact(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        priority: _priority,
        relationshipName: _relationship,
        userId: userId,
      );
      _nameController.clear();
      _phoneController.clear();
      if (mounted) {
        Navigator.pop(context);
        _loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contact: $e')),
        );
      }
    }
  }

  Future<void> _deleteContact(String id) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId;

      await _repo.deleteEmergencyContact(id, userId: userId);
      if (mounted) {
        _loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  void _showAddDialog() {
    if (_contacts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 emergency contacts allowed (Priority 1-5)')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WariColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Emergency Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WariColors.slate900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Contact Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number (+91)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _relationship,
                    decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                    items: ['Family', 'Friend', 'Doctor', 'Other']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => _relationship = val ?? 'Family'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority (1-5)', border: OutlineInputBorder()),
                    items: [1, 2, 3, 4, 5]
                        .map((p) => DropdownMenuItem(value: p, child: Text('Priority $p')))
                        .toList(),
                    onChanged: (val) => setState(() => _priority = val ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addContact,
              style: ElevatedButton.styleFrom(backgroundColor: WariColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save Emergency Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts (Max 5)'),
        backgroundColor: WariColors.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.contacts, size: 64, color: WariColors.slate400),
                      const SizedBox(height: 16),
                      const Text('No emergency contacts added yet.', style: TextStyle(color: WariColors.slate600)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (ctx, idx) {
                    final item = _contacts[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: WariColors.primary.withValues(alpha: 0.1),
                          child: Text('${item['priority'] ?? idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: WariColors.primary)),
                        ),
                        title: Text(item['name'] ?? 'Contact', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item['phone_number']} • ${item['relationship_name'] ?? 'Family'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: WariColors.danger),
                          onPressed: () => _deleteContact(item['id']),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _contacts.length < 5
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              backgroundColor: WariColors.primary,
            )
          : null,
    );
  }
}
