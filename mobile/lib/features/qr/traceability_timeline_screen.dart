import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class TraceabilityTimelineScreen extends ConsumerWidget {
  final String batchId;

  const TraceabilityTimelineScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineStreamProvider(batchId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Traceability Journey', style: TextStyle(fontSize: 16)),
            Text(batchId, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
          ],
        ),
      ),
      body: timelineAsync.when(
        data: (events) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline indicator column
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _stageColor(event.stage).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: _stageColor(event.stage), width: 2),
                          ),
                          child: Icon(
                            _stageIcon(event.stage),
                            size: 14,
                            color: _stageColor(event.stage),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppTheme.darkBorder,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Event details card
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  event.stage.toUpperCase(),
                                  style: TextStyle(
                                    color: _stageColor(event.stage),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  event.timestamp,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.locationName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  event.performedBy,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                const Spacer(),
                                const Icon(Icons.thermostat, size: 14, color: AppTheme.accentGold),
                                const SizedBox(width: 2),
                                Text(
                                  '${event.temperature.toStringAsFixed(1)}°C',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading traceability: $err')),
      ),
    );
  }

  static Color _stageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'harvest':
        return AppTheme.primaryGreen;
      case 'collection':
        return AppTheme.skyBlue;
      case 'transport':
        return AppTheme.warningOrange;
      case 'warehouse':
        return AppTheme.accentGold;
      default:
        return Colors.purpleAccent;
    }
  }

  static IconData _stageIcon(String stage) {
    switch (stage.toLowerCase()) {
      case 'harvest':
        return Icons.eco;
      case 'collection':
        return Icons.storefront;
      case 'transport':
        return Icons.local_shipping;
      case 'warehouse':
        return Icons.warehouse;
      default:
        return Icons.check_circle_outline;
    }
  }
}
