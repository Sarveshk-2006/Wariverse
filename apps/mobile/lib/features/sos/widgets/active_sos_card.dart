import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/sos_provider.dart';

/// Card showing active emergency status, incident reference, responder info, and cancel/resolve options.
class ActiveSosCard extends StatelessWidget {
  const ActiveSosCard({super.key, required this.incident});

  final SOSIncident incident;

  @override
  Widget build(BuildContext context) {
    final sosProvider = Provider.of<SosProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WariSpacing.base),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(WariSpacing.base),
            decoration: BoxDecoration(
              color: WariColors.successLight,
              borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
              border: Border.all(color: WariColors.success, width: 2),
            ),
            child: Column(
              children: [
                const Text('✅', style: TextStyle(fontSize: 48)),
                const SizedBox(height: WariSpacing.xs),
                Text(
                  'SOS SENT & ACTIVE!',
                  style: WariTypography.headlineSmall.copyWith(color: WariColors.successDark),
                ),
                Text(
                  'Emergency responders have been alerted and dispatched to your location.',
                  style: WariTypography.bodySmall.copyWith(color: WariColors.successDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WariSpacing.base),

                Container(
                  padding: const EdgeInsets.all(WariSpacing.base),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(WariSpacing.radiusMd),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('INCIDENT REF', style: WariTypography.caption),
                              Text(incident.id, style: WariTypography.titleSmall),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('STATUS', style: WariTypography.caption),
                              WariStatusChip(
                                label: incident.status.displayName,
                                color: WariColors.success,
                                dense: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: WariSpacing.base),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NEAREST RESPONDER', style: WariTypography.caption),
                              Text(
                                incident.responderName ?? 'Dispatched Team',
                                style: WariTypography.titleSmall,
                              ),
                            ],
                          ),
                          if (incident.responderDistanceM != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('DISTANCE', style: WariTypography.caption),
                                Text(
                                  '${incident.responderDistanceM}m',
                                  style: WariTypography.titleSmall.copyWith(color: WariColors.primary),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Divider(height: WariSpacing.base),

                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: WariColors.danger),
                          const SizedBox(width: WariSpacing.xs),
                          Expanded(
                            child: Text(
                              'Location: https://www.google.com/maps?q=${incident.latitude.toStringAsFixed(5)},${incident.longitude.toStringAsFixed(5)}',
                              style: WariTypography.caption.copyWith(color: WariColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: WariSpacing.base),

                      Row(
                        children: [
                          const Icon(Icons.mark_email_read_outlined, size: 18, color: WariColors.primary),
                          const SizedBox(width: WariSpacing.xs),
                          Expanded(
                            child: Text(
                              'Emergency Contacts Alerted: Up to 5 contacts targeted (SMS Gateway: NOT_CONFIGURED)',
                              style: WariTypography.caption.copyWith(color: WariColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: WariSpacing.base),

          WariCard(
            child: Column(
              children: [
                Text(
                  'Your location is being continuously shared with nearby responders.',
                  style: WariTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WariSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: WariSecondaryButton(
                        label: 'Cancel SOS',
                        onPressed: () => sosProvider.cancelActiveSOS(),
                      ),
                    ),
                    const SizedBox(width: WariSpacing.sm),
                    Expanded(
                      child: WariPrimaryButton(
                        label: 'Resolve SOS',
                        backgroundColor: WariColors.success,
                        onPressed: () => sosProvider.resolveActiveSOS(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
