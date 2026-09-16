import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class QrCodeScreen extends StatelessWidget {
  final String batchId;

  const QrCodeScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Traceability QR Tag')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Column(
                children: [
                  const Text(
                    'IMMUTABLE SUPPLY CHAIN PASSPORT',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    batchId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // QR Code Widget
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: 'agrichain://batch/$batchId',
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Scan with any smartphone or AgriChain scanner to inspect origin farm, harvesting audit, real-time refrigeration history, and cold-chain compliance score.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Inspect Full Traceability Timeline'),
              onPressed: () => context.push('/traceability/$batchId'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.darkBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.share_outlined, color: AppTheme.accentGold),
              label: const Text('Share Digital Certificate'),
              onPressed: () => _showDigitalCertificateModal(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDigitalCertificateModal(BuildContext context) {
    const certificateText = '''
🌾 AGRISUPPLY LEDGER — DIGITAL QUALITY CERTIFICATE
==================================================
Batch ID:        AGRI-2026-TOM-000124
Commodity:       Hybrid Roma Tomato (Export Grade A+)
Harvest Date:    2026-09-16 06:30 AM
Origin:          Sahyadri Agro Farms, Nashik, Maharashtra
Destination:     APMC Central Market Vashi, Mumbai
Compliance:      98.4% Thermal & Transpiration Compliance
Cold-Chain:      Optimal Threshold <= 22.0°C (Nominal)
Ledger Hash:     0x8f3c4d12e4b6a9871029c3f41209b67e2a9b44c1
Verification:    AUTHENTIC & TAMPER-EVIDENT
Ledger URL:      http://localhost:3000/#/traceability/AGRI-2026-TOM-000124
==================================================
Verified by AgriChain AI Automated Logistics Protocol
''';

    // 1. Copy to clipboard immediately
    Clipboard.setData(ClipboardData(
      text: 'http://localhost:3000/#/traceability/$batchId\n\n$certificateText',
    ));

    // 2. Present Rich Interactive Digital Certificate
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.darkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.primaryGreen, width: 2)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with Verified Seal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Digital Quality Certificate',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Batch $batchId • Copied to Clipboard',
                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Certificate Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  children: [
                    _certRow('PRODUCE', 'Hybrid Roma Tomato (Grade A+)'),
                    _certRow('FARM ORIGIN', 'Sahyadri Agro Farms, Nashik'),
                    _certRow('HARVEST DATE', '16 Sep 2026 • 06:30 AM'),
                    _certRow('COLD CHAIN INTEGRITY', '98.4% (Optimal)', valueColor: AppTheme.primaryGreen),
                    _certRow('DESTINATION', 'APMC Central Market Vashi'),
                    const Divider(color: AppTheme.darkBorder, height: 18),
                    _certRow(
                      'LEDGER SIGNATURE',
                      '0x8f3c4d12...7e2a9b44c1',
                      valueColor: AppTheme.accentGold,
                      isMonospace: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Verifiable Passport URL', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'http://localhost:3000/#/traceability/$batchId',
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Digital Certificate URL copied to clipboard!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.timeline, size: 18, color: AppTheme.skyBlue),
                label: const Text('Inspect Full Traceability Journey'),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/traceability/$batchId');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _certRow(String label, String value, {Color? valueColor, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

