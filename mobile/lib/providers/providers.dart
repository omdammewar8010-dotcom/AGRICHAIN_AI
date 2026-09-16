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

// Value-equatable parameter models to prevent infinite Riverpod rebuilds
class RiskParams {
  final String cropType;
  final double temperature;
  final double humidity;
  final double delayMinutes;

  const RiskParams({
    this.cropType = 'Tomato',
    this.temperature = 21.0,
    this.humidity = 67.0,
    this.delayMinutes = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskParams &&
          other.cropType == cropType &&
          other.temperature == temperature &&
          other.humidity == humidity &&
          other.delayMinutes == delayMinutes;

  @override
  int get hashCode => Object.hash(cropType, temperature, humidity, delayMinutes);
}

class RouteParams {
  final double timeWeight;
  final double costWeight;
  final double riskWeight;
  final double currentTemp;
  final double currentDelay;

  const RouteParams({
    this.timeWeight = 0.35,
    this.costWeight = 0.25,
    this.riskWeight = 0.40,
    this.currentTemp = 21.0,
    this.currentDelay = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteParams &&
          other.timeWeight == timeWeight &&
          other.costWeight == costWeight &&
          other.riskWeight == riskWeight &&
          other.currentTemp == currentTemp &&
          other.currentDelay == currentDelay;

  @override
  int get hashCode => Object.hash(timeWeight, costWeight, riskWeight, currentTemp, currentDelay);
}

// Future Providers
final riskPredictionProvider = FutureProvider.family<RiskPredictionModel, RiskParams>((ref, params) async {
  return ref.watch(mlRepoProvider).predictRisk(
        cropType: params.cropType,
        temperature: params.temperature,
        humidity: params.humidity,
        delayMinutes: params.delayMinutes,
      );
});

final optimizedRoutesProvider = FutureProvider.family<List<RouteOptionModel>, RouteParams>((ref, params) async {
  return ref.watch(routeRepoProvider).getOptimizedRoutes(
        timeWeight: params.timeWeight,
        costWeight: params.costWeight,
        riskWeight: params.riskWeight,
        currentTemp: params.currentTemp,
        currentDelay: params.currentDelay,
      );
});

