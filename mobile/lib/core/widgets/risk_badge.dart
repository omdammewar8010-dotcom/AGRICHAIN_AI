import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final String level;
  final double? score;

  const RiskBadge({super.key, required this.level, this.score});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        color = AppTheme.criticalRed;
        break;
      case 'HIGH':
        color = AppTheme.warningOrange;
        break;
      case 'MEDIUM':
        color = AppTheme.accentGold;
        break;
      default:
        color = AppTheme.primaryGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            score != null ? '${level.toUpperCase()} (${score!.toInt()})' : level.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
