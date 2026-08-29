import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Primary saffron-filled action button.
class WariPrimaryButton extends StatelessWidget {
  const WariPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: WariColors.textOnPrimary,
            ),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: dense ? 16 : 18),
                  const SizedBox(width: WariSpacing.xs),
                  Text(
                    label,
                    style: dense
                        ? WariTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                        : null,
                  ),
                ],
              )
            : Text(
                label,
                style: dense
                    ? WariTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
                    : null,
              ));

    final buttonStyle = backgroundColor != null
        ? ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.white,
            padding: dense ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6) : null,
          )
        : (dense
            ? ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              )
            : null);

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: child,
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Outlined saffron-bordered secondary button.
class WariSecondaryButton extends StatelessWidget {
  const WariSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Widget child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: WariSpacing.sm),
              Text(label),
            ],
          )
        : Text(label);

    final button = OutlinedButton(onPressed: onPressed, child: child);

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Icon-only circular action button (e.g., map controls, quick actions).
class WariIconButton extends StatelessWidget {
  const WariIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 40.0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final body = Material(
      color: backgroundColor ?? WariColors.surface,
      borderRadius: BorderRadius.circular(size / 2),
      elevation: WariSpacing.elevationSm,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: 20,
            color: color ?? WariColors.textSecondary,
          ),
        ),
      ),
    );

    return body;
  }
}

/// Prominent SOS emergency button — large red button for emergency access.
class SosButton extends StatelessWidget {
  const SosButton({
    super.key,
    required this.onPressed,
    this.label = 'SOS',
    this.size = 90.0,
  });

  final VoidCallback onPressed;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: WariColors.danger,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: WariColors.danger.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: size * 0.32),
            const SizedBox(height: 2),
            Text(
              label,
              style: WariTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
