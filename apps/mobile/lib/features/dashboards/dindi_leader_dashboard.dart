import 'package:flutter/material.dart';
import '../../core/theme/wari_theme_exports.dart';
import '../../core/widgets/wari_widgets_exports.dart';

/// Dindi Leader / Pramukh Operational Management Dashboard.
class DindiLeaderDashboard extends StatefulWidget {
  const DindiLeaderDashboard({super.key});

  @override
  State<DindiLeaderDashboard> createState() => _DindiLeaderDashboardState();
}

class _DindiLeaderDashboardState extends State<DindiLeaderDashboard> {
  bool _isBeaconActive = true;
  final int _totalMembers = 142;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(WariSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(WariSpacing.base),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [WariColors.primaryDark, WariColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(WariSpacing.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dindi No. 12 — Sant Tukaram Maharaj',
                          style: WariTypography.titleMedium.copyWith(color: Colors.white),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isBeaconActive ? WariColors.success : WariColors.slate500,
                            borderRadius: BorderRadius.circular(WariSpacing.radiusFull),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isBeaconActive ? Icons.sensors : Icons.sensors_off,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isBeaconActive ? 'BEACON ACTIVE' : 'OFFLINE',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WariSpacing.sm),
                    Text(
                      'Pramukh Operational Command',
                      style: WariTypography.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WariSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: WariCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registered Members', style: WariTypography.caption),
                          const SizedBox(height: 4),
                          Text('$_totalMembers Varkaris', style: WariTypography.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: WariSpacing.sm),
                  Expanded(
                    child: WariCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next Scheduled Halt', style: WariTypography.caption),
                          const SizedBox(height: 4),
                          Text('Akurdi (13:30)', style: WariTypography.headlineSmall.copyWith(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WariSpacing.base),
              const SectionHeader(title: 'Leader Operational Controls'),
              SwitchListTile(
                title: Text('Palkhi Live Location Beacon', style: WariTypography.titleMedium),
                subtitle: const Text('Broadcasts real-time GPS location of Dindi No. 12 to members'),
                value: _isBeaconActive,
                activeThumbColor: WariColors.primary,
                onChanged: (val) {

                  setState(() {
                    _isBeaconActive = val;
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.qr_code_2, color: WariColors.primary),
                title: Text('Generate Digital Dindi Join Pass', style: WariTypography.titleMedium),
                subtitle: const Text('Display QR code for new Varkaris to join Dindi No. 12'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.record_voice_over, color: WariColors.primary),
                title: Text('Palkhi Voice Audio Broadcast', style: WariTypography.titleMedium),
                subtitle: const Text('Start live audio announcements for Dindi pilgrims'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.announcement, color: WariColors.primary),
                title: Text('Post Dindi Announcement', style: WariTypography.titleMedium),
                subtitle: const Text('Send verified schedule update to members'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
