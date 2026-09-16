import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/risk_badge.dart';
import '../../providers/providers.dart';

class ExplainableAiScreen extends ConsumerWidget {
  final String batchId;

  const ExplainableAiScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskAsync = ref.watch(riskPredictionProvider({
      'cropType': 'Tomato',
      'temperature': 31.8,
      'humidity': 84.0,
      'delayMinutes': 45.0,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explainable AI (SHAP Diagnostics)'),
      ),
      body: riskAsync.when(
        data: (risk) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top composite score card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.criticalRed.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PREDICTIVE COMPOSITE RISK',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          RiskBadge(level: risk.riskLevel, score: risk.overallRisk),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${risk.overallRisk.toInt()} / 100',
                        style: const TextStyle(
                          color: AppTheme.criticalRed,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Spoilage Risk: ${risk.spoilageRisk.toInt()}% • Delay Risk: ${risk.delayRisk.toInt()}%',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Prescriptive Action Recommendation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.criticalRed.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppTheme.accentGold, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'AI PRESCRIPTIVE ACTION',
                            style: TextStyle(
                              color: AppTheme.accentGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        risk.recommendedAction,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SHAP Feature Attribution Impact Breakdown
                const Text(
                  'SHAP FEATURE ATTRIBUTION BREAKDOWN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Shows exactly why the ML model flagged this shipment as high risk',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 14),

                ...risk.factors.map((factor) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              factor.factor,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '+${factor.impact.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: AppTheme.warningOrange,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (factor.impact / 100.0).clamp(0.0, 1.0),
                            backgroundColor: AppTheme.darkSurface,
                            color: AppTheme.warningOrange,
                            minHeight: 6,
                          ),
                        ),
                        if (factor.description != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            factor.description!,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Action buttons
                ElevatedButton.icon(
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Optimize Alternate Route Now'),
                  onPressed: () => context.push('/routes'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ask Gemini Diagnostic Assistant'),
                  onPressed: () => context.push('/ai-assistant'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading XAI factors: $err')),
      ),
    );
  }
}
