import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/risk_badge.dart';
import '../../providers/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final shipmentsAsync = ref.watch(shipmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🌾 AgriChain AI'),
            const Spacer(),
            // Persona role switcher
            PopupMenuButton<String>(
              initialValue: user.role,
              tooltip: 'Switch Persona Role',
              onSelected: (newRole) {
                ref.read(currentUserProvider.notifier).setRole(newRole);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.swap_horiz, size: 14, color: AppTheme.primaryGreen),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(value: AppConstants.roleFarmer, child: Text('👨‍🌾 Farmer Persona')),
                const PopupMenuItem(value: AppConstants.roleTransporter, child: Text('🚚 Transporter Persona')),
                const PopupMenuItem(value: AppConstants.roleWarehouseManager, child: Text('🏭 Warehouse Manager')),
                const PopupMenuItem(value: AppConstants.roleBuyer, child: Text('🛒 Buyer Persona')),
                const PopupMenuItem(value: AppConstants.roleAdmin, child: Text('⚡ Admin Persona')),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Hackathon Demo Banner
            InkWell(
              onTap: () => context.push('/simulation'),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.darkForest,
                      AppTheme.primaryGreen.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ LIVE HACKATHON DEMO MODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Trigger temp spikes, delays & route optimization live',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Welcome Header
            Text(
              'Welcome back, ${user.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Active Supply Chain Monitor • Maharashtra Ag-Corridor',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 18),

            // Top 4 Metrics Grid
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'ACTIVE FREIGHT',
                    value: '18',
                    subtitle: '2 Reefer Trucks',
                    icon: Icons.local_shipping_outlined,
                    iconColor: AppTheme.skyBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'CRITICAL HAZARDS',
                    value: '1',
                    subtitle: 'Temp Warning (+4.5°C)',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.criticalRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'LOSS PREVENTED',
                    value: '18,450 kg',
                    subtitle: '₹9.22 Lakh saved',
                    icon: Icons.eco_outlined,
                    iconColor: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'COLD COMPLIANCE',
                    value: '94.8%',
                    subtitle: 'Target: >92.0%',
                    icon: Icons.verified_outlined,
                    iconColor: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Active Monitored Shipment Card
            const Text(
              'ACTIVE MONITORED SHIPMENT',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            shipmentsAsync.when(
              data: (shipments) {
                final active = shipments.isNotEmpty ? shipments.first : null;
                if (active == null) {
                  return const Text('No active shipments.');
                }
                return Container(
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active.shipmentId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                active.batchId,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                          RiskBadge(level: active.riskLevel, score: active.overallRisk),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, size: 16, color: AppTheme.primaryGreen),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${active.originName} ➔ ${active.destinationName}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statTile('REMAINING', '${active.remainingDistanceKm.toInt()} km'),
                          _statTile('SPEED', '${active.currentSpeed.toInt()} km/h'),
                          _statTile('DELAY', '+${active.delayMinutes.toInt()} min'),
                          _statTile('SPOIL RISK', '${active.spoilageRisk.toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryGreen,
                                side: const BorderSide(color: AppTheme.primaryGreen),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Live Tracking'),
                              onPressed: () => context.push('/tracking/${active.shipmentId}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkSurface,
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: AppTheme.darkBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.psychology_outlined, size: 18, color: AppTheme.accentGold),
                              label: const Text('Explain AI'),
                              onPressed: () => context.push('/explainable-ai/${active.batchId}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 24),

            // Quick Access Hub
            const Text(
              'PLATFORM CAPABILITIES',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _hubButton(
                  context,
                  icon: Icons.add_circle_outline,
                  label: 'New Batch',
                  route: '/create-batch',
                  color: AppTheme.primaryGreen,
                ),
                _hubButton(
                  context,
                  icon: Icons.inventory_2_outlined,
                  label: 'My Batches',
                  route: '/batches',
                  color: AppTheme.skyBlue,
                ),
                _hubButton(
                  context,
                  icon: Icons.alt_route,
                  label: 'Route Optimizer',
                  route: '/routes',
                  color: AppTheme.accentGold,
                ),
                _hubButton(
                  context,
                  icon: Icons.qr_code_2,
                  label: 'QR Trace',
                  route: '/qr/AGRI-2026-TOM-000124',
                  color: Colors.purpleAccent,
                ),
                _hubButton(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: 'Gemini AI',
                  route: '/ai-assistant',
                  color: Colors.tealAccent,
                ),
                _hubButton(
                  context,
                  icon: Icons.sensors_outlined,
                  label: 'Simulation',
                  route: '/simulation',
                  color: AppTheme.criticalRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static Widget _hubButton(BuildContext context, {required IconData icon, required String label, required String route, required Color color}) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
