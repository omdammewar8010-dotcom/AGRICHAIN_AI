import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/batch_event_model.dart';

class TraceabilityRepository {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  final List<BatchEventModel> _demoTimeline = [
    const BatchEventModel(
      eventId: 'EVT-001',
      batchId: 'AGRI-2026-TOM-000124',
      stage: 'harvest',
      type: 'harvest_registered',
      locationName: 'Sahyadri Agro Farms, Nashik',
      latitude: 19.9975,
      longitude: 73.7898,
      temperature: 20.5,
      humidity: 65.0,
      performedBy: 'Rahul Patil (Farmer)',
      role: 'farmer',
      description: 'Harvested 1,200 kg Roma Tomatoes. Graded Grade A. Pre-cooled to 20°C in packhouse.',
      timestamp: '2026-09-16 06:30 AM',
    ),
    const BatchEventModel(
      eventId: 'EVT-002',
      batchId: 'AGRI-2026-TOM-000124',
      stage: 'collection',
      type: 'intake_inspection',
      locationName: 'Dindori Rural Collection Center',
      latitude: 19.8500,
      longitude: 73.7100,
      temperature: 21.0,
      humidity: 68.0,
      performedBy: 'Suresh More (Inspector)',
      role: 'collection_center',
      description: 'QC Verified: Brix 5.2, Firmness 4.8kg/cm2. QR code tag affixed. Loaded into Reefer MH-15-EG-8842.',
      timestamp: '2026-09-16 08:15 AM',
    ),
    const BatchEventModel(
      eventId: 'EVT-003',
      batchId: 'AGRI-2026-TOM-000124',
      stage: 'transport',
      type: 'transit_checkpoint',
      locationName: 'Igatpuri Logistics Checkpoint (KM 45)',
      latitude: 19.6948,
      longitude: 73.5601,
      temperature: 20.8,
      humidity: 67.2,
      performedBy: 'Vikram Shinde (Transporter)',
      role: 'transporter',
      description: 'Reefer compressor active. IoT Node ESP32-TRUCK-001 operational. Telemetry nominal.',
      timestamp: '2026-09-16 09:10 AM',
    ),
  ];

  Stream<List<BatchEventModel>> streamTimeline(String batchId) async* {
    // 1. Immediately yield cached/demo events so UI renders instantly (0ms latency)
    final initial = _demoTimeline.where((e) => e.batchId == batchId).toList();
    yield initial.isNotEmpty ? initial : _demoTimeline;

    // 2. Stream live events from Cloud Firestore if available
    try {
      if (_firestore != null) {
        await for (final snap in _firestore!
            .collection('batch_events')
            .where('batchId', isEqualTo: batchId)
            .snapshots()
            .handleError((_) => null)) {
          if (snap.docs.isNotEmpty) {
            yield snap.docs
                .map((doc) => BatchEventModel.fromMap(doc.data(), doc.id))
                .toList();
          }
        }
      }
    } catch (_) {
      // Offline fallback already yielded above
    }
  }

  Future<void> logEvent(BatchEventModel event) async {
    _demoTimeline.add(event);
    try {
      if (_firestore != null) {
        await _firestore!.collection('batch_events').doc(event.eventId).set({
          'batchId': event.batchId,
          'shipmentId': event.shipmentId,
          'stage': event.stage,
          'type': event.type,
          'location': {
            'address': event.locationName,
            'latitude': event.latitude,
            'longitude': event.longitude,
          },
          'temperature': event.temperature,
          'humidity': event.humidity,
          'performedBy': event.performedBy,
          'role': event.role,
          'description': event.description,
          'timestamp': event.timestamp,
        });
      }
    } catch (_) {}
  }
}
