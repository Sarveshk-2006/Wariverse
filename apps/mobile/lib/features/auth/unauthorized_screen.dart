import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';

/// Screen displayed when a user attempts to access a forbidden route or role-restricted feature.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key, this.requestedRoute});

  final String? requestedRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Padding(
        padding: const EdgeInsets.all(WariSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: WariColors.danger),
            const SizedBox(height: WariSpacing.base),
            Text(
              'Unauthorized Action',
              style: WariTypography.headlineMedium.copyWith(color: WariColors.dangerDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: WariSpacing.sm),
            Text(
              'Your current role does not have authorization to access ${requestedRoute ?? 'this resource'}. This action has been logged for security.',
              style: WariTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WariSpacing.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Return to Home Dashboard'),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
