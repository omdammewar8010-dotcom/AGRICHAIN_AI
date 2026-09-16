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

  final List<CropBatchModel> _localBatches = [
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

  Stream<List<CropBatchModel>> streamBatches() async* {
    yield _localBatches;
    try {
      if (_firestore != null) {
        await for (final snapshot in _firestore!
            .collection('crop_batches')
            .snapshots()
            .handleError((_) => null)) {
          if (snapshot.docs.isNotEmpty) {
            yield snapshot.docs
                .map((doc) => CropBatchModel.fromMap(doc.data(), doc.id))
                .toList();
          }
        }
      }
    } catch (_) {
      // Baseline already yielded
    }
  }

  Future<void> createBatch(CropBatchModel batch) async {
    _localBatches.insert(0, batch);
    try {
      if (_firestore != null) {
        await _firestore!
            .collection('crop_batches')
            .doc(batch.batchId)
            .set(batch.toMap());
      }
    } catch (_) {
      // In offline/demo mode, stored in local list
    }
  }

  Future<CropBatchModel?> getBatchById(String batchId) async {
    try {
      if (_firestore != null) {
        final doc = await _firestore!.collection('crop_batches').doc(batchId).get();
        if (doc.exists && doc.data() != null) {
          return CropBatchModel.fromMap(doc.data()!, doc.id);
        }
      }
    } catch (_) {}

    final found = _localBatches.where((b) => b.batchId == batchId);
    return found.isNotEmpty ? found.first : _localBatches.first;
  }
}
