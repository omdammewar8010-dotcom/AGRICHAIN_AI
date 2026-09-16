class CropBatchModel {
  final String batchId;
  final String cropName;
  final String cropCategory;
  final double quantity;
  final String unit;
  final String farmerId;
  final String? farmId;
  final String harvestDate;
  final double expectedShelfLifeHours;
  final double preferredTempMin;
  final double preferredTempMax;
  final double preferredHumMin;
  final double preferredHumMax;
  final String qualityGrade;
  final String currentStatus; // registered, in_transit, delivered, spoiled
  final String originAddress;
  final double originLat;
  final double originLng;
  final String destinationAddress;
  final double destLat;
  final double destLng;
  final String? activeShipmentId;

  const CropBatchModel({
    required this.batchId,
    required this.cropName,
    required this.cropCategory,
    required this.quantity,
    required this.unit,
    required this.farmerId,
    this.farmId,
    required this.harvestDate,
    required this.expectedShelfLifeHours,
    required this.preferredTempMin,
    required this.preferredTempMax,
    required this.preferredHumMin,
    required this.preferredHumMax,
    required this.qualityGrade,
    required this.currentStatus,
    required this.originAddress,
    required this.originLat,
    required this.originLng,
    required this.destinationAddress,
    required this.destLat,
    required this.destLng,
    this.activeShipmentId,
  });

  factory CropBatchModel.fromMap(Map<String, dynamic> map, String id) {
    final prefTemp = map['preferredTemperature'] as Map<String, dynamic>?;
    final prefHum = map['preferredHumidity'] as Map<String, dynamic>?;
    final origin = map['origin'] as Map<String, dynamic>?;
    final dest = map['destination'] as Map<String, dynamic>?;

    return CropBatchModel(
      batchId: id,
      cropName: map['cropName'] ?? 'Tomato',
      cropCategory: map['cropCategory'] ?? 'Vegetable',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1000.0,
      unit: map['unit'] ?? 'kg',
      farmerId: map['farmerId'] ?? 'user_farmer',
      farmId: map['farmId'],
      harvestDate: map['harvestDate'] ?? '2026-09-16',
      expectedShelfLifeHours: (map['expectedShelfLifeHours'] as num?)?.toDouble() ?? 96.0,
      preferredTempMin: (prefTemp?['min'] as num?)?.toDouble() ?? 18.0,
      preferredTempMax: (prefTemp?['max'] as num?)?.toDouble() ?? 22.0,
      preferredHumMin: (prefHum?['min'] as num?)?.toDouble() ?? 60.0,
      preferredHumMax: (prefHum?['max'] as num?)?.toDouble() ?? 75.0,
      qualityGrade: map['qualityGrade'] ?? 'A',
      currentStatus: map['currentStatus'] ?? 'registered',
      originAddress: origin?['address'] ?? 'Nashik, Maharashtra',
      originLat: (origin?['latitude'] as num?)?.toDouble() ?? 19.9975,
      originLng: (origin?['longitude'] as num?)?.toDouble() ?? 73.7898,
      destinationAddress: dest?['address'] ?? 'APMC Vashi, Mumbai',
      destLat: (dest?['latitude'] as num?)?.toDouble() ?? 19.0760,
      destLng: (dest?['longitude'] as num?)?.toDouble() ?? 72.8777,
      activeShipmentId: map['activeShipmentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'cropCategory': cropCategory,
      'quantity': quantity,
      'unit': unit,
      'farmerId': farmerId,
      'farmId': farmId,
      'harvestDate': harvestDate,
      'expectedShelfLifeHours': expectedShelfLifeHours,
      'preferredTemperature': {'min': preferredTempMin, 'max': preferredTempMax},
      'preferredHumidity': {'min': preferredHumMin, 'max': preferredHumMax},
      'qualityGrade': qualityGrade,
      'currentStatus': currentStatus,
      'origin': {
        'address': originAddress,
        'latitude': originLat,
        'longitude': originLng,
      },
      'destination': {
        'address': destinationAddress,
        'latitude': destLat,
        'longitude': destLng,
      },
      'activeShipmentId': activeShipmentId,
    };
  }
}
