import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/live_telemetry_model.dart';

class IoTRepository {
  FirebaseDatabase? get _rtdb {
    try {
      return FirebaseDatabase.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<LiveTelemetryModel> streamShipmentTelemetry(String shipmentId) {
    try {
      if (_rtdb == null) {
        return Stream.periodic(const Duration(seconds: 4), (_) => _fallbackTelemetry());
      }
      return _rtdb!
          .ref('live/shipments/$shipmentId')
          .onValue
          .map((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final map = event.snapshot.value as Map<dynamic, dynamic>;
          return LiveTelemetryModel.fromMap(map);
        }
        return _fallbackTelemetry();
      }).handleError((_) => _fallbackTelemetry());
    } catch (_) {
      // In offline/demo mode, emit realistic simulated tick every 4 seconds
      return Stream.periodic(const Duration(seconds: 4), (_) => _fallbackTelemetry());
    }
  }

  LiveTelemetryModel _fallbackTelemetry() {
    return LiveTelemetryModel(
      batchId: 'AGRI-2026-TOM-000124',
      latitude: 19.4521,
      longitude: 73.3421,
      temperature: 20.8,
      humidity: 67.5,
      speed: 48.5,
      battery: 94,
      deviceStatus: 'online',
      anomalyFlag: false,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
