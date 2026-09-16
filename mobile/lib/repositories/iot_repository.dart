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

  Stream<LiveTelemetryModel> streamShipmentTelemetry(String shipmentId) async* {
    yield _fallbackTelemetry();
    try {
      if (_rtdb != null) {
        await for (final event in _rtdb!
            .ref('live/shipments/$shipmentId')
            .onValue
            .handleError((_) => null)) {
          if (event.snapshot.value is Map) {
            final map = event.snapshot.value as Map<dynamic, dynamic>;
            yield LiveTelemetryModel.fromMap(map);
          }
        }
      }
    } catch (_) {}
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
