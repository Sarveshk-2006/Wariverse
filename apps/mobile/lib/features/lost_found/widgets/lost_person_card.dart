import 'package:flutter/material.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';

class LostPersonCard extends StatelessWidget {
  const LostPersonCard({
    super.key,
    required this.person,
    this.onMarkFound,
  });

  final LostPerson person;
  final VoidCallback? onMarkFound;

  @override
  Widget build(BuildContext context) {
    final isMissing = person.isMissing;
    final statusColor = isMissing ? WariColors.danger : WariColors.success;

    return WariCard(
      borderColor: statusColor.withValues(alpha: 0.3),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.person, color: statusColor, size: 26),
              ),
              const SizedBox(width: WariSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            person.name,
                            style: WariTypography.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        WariStatusChip(
                          label: person.status.toUpperCase(),
                          color: statusColor,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${person.gender ?? "Age unknown"} · ${person.age != null ? "${person.age} yrs" : "Age not specified"}',
                      style: WariTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          if (person.description != null && person.description!.isNotEmpty) ...[
            Text(person.description!, style: WariTypography.bodySmall.copyWith(color: WariColors.slate800)),
            const SizedBox(height: WariSpacing.xs),
          ],

          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: WariColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Reported ${WariFormatters.timeAgo(person.createdAt.toIso8601String())}',
                style: WariTypography.caption,
              ),
              if (person.bloodGroup != null) ...[
                const SizedBox(width: WariSpacing.sm),
                WariStatusChip(
                  label: 'Blood: ${person.bloodGroup}',
                  color: WariColors.danger,
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: WariSpacing.sm),

          if (person.emergencyContact != null) ...[
            Container(
              padding: const EdgeInsets.all(WariSpacing.xs),
              decoration: BoxDecoration(
                color: WariColors.slate100,
                borderRadius: BorderRadius.circular(WariSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: WariColors.primary),
                  const SizedBox(width: WariSpacing.xs),
                  Text('Contact: ${person.emergencyContact}', style: WariTypography.labelSmall),
                ],
              ),
            ),
            const SizedBox(height: WariSpacing.xs),
          ],

          if (isMissing && onMarkFound != null)
            Align(
              alignment: Alignment.centerRight,
              child: WariSecondaryButtonInline(
                label: 'Mark as Found',
                onPressed: onMarkFound!,
              ),
            ),
        ],
      ),
    );
  }
}
