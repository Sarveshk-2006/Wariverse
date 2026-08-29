import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';

/// Role-Aware Registration & Onboarding screen for WariVerse AI.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _dindiCodeController = TextEditingController();
  String _selectedRole = 'VARKARI';
  String _selectedBloodGroup = 'O+';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _dindiCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (['ADMIN', 'POLICE', 'MEDICAL_TEAM', 'CLEANER'].contains(_selectedRole)) {
      setState(() {
        _errorMessage = 'Privileged operational roles ($_selectedRole) require Admin invitation and cannot be self-registered.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final displayName = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final ageText = _ageController.text.trim();
      final age = int.tryParse(ageText);
      final dindiCode = _dindiCodeController.text.trim();

      final success = await userProvider.register(
        email: email,
        password: password,
        displayName: displayName,
        role: _selectedRole,
        phone: phone,
        age: age,
        bloodGroup: _selectedBloodGroup,
        dindiCode: dindiCode,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
      } else if (mounted) {
        setState(() {
          _errorMessage = userProvider.errorMessage ?? 'Registration failed. Please check details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WariSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join the Wari Operations Platform',
                  style: WariTypography.headlineSmall.copyWith(color: WariColors.primaryDark),
                ),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  'Register as a Varkari Pilgrim, Dindi Leader, or Field Volunteer. Operational roles require Admin approval.',
                  style: WariTypography.bodySmall,
                ),
                const SizedBox(height: WariSpacing.lg),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(WariSpacing.sm),
                    decoration: BoxDecoration(
                      color: WariColors.dangerLight,
                      borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: WariColors.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: WariSpacing.md),
                ],

                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Registration Role',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VARKARI', child: Text('Varkari Pilgrim')),
                    DropdownMenuItem(value: 'VOLUNTEER', child: Text('Volunteer Field Responder')),
                    DropdownMenuItem(value: 'DINDI_LEADER', child: Text('Dindi Leader')),
                    DropdownMenuItem(value: 'MEDICAL_TEAM', child: Text('Medical Team (Requires Approval)')),
                    DropdownMenuItem(value: 'POLICE', child: Text('Police Command (Requires Approval)')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Requires Approval)')),
                    DropdownMenuItem(value: 'CLEANER', child: Text('CleanWari Staff (Requires Approval)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: WariSpacing.md),

                if (_selectedRole == 'DINDI_LEADER') ...[
                  TextFormField(
                    controller: _dindiCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Dindi Code / ID (e.g. DND-001)',
                      prefixIcon: Icon(Icons.groups),
                    ),
                    validator: (v) => _selectedRole == 'DINDI_LEADER' && (v == null || v.isEmpty)
                        ? 'Please enter Dindi Code/ID'
                        : null,
                  ),
                  const SizedBox(height: WariSpacing.md),
                ],

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter full name' : null,
                ),
                const SizedBox(height: WariSpacing.md),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Phone Number (+91)', prefixIcon: Icon(Icons.phone)),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter mobile number' : null,
                ),
                const SizedBox(height: WariSpacing.md),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                  validator: (v) => v == null || !v.contains('@') ? 'Please enter valid email' : null,
                ),
                const SizedBox(height: WariSpacing.md),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: WariSpacing.md),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                      ),
                    ),
                    const SizedBox(width: WariSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBloodGroup,
                        decoration: const InputDecoration(labelText: 'Blood Group'),
                        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                            .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedBloodGroup = val ?? 'O+'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WariSpacing.xl),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WariColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(_isLoading ? 'Creating Account...' : 'Register Account'),
                ),
                const SizedBox(height: WariSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
