import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';
import '../../providers/user_provider.dart';
import '../../navigation/app_routes.dart';

/// Multi-Portal Apple-Style Auth Login Screen for WariVerse AI.
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

  final List<({String role, String label, String description, IconData icon, Color color})> _portals = [
    (role: 'VARKARI', label: 'VARKARI', description: 'Pilgrim & Safety Services', icon: Icons.directions_walk_rounded, color: WariColors.primary),
    (role: 'DINDI_LEADER', label: 'DINDI LEADER', description: 'Manage your Dindi', icon: Icons.groups_rounded, color: WariColors.primaryDark),
    (role: 'VOLUNTEER', label: 'VOLUNTEER', description: 'Respond to incidents', icon: Icons.support_agent_rounded, color: WariColors.warning),
    (role: 'NGO', label: 'NGO', description: 'Manage aid distribution', icon: Icons.volunteer_activism_rounded, color: WariColors.success),
    (role: 'SANITATION', label: 'SANITATION', description: 'Field sanitation operations', icon: Icons.cleaning_services_rounded, color: WariColors.info),
    (role: 'ADMIN', label: 'ADMIN', description: 'Command & Monitoring', icon: Icons.admin_panel_settings_rounded, color: WariColors.danger),
  ];

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
          padding: const EdgeInsets.all(WariSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: WariSpacing.base),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: WariColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/wariverse_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: WariSpacing.xs),
              Text(
                'WariVerse AI',
                style: WariTypography.headlineLarge.copyWith(color: WariColors.primaryDark, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              Text(
                'Safer Wari. Smarter Coordination.',
                style: WariTypography.bodySmall.copyWith(color: WariColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WariSpacing.base),

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
                      const Icon(Icons.error_outline_rounded, color: WariColors.danger, size: 20),
                      const SizedBox(width: WariSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: WariTypography.bodySmall.copyWith(color: WariColors.dangerDark, fontWeight: FontWeight.w600),
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
                      const Icon(Icons.check_circle_outline_rounded, color: WariColors.success, size: 20),
                      const SizedBox(width: WariSpacing.sm),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: WariTypography.bodySmall.copyWith(color: WariColors.successDark, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Portal Selection Grid
              Text('Portal Access', style: WariTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: WariSpacing.xs),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _portals.length,
                itemBuilder: (ctx, i) {
                  final p = _portals[i];
                  final isSelected = _selectedPortalRole == p.role;
                  return InkWell(
                    onTap: () => setState(() => _selectedPortalRole = p.role),
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? p.color.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected ? p.color : WariColors.border,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(p.icon, color: isSelected ? p.color : WariColors.slate600, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: isSelected ? p.color : WariColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  p.description,
                                  style: const TextStyle(fontSize: 9, color: WariColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: WariSpacing.base),

              // Login Form Card
              WariCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedPortalRole == 'ADMIN') ...[
                      Container(
                        padding: const EdgeInsets.all(WariSpacing.xs),
                        decoration: BoxDecoration(
                          color: WariColors.slate100,
                          borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
                          border: Border.all(color: WariColors.slate300),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.admin_panel_settings_rounded, color: WariColors.primary, size: 16),
                            SizedBox(width: WariSpacing.xs),
                            Expanded(
                              child: Text(
                                'Admin Command Center is restricted to Firebase Admin accounts. Registration is disabled.',
                                style: TextStyle(fontSize: 10, color: WariColors.slate700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WariSpacing.xs),
                    ],

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: WariSpacing.xs),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                      ),
                    ),

                    const SizedBox(height: WariSpacing.xs),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Sign In to ${_selectedPortalRole.replaceAll("_", " ")}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(fontSize: 12)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
                          child: const Text('Register Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
