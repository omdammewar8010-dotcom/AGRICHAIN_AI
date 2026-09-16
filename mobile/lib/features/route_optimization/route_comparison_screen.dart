import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class RouteComparisonScreen extends ConsumerStatefulWidget {
  const RouteComparisonScreen({super.key});

  @override
  ConsumerState<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends ConsumerState<RouteComparisonScreen> {
  String _selectedPriority = 'freshness'; // freshness, time, cost
  String? _chosenRouteId = 'ROUTE-EXPRESS-01';

  @override
  Widget build(BuildContext context) {
    double timeW = 0.35;
    double costW = 0.25;
    double riskW = 0.40;

    if (_selectedPriority == 'time') {
      timeW = 0.60;
      costW = 0.15;
      riskW = 0.25;
    } else if (_selectedPriority == 'cost') {
      timeW = 0.20;
      costW = 0.60;
      riskW = 0.20;
    }

    final routesAsync = ref.watch(optimizedRoutesProvider(RouteParams(
      timeWeight: timeW,
      costWeight: costW,
      riskWeight: riskW,
      currentTemp: 31.8,
      currentDelay: 45.0,
    )));

    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Objective Route Engine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'LOGISTICS OPTIMIZATION PRIORITY',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Priority Presets
            Row(
              children: [
                _priorityButton('Freshness / Risk', 'freshness', Icons.eco),
                const SizedBox(width: 8),
                _priorityButton('Fastest ETA', 'time', Icons.speed),
                const SizedBox(width: 8),
                _priorityButton('Lowest Cost', 'cost', Icons.savings_outlined),
              ],
            ),
            const SizedBox(height: 20),

            routesAsync.when(
              data: (routes) {
                return Column(
                  children: routes.map((route) {
                    final isSelected = _chosenRouteId == route.routeId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: route.isRecommended
                              ? AppTheme.primaryGreen
                              : (isSelected ? Colors.white : AppTheme.darkBorder),
                          width: route.isRecommended || isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route.routeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (route.isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'RECOMMENDED',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Route metrics
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _tile('ETA', '${(route.etaMinutes / 60).toStringAsFixed(1)}h'),
                              _tile('DISTANCE', '${route.distanceKm.toInt()} km'),
                              _tile('COST', '₹${route.costInr.toInt()}'),
                              _tile('SPOIL RISK', '${route.spoilageRisk.toInt()}%',
                                  color: route.spoilageRisk > 30 ? AppTheme.criticalRed : AppTheme.primaryGreen),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Highlights
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: route.highlights.map((h) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(h, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Cold storage points en route
                          if (route.coldStoragePoints.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.ac_unit, size: 14, color: AppTheme.skyBlue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Cold Hubs: ${route.coldStoragePoints.join(' • ')}',
                                    style: const TextStyle(color: AppTheme.skyBlue, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? AppTheme.primaryGreen : AppTheme.darkSurface,
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryGreen : AppTheme.darkBorder,
                                ),
                              ),
                              onPressed: () {
                                setState(() => _chosenRouteId = route.routeId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dispatched corridor: ${route.routeName}'),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              },
                              child: Text(isSelected ? '✓ Active Selected Route' : 'Dispatch via this Corridor'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error calculating routes: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityButton(String label, String id, IconData icon) {
    final isSelected = _selectedPriority == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPriority = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen.withOpacity(0.2) : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.darkBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.primaryGreen : Colors.white60),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tile(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
