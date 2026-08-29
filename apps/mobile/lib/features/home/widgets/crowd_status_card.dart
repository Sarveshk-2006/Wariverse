import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/wari_theme_exports.dart';
import '../../../core/utils/wari_formatters.dart';
import '../../../core/widgets/wari_widgets_exports.dart';
import '../../../models/models_exports.dart';
import '../../../providers/home_provider.dart';
import '../../../navigation/app_routes.dart';

/// Crowd status banner widget matching web dashboard crowd monitoring section.
class CrowdStatusCard extends StatelessWidget {
  const CrowdStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final crowdLevel = homeProvider.highestCrowdLevel;
    final totalPilgrims = homeProvider.totalPilgrimsEstimate;

    final accentColor = _getCrowdColor(crowdLevel);
    final label = _getCrowdLabel(crowdLevel);
    final emoji = _getCrowdEmoji(crowdLevel);

    return WariAccentCard(
      accentColor: accentColor,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.crowdDetail,
        arguments: 'Vitthal Mandir Ghat Zone',
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: WariTypography.headlineSmall.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: WariSpacing.xs),
                    CrowdLevelChip(level: _mapCrowdSeverity(crowdLevel), dense: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '~${WariFormatters.formatCount(totalPilgrims > 0 ? totalPilgrims : 1450000)} pilgrims on route right now',
                  style: WariTypography.bodySmall,
                ),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  static Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.GREEN:  return WariColors.crowdGreen;
      case CrowdLevel.YELLOW: return WariColors.crowdYellow;
      case CrowdLevel.ORANGE: return WariColors.crowdOrange;
      case CrowdLevel.RED:    return WariColors.crowdRed;
    }
  }

  static String _getCrowdLabel(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.GREEN:  return 'Normal Pilgrim Flow';
      case CrowdLevel.YELLOW: return 'Moderate Density';
      case CrowdLevel.ORANGE: return 'Heavy Crowd Advisory';
      case CrowdLevel.RED:    return '⚠️ Critical Stampede Risk';
    }
  }

  static String _getCrowdEmoji(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.GREEN:  return '🟢';
      case CrowdLevel.YELLOW: return '🟡';
      case CrowdLevel.ORANGE: return '🟠';
      case CrowdLevel.RED:    return '🔴';
    }
  }

  static CrowdSeverity _mapCrowdSeverity(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.GREEN:  return CrowdSeverity.green;
      case CrowdLevel.YELLOW: return CrowdSeverity.yellow;
      case CrowdLevel.ORANGE: return CrowdSeverity.orange;
      case CrowdLevel.RED:    return CrowdSeverity.red;
    }
  }
}
