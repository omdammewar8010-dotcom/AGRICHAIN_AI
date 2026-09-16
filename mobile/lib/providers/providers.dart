import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/crop_batch_model.dart';
import '../models/shipment_model.dart';
import '../models/batch_event_model.dart';
import '../models/live_telemetry_model.dart';
import '../models/risk_model.dart';
import '../models/route_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/batch_repository.dart';
import '../repositories/shipment_repository.dart';
import '../repositories/traceability_repository.dart';
import '../repositories/iot_repository.dart';
import '../repositories/ml_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/ai_repository.dart';

// Client & Repositories
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository());
final batchRepoProvider = Provider<BatchRepository>((ref) => BatchRepository());
final shipmentRepoProvider = Provider<ShipmentRepository>((ref) => ShipmentRepository());
final traceabilityRepoProvider = Provider<TraceabilityRepository>((ref) => TraceabilityRepository());
final iotRepoProvider = Provider<IoTRepository>((ref) => IoTRepository());
final mlRepoProvider = Provider<MLRepository>((ref) => MLRepository(ref.watch(apiClientProvider)));
final routeRepoProvider = Provider<RouteRepository>((ref) => RouteRepository(ref.watch(apiClientProvider)));
final aiRepoProvider = Provider<AIRepository>((ref) => AIRepository(ref.watch(apiClientProvider)));

// Current User Notifier Provider (supports live role switching for hackathon demo)
class CurrentUserNotifier extends Notifier<UserModel> {
  @override
  UserModel build() {
    return ref.watch(authRepoProvider).currentDemoUser;
  }

  void setRole(String role) {
    ref.read(authRepoProvider).setDemoRole(role);
    state = ref.read(authRepoProvider).currentDemoUser;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel>(CurrentUserNotifier.new);

// Stream Providers
final batchesStreamProvider = StreamProvider<List<CropBatchModel>>((ref) {
  return ref.watch(batchRepoProvider).streamBatches();
});

final shipmentsStreamProvider = StreamProvider<List<ShipmentModel>>((ref) {
  return ref.watch(shipmentRepoProvider).streamShipments();
});

final liveTelemetryStreamProvider = StreamProvider.family<LiveTelemetryModel, String>((ref, shipmentId) {
  return ref.watch(iotRepoProvider).streamShipmentTelemetry(shipmentId);
});

final timelineStreamProvider = StreamProvider.family<List<BatchEventModel>, String>((ref, batchId) {
  return ref.watch(traceabilityRepoProvider).streamTimeline(batchId);
});

// Future Providers
final riskPredictionProvider = FutureProvider.family<RiskPredictionModel, Map<String, dynamic>>((ref, params) async {
  return ref.watch(mlRepoProvider).predictRisk(
        cropType: params['cropType'] ?? 'Tomato',
        temperature: (params['temperature'] as num?)?.toDouble() ?? 21.0,
        humidity: (params['humidity'] as num?)?.toDouble() ?? 67.0,
        delayMinutes: (params['delayMinutes'] as num?)?.toDouble() ?? 0.0,
      );
});

final optimizedRoutesProvider = FutureProvider.family<List<RouteOptionModel>, Map<String, dynamic>>((ref, params) async {
  return ref.watch(routeRepoProvider).getOptimizedRoutes(
        timeWeight: params['timeWeight'] ?? 0.35,
        costWeight: params['costWeight'] ?? 0.25,
        riskWeight: params['riskWeight'] ?? 0.40,
        currentTemp: params['currentTemp'] ?? 21.0,
        currentDelay: params['currentDelay'] ?? 0.0,
      );
});
