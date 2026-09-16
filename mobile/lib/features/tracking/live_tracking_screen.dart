import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sensor_gauge.dart';
import '../../core/widgets/risk_badge.dart';
import '../../providers/providers.dart';

class LiveTrackingScreen extends ConsumerWidget {
  final String shipmentId;

  const LiveTrackingScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(liveTelemetryStreamProvider(shipmentId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live IoT Freight Tracking', style: TextStyle(fontSize: 16)),
            Text(
              'RTDB Stream • $shipmentId',
              style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined, color: AppTheme.accentGold),
            tooltip: 'Explain Risk with AI',
            onPressed: () => context.push('/explainable-ai/AGRI-2026-TOM-000124'),
          ),
        ],
      ),
      body: telemetryAsync.when(
        data: (telem) {
          final isBreached = telem.temperature > 22.0 || telem.anomalyFlag;
          final riskScore = isBreached ? 78.5 : 22.0;
          final riskLevel = isBreached ? 'CRITICAL' : 'LOW';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Simulated High-Tech Map Canvas with Coordinates
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBreached ? AppTheme.criticalRed.withOpacity(0.5) : AppTheme.darkBorder,
                      width: isBreached ? 1.5 : 1.0,
                    ),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        AppTheme.darkSurface,
                        AppTheme.darkBg,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Grid map lines
                      CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: _MapGridPainter(),
                      ),
                      // Vehicle Pin
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen).withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.darkBg.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${telem.latitude.toStringAsFixed(4)}° N, ${telem.longitude.toStringAsFixed(4)}° E',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: telem.deviceStatus == 'online' ? AppTheme.primaryGreen : AppTheme.criticalRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                telem.deviceStatus.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔋 ${telem.battery}%',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live Sensor Readings (Temperature & Humidity Gauges)
                Row(
                  children: [
                    Expanded(
                      child: SensorGauge(
                        label: 'Cargo Temp',
                        value: telem.temperature,
                        unit: '°C',
                        minSafe: 18.0,
                        maxSafe: 22.0,
                        icon: Icons.thermostat,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SensorGauge(
                        label: 'Rel. Humidity',
                        value: telem.humidity,
                        unit: '%',
                        minSafe: 60.0,
                        maxSafe: 75.0,
                        icon: Icons.water_drop_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Real-time ML Risk Evaluation Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBreached ? AppTheme.criticalRed.withOpacity(0.5) : AppTheme.darkBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CONTINUOUS ML RISK EVALUATION',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          RiskBadge(level: riskLevel, score: riskScore),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isBreached
                            ? '🚨 Anomaly Detected: Container temperature (+${(telem.temperature - 22.0).toStringAsFixed(1)}°C) exceeds safety limits. Crop respiration accelerated.'
                            : '✅ Cold-chain integrity nominal. Produce freshness index optimal at 94.8%.',
                        style: TextStyle(
                          color: isBreached ? AppTheme.criticalRed : Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkSurface,
                                foregroundColor: AppTheme.accentGold,
                                side: const BorderSide(color: AppTheme.accentGold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.analytics_outlined, size: 16),
                              label: const Text('View SHAP XAI'),
                              onPressed: () => context.push('/explainable-ai/AGRI-2026-TOM-000124'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.alt_route, size: 16),
                              label: const Text('Reroute'),
                              onPressed: () => context.push('/routes'),
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error reading RTDB stream: $err')),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
