import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Centered loading spinner with optional label.
class WariLoadingIndicator extends StatelessWidget {
  const WariLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: WariColors.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: WariSpacing.base),
            Text(message!, style: WariTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay.
class WariLoadingScreen extends StatelessWidget {
  const WariLoadingScreen({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WariColors.background,
      body: WariLoadingIndicator(message: message),
    );
  }
}

/// Shimmer-style placeholder card for skeleton loading.
class WariSkeletonCard extends StatefulWidget {
  const WariSkeletonCard({
    super.key,
    this.height = 80,
    this.width = double.infinity,
    this.radius,
  });

  final double height;
  final double width;
  final double? radius;

  @override
  State<WariSkeletonCard> createState() => _WariSkeletonCardState();
}

class _WariSkeletonCardState extends State<WariSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: WariColors.slate200.withValues(alpha: _animation.value),
          borderRadius: BorderRadius.circular(
            widget.radius ?? WariSpacing.radiusMd,
          ),
        ),
      ),
    );
  }
}

/// Empty state placeholder with icon, title, and optional action.
class WariEmptyState extends StatelessWidget {
  const WariEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: WariColors.slate100,
                borderRadius: BorderRadius.circular(WariSpacing.radiusXl),
              ),
              child: Icon(icon, size: 32, color: WariColors.slate400),
            ),
            const SizedBox(height: WariSpacing.base),
            Text(
              title,
              style: WariTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: WariSpacing.sm),
              Text(
                subtitle!,
                style: WariTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: WariSpacing.base),
              WariSecondaryButtonInline(
                label: actionLabel!,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state placeholder with retry option.
class WariErrorState extends StatelessWidget {
  const WariErrorState({
    super.key,
    this.message = 'Something went wrong.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WariSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: WariColors.danger),
            const SizedBox(height: WariSpacing.base),
            Text(
              message,
              style: WariTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: WariSpacing.base),
              WariSecondaryButtonInline(
                label: 'Retry',
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline secondary button (used inside states).
class WariSecondaryButtonInline extends StatelessWidget {
  const WariSecondaryButtonInline({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 40),
        side: const BorderSide(color: WariColors.primary),
        foregroundColor: WariColors.primary,
      ),
      child: Text(label),
    );
  }
}

/// Offline/demo mode banner shown at the top of screens when using mock data.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.message = 'Demo Mode — Using Offline Data'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WariColors.warningLight,
      padding: const EdgeInsets.symmetric(
        horizontal: WariSpacing.base,
        vertical: WariSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 14, color: WariColors.warning),
          const SizedBox(width: WariSpacing.sm),
          Text(
            message,
            style: WariTypography.labelSmall.copyWith(
              color: WariColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}


