import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';

/// Multi-Role Auth Login Screen for WariVerse AI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedPortalRole = 'VARKARI';
  String? _errorMessage;
  String? _successMessage;

  final Map<String, String> _portalLabels = {
    'VARKARI': 'Varkari Pilgrim Portal',
    'DINDI_LEADER': 'Dindi Leader Operations',
    'VOLUNTEER': 'Volunteer Field Response',
    'MEDICAL_TEAM': 'Medical Emergency Shield',
    'POLICE': 'Police Security Command',
    'ADMIN': 'Executive Command Center',
    'CLEANER': 'CleanWari Sanitation Operations',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter both email and password.';
          _isLoading = false;
        });
        return;
      }

      final success = await userProvider.login(
        email,
        password,
        requestedPortalRole: _selectedPortalRole,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
      } else if (mounted) {
        setState(() {
          _errorMessage = userProvider.errorMessage ?? 'Authentication failed. Please check credentials.';
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

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your registered email address to receive a password reset link:'),
            const SizedBox(height: WariSpacing.sm),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid email address.')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final sent = await userProvider.sendPasswordResetEmail(email);
              if (mounted) {
                if (sent) {
                  setState(() {
                    _successMessage = 'Password reset link sent to $email. Please check your inbox.';
                  });
                } else {
                  setState(() {
                    _errorMessage = userProvider.errorMessage ?? 'Failed to send password reset email.';
                  });
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WariColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WariSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: WariSpacing.lg),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: WariColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, size: 48, color: WariColors.primary),
                ),
              ),
              const SizedBox(height: WariSpacing.base),
              Text(
                'WariVerse AI',
                style: WariTypography.headlineLarge.copyWith(color: WariColors.primaryDark),
                textAlign: TextAlign.center,
              ),
              Text(
                'Multi-Portal Pilgrimage Operations System',
                style: WariTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.xl),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: WariSpacing.base),
                  padding: const EdgeInsets.all(WariSpacing.base),
                  decoration: BoxDecoration(
                    color: WariColors.dangerLight,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: WariColors.danger, size: 20),
                      const SizedBox(width: WariSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: WariTypography.bodySmall.copyWith(color: WariColors.dangerDark),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: WariSpacing.base),
                  padding: const EdgeInsets.all(WariSpacing.base),
                  decoration: BoxDecoration(
                    color: WariColors.successLight,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: WariColors.success, size: 20),
                      const SizedBox(width: WariSpacing.sm),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: WariTypography.bodySmall.copyWith(color: WariColors.successDark),
                        ),
                      ),
                    ],
                  ),
                ),

              WariCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Portal Access',
                      style: WariTypography.titleMedium,
                    ),
                    const SizedBox(height: WariSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPortalRole,
                      decoration: const InputDecoration(
                        labelText: 'Select Portal to Access',
                        prefixIcon: Icon(Icons.business_center),
                      ),
                      items: _portalLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPortalRole = val);
                      },
                    ),
                    const SizedBox(height: WariSpacing.base),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: WariSpacing.base),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: WariSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: WariSpacing.md),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Sign In to ${_portalLabels[_selectedPortalRole]?.split(" ").first ?? "Portal"}'),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
                          child: const Text('Register Account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
