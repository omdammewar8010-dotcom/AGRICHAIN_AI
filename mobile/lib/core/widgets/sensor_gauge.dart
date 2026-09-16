import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SensorGauge extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double minSafe;
  final double maxSafe;
  final IconData icon;

  const SensorGauge({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.minSafe,
    required this.maxSafe,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isBreached = value < minSafe || value > maxSafe;
    final alertColor = isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBreached ? alertColor.withOpacity(0.6) : AppTheme.darkBorder,
          width: isBreached ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: alertColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (isBreached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: alertColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BREACH',
                    style: TextStyle(color: alertColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: alertColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Optimal: ${minSafe.toStringAsFixed(0)} - ${maxSafe.toStringAsFixed(0)}$unit',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
