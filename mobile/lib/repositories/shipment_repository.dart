import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shipment_model.dart';

class ShipmentRepository {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final List<ShipmentModel> _localShipments = [
    const ShipmentModel(
      shipmentId: 'SHIP-2026-0916-01',
      batchId: 'AGRI-2026-TOM-000124',
      transporterId: 'USER-123',
      vehicleId: 'MH-15-EG-8842 (Reefer)',
      iotDeviceId: 'ESP32-TRUCK-001',
      status: 'in_transit',
      originName: 'Sahyadri Agro Farms, Nashik',
      destinationName: 'APMC Market Vashi, Mumbai',
      currentLat: 19.4521,
      currentLng: 73.3421,
      distanceKm: 165.0,
      remainingDistanceKm: 75.0,
      currentSpeed: 48.5,
      delayMinutes: 15.0,
      spoilageRisk: 22.0,
      overallRisk: 24.5,
      riskLevel: 'LOW',
      activeRouteId: 'ROUTE-EXPRESS-01',
    ),
  ];

  Stream<List<ShipmentModel>> streamShipments() {
    try {
      if (_firestore == null) return Stream.value(_localShipments);
      return _firestore!.collection('shipments').snapshots().map((snap) {
        if (snap.docs.isEmpty) return _localShipments;
        return snap.docs
            .map((doc) => ShipmentModel.fromMap(doc.data(), doc.id))
            .toList();
      }).handleError((_) => _localShipments);
    } catch (_) {
      return Stream.value(_localShipments);
    }
  }

  Future<ShipmentModel> getShipmentById(String id) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection('shipments').doc(id).get();
        if (doc.exists && doc.data() != null) {
          return ShipmentModel.fromMap(doc.data()!, doc.id);
        }
      }
    } catch (_) {}
    return _localShipments.first;
  }
}
