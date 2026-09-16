import '../core/network/api_client.dart';
import '../models/chat_message_model.dart';

class AIRepository {
  final ApiClient _apiClient;

  AIRepository(this._apiClient);

  Future<ChatMessageModel> sendQuery({
    required String message,
    String? batchId,
    String? cropName,
    double? currentTemperature,
    double? currentHumidity,
    double? delayMinutes,
    double? riskScore,
    String? riskLevel,
    String? currentLocation,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/chat',
        data: {
          'message': message,
          'context': {
            'batchId': batchId ?? 'AGRI-2026-TOM-000124',
            'shipmentId': 'SHIP-2026-0916-01',
            'cropName': cropName ?? 'Tomato',
            'currentTemperature': currentTemperature ?? 22.0,
            'currentHumidity': currentHumidity ?? 68.0,
            'preferredTempMin': 18.0,
            'preferredTempMax': 22.0,
            'delayMinutes': delayMinutes ?? 0.0,
            'riskScore': riskScore ?? 24.0,
            'riskLevel': riskLevel ?? 'LOW',
            'currentLocation': currentLocation ?? 'Kasara Ghat Corridor',
            'destination': 'APMC Market Vashi, Mumbai',
          },
        },
      );

      final data = response.data;
      return ChatMessageModel(
        text: data['reply'] ?? 'Diagnostics evaluated.',
        isUser: false,
        keyTakeaways: (data['keyTakeaways'] as List?)?.map((e) => e.toString()).toList() ?? [],
        suggestedActions: (data['suggestedActions'] as List?)?.map((e) => e.toString()).toList() ?? [],
        timestamp: DateTime.now(),
      );
    } catch (_) {
      // Fallback
      return ChatMessageModel(
        text: 'The shipment is currently at moderate risk because container temperature is $currentTemperature°C '
            'and transit delay has accumulated to +${delayMinutes?.toInt() ?? 0} minutes. We recommend reviewing '
            'the optimized alternate route via Samruddhi Expressway.',
        isUser: false,
        keyTakeaways: [
          'Current Temperature: $currentTemperature°C (Safe Max: 22.0°C)',
          'Accumulated Delay: +${delayMinutes?.toInt() ?? 0} minutes',
        ],
        suggestedActions: [
          'Verify compressor alternator power switch',
          'Evaluate detour to Bhiwandi Cold Hub',
        ],
        timestamp: DateTime.now(),
      );
    }
  }
}
