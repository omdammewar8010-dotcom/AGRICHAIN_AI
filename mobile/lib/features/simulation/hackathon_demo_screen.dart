import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sensor_gauge.dart';
import '../../core/widgets/risk_badge.dart';
import '../../providers/providers.dart';

class HackathonDemoScreen extends ConsumerStatefulWidget {
  const HackathonDemoScreen({super.key});

  @override
  ConsumerState<HackathonDemoScreen> createState() => _HackathonDemoScreenState();
}

class _HackathonDemoScreenState extends ConsumerState<HackathonDemoScreen> {
  double _currentTemp = 20.2;
  double _currentHum = 67.5;
  double _delayMin = 0.0;
  String _activeMode = 'Normal Optimal Transit';
  bool _isProcessing = false;

  Future<void> _inject(String mode, double temp, double hum, double delay) async {
    setState(() => _isProcessing = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      await apiClient.dio.post(
        '/simulation/inject',
        data: {
          'anomalyType': mode == 'temp_spike'
              ? 'temp_spike'
              : (mode == 'delay' ? 'route_delay' : (mode == 'humidity' ? 'humidity_spike' : 'normal')),
          'magnitude': mode == 'temp_spike' ? temp : (mode == 'delay' ? delay : hum),
        },
      );
    } catch (_) {}

    setState(() {
      _currentTemp = temp;
      _currentHum = hum;
      _delayMin = delay;
      _activeMode = mode == 'temp_spike'
          ? '🚨 Temperature Spike (32.8°C Reefer Cutoff)'
          : (mode == 'delay'
              ? '⏱️ Route Congestion (+75 Min Delay at Kasara Ghat)'
              : (mode == 'humidity'
                  ? '💧 High Humidity (92% Mold Excursion)'
                  : '✅ Normal Optimal Transit (20.2°C, 67% Hum)'));
      _isProcessing = false;
    });

    ref.invalidate(riskPredictionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final riskAsync = ref.watch(riskPredictionProvider({
      'cropType': 'Tomato',
      'temperature': _currentTemp,
      'humidity': _currentHum,
      'delayMinutes': _delayMin,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Hackathon Live Demo Suite'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Hackathon Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.darkForest, AppTheme.darkCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 PROBLEM STATEMENT: AG-05',
                    style: TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'DETECT ➔ PREDICT ➔ EXPLAIN ➔ OPTIMIZE ➔ ACT ➔ TRACE',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active Scenario: $_activeMode',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Telemetry Gauges
            Row(
              children: [
                Expanded(
                  child: SensorGauge(
                    label: 'Simulated Temp',
                    value: _currentTemp,
                    unit: '°C',
                    minSafe: 18.0,
                    maxSafe: 22.0,
                    icon: Icons.thermostat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SensorGauge(
                    label: 'Simulated Humidity',
                    value: _currentHum,
                    unit: '%',
                    minSafe: 60.0,
                    maxSafe: 75.0,
                    icon: Icons.water_drop_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Real-time ML Evaluation
            riskAsync.when(
              data: (risk) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: risk.overallRisk > 50 ? AppTheme.criticalRed.withOpacity(0.6) : AppTheme.primaryGreen.withOpacity(0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LIVE ML INFERENCE OUTPUT',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          RiskBadge(level: risk.riskLevel, score: risk.overallRisk),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Spoilage Risk: ${risk.spoilageRisk.toInt()}% • Delay Risk: ${risk.delayRisk.toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        risk.recommendedAction,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),

            // Simulation Controls
            const Text(
              'INTERACTIVE ANOMALY INJECTION TRIGGERS',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            _triggerButton(
              title: '🔥 1. Inject Temperature Spike (32.8°C)',
              subtitle: 'Simulates refrigeration unit failure; spoilage risk shoots up',
              color: AppTheme.criticalRed,
              onPressed: () => _inject('temp_spike', 32.8, 72.0, 0.0),
            ),
            const SizedBox(height: 10),

            _triggerButton(
              title: '⏱️ 2. Inject Route Traffic Delay (+75 mins)',
              subtitle: 'Simulates Kasara Ghat highway stoppage; triggers delay model',
              color: AppTheme.warningOrange,
              onPressed: () => _inject('delay', 24.5, 70.0, 75.0),
            ),
            const SizedBox(height: 10),

            _triggerButton(
              title: '💧 3. Inject Moisture / Humidity Spike (94%)',
              subtitle: 'Simulates rain infiltration & mold hazard',
              color: AppTheme.skyBlue,
              onPressed: () => _inject('humidity', 21.0, 94.0, 0.0),
            ),
            const SizedBox(height: 10),

            _triggerButton(
              title: '✅ 4. Restore Optimal Baseline (20.2°C, 67%)',
              subtitle: 'Resets cargo refrigeration to factory optimal conditions',
              color: AppTheme.primaryGreen,
              onPressed: () => _inject('normal', 20.2, 67.5, 0.0),
            ),
            const SizedBox(height: 24),

            // Guided Demo Shortcuts
            const Text(
              'DEMO SHORTCUTS',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkSurface,
                      foregroundColor: AppTheme.accentGold,
                      side: const BorderSide(color: AppTheme.accentGold),
                    ),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('Explain AI (SHAP)'),
                    onPressed: () => context.push('/explainable-ai/AGRI-2026-TOM-000124'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.alt_route, size: 16),
                    label: const Text('Optimize Routes'),
                    onPressed: () => context.push('/routes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Ask Gemini AI'),
                    onPressed: () => context.push('/ai-assistant'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('Inspect QR'),
                    onPressed: () => context.push('/qr/AGRI-2026-TOM-000124'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _triggerButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.bolt, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
