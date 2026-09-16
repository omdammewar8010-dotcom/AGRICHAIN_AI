import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_batch_model.dart';

class BatchRepository {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static final List<CropBatchModel> _initialBatches = [
    const CropBatchModel(
      batchId: 'AGRI-2026-TOM-000124',
      cropName: 'Tomato (Roma Hybrid)',
      cropCategory: 'Vegetable',
      quantity: 1200.0,
      unit: 'kg',
      farmerId: 'USER-001',
      farmId: 'FARM-NASHIK-01',
      harvestDate: '2026-09-16',
      expectedShelfLifeHours: 96.0,
      preferredTempMin: 18.0,
      preferredTempMax: 22.0,
      preferredHumMin: 60.0,
      preferredHumMax: 75.0,
      qualityGrade: 'A',
      currentStatus: 'in_transit',
      originAddress: 'Sahyadri Agro Farms, Nashik, Maharashtra',
      originLat: 19.9975,
      originLng: 73.7898,
      destinationAddress: 'APMC Central Terminal, Vashi, Navi Mumbai',
      destLat: 19.0760,
      destLng: 72.8777,
      activeShipmentId: 'SHIP-2026-0916-01',
    ),
    const CropBatchModel(
      batchId: 'AGRI-2026-GRP-000088',
      cropName: 'Thompson Seedless Grapes',
      cropCategory: 'Fruit',
      quantity: 850.0,
      unit: 'kg',
      farmerId: 'USER-001',
      farmId: 'FARM-NASHIK-01',
      harvestDate: '2026-09-15',
      expectedShelfLifeHours: 120.0,
      preferredTempMin: 0.0,
      preferredTempMax: 2.0,
      preferredHumMin: 85.0,
      preferredHumMax: 95.0,
      qualityGrade: 'A+',
      currentStatus: 'registered',
      originAddress: 'Dindori Vineyard, Nashik',
      originLat: 20.1500,
      originLng: 73.8300,
      destinationAddress: 'Cold Chain Terminal, JNPT Mumbai',
      destLat: 18.9500,
      destLng: 72.9500,
    ),
  ];

  final Map<String, CropBatchModel> _batchesMap = {};
  late final StreamController<List<CropBatchModel>> _batchesController;
  StreamSubscription? _firestoreSub;

  BatchRepository() {
    _batchesController = StreamController<List<CropBatchModel>>.broadcast();
    for (final b in _initialBatches) {
      _batchesMap[b.batchId] = b;
    }
    _initFirestoreListener();
  }

  void _initFirestoreListener() {
    try {
      if (_firestore != null) {
        _firestoreSub = _firestore!
            .collection('crop_batches')
            .snapshots()
            .listen(
          (snapshot) {
            for (final doc in snapshot.docs) {
              final batch = CropBatchModel.fromMap(doc.data(), doc.id);
              _batchesMap[batch.batchId] = batch;
            }
            _emitCurrent();
          },
          onError: (_) {
            // Keep in-memory cache on offline or error
          },
        );
      }
    } catch (_) {}
  }

  void _emitCurrent() {
    if (!_batchesController.isClosed) {
      _batchesController.add(_getCurrentList());
    }
  }

  List<CropBatchModel> _getCurrentList() {
    final list = _batchesMap.values.toList();
    list.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
    return list;
  }

  Stream<List<CropBatchModel>> streamBatches() async* {
    yield _getCurrentList();
    yield* _batchesController.stream;
  }

  Future<void> createBatch(CropBatchModel batch) async {
    // 1. Immediately store in reactive memory map and emit so UI updates with 0 latency
    _batchesMap[batch.batchId] = batch;
    _emitCurrent();

    // 2. Persist to Cloud Firestore
    try {
      if (_firestore != null) {
        await _firestore!
            .collection('crop_batches')
            .doc(batch.batchId)
            .set(batch.toMap());

        // Log initial harvest event in batch_events for complete traceability
        await _firestore!
            .collection('batch_events')
            .doc('EVT-${batch.batchId}-001')
            .set({
          'batchId': batch.batchId,
          'stage': 'harvest',
          'type': 'harvest_registered',
          'location': {
            'name': batch.originAddress,
            'latitude': batch.originLat,
            'longitude': batch.originLng,
          },
          'temperature': batch.preferredTempMin,
          'humidity': batch.preferredHumMin,
          'performedBy': 'Registered Producer',
          'role': 'farmer',
          'description': 'Harvest registered: ${batch.quantity.toInt()} ${batch.unit} of ${batch.cropName} (Grade ${batch.qualityGrade}). Quality passport active.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Offline fallback: batch is safely preserved in reactive _batchesMap
    }
  }

  Future<CropBatchModel?> getBatchById(String batchId) async {
    if (_batchesMap.containsKey(batchId)) {
      return _batchesMap[batchId];
    }
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection('crop_batches').doc(batchId).get();
        if (doc.exists && doc.data() != null) {
          final batch = CropBatchModel.fromMap(doc.data()!, doc.id);
          _batchesMap[batch.batchId] = batch;
          return batch;
        }
      }
    } catch (_) {}

    return _batchesMap.values.isNotEmpty ? _batchesMap.values.first : null;
  }

  void dispose() {
    _firestoreSub?.cancel();
    _batchesController.close();
  }
}
