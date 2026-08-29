import 'package:flutter/material.dart';
import '../theme/wari_theme_exports.dart';

/// Shows a styled WariVerse bottom sheet.
Future<T?> showWariBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isDismissible = true,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (_) => _WariBottomSheetContainer(child: child),
  );
}

class _WariBottomSheetContainer extends StatelessWidget {
  const _WariBottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: WariColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(WariSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: WariSpacing.md),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: WariColors.slate300,
              borderRadius: BorderRadius.circular(WariSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: WariSpacing.base),
          child,
        ],
      ),
    );
  }
}

/// Reusable detail row for bottom sheets (label + value).
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WariSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: WariColors.textMuted),
            const SizedBox(width: WariSpacing.sm),
          ],
          SizedBox(
            width: 110,
            child: Text(label, style: WariTypography.titleSmall),
          ),
          Expanded(
            child: Text(
              value,
              style: WariTypography.bodyMedium.copyWith(
                color: valueColor ?? WariColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
