class ShipmentModel {
  final String shipmentId;
  final String batchId;
  final String transporterId;
  final String vehicleId;
  final String iotDeviceId;
  final String status; // assigned, in_transit, delivered, delayed
  final String originName;
  final String destinationName;
  final double currentLat;
  final double currentLng;
  final double distanceKm;
  final double remainingDistanceKm;
  final double currentSpeed;
  final double delayMinutes;
  final double spoilageRisk;
  final double overallRisk;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final String? activeRouteId;

  const ShipmentModel({
    required this.shipmentId,
    required this.batchId,
    required this.transporterId,
    required this.vehicleId,
    required this.iotDeviceId,
    required this.status,
    required this.originName,
    required this.destinationName,
    required this.currentLat,
    required this.currentLng,
    required this.distanceKm,
    required this.remainingDistanceKm,
    required this.currentSpeed,
    required this.delayMinutes,
    required this.spoilageRisk,
    required this.overallRisk,
    required this.riskLevel,
    this.activeRouteId,
  });

  factory ShipmentModel.fromMap(Map<String, dynamic> map, String id) {
    final curLoc = map['currentLocation'] as Map<String, dynamic>?;
    final orig = map['origin'] as Map<String, dynamic>?;
    final dest = map['destination'] as Map<String, dynamic>?;

    return ShipmentModel(
      shipmentId: id,
      batchId: map['batchId'] ?? '',
      transporterId: map['transporterId'] ?? '',
      vehicleId: map['vehicleId'] ?? 'MH-15-8842',
      iotDeviceId: map['iotDeviceId'] ?? 'ESP32-TRUCK-001',
      status: map['status'] ?? 'in_transit',
      originName: orig?['name'] ?? 'Nashik Farm Hub',
      destinationName: dest?['name'] ?? 'APMC Market Vashi',
      currentLat: (curLoc?['latitude'] as num?)?.toDouble() ?? 19.4521,
      currentLng: (curLoc?['longitude'] as num?)?.toDouble() ?? 73.3421,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 165.0,
      remainingDistanceKm: (map['remainingDistanceKm'] as num?)?.toDouble() ?? 75.0,
      currentSpeed: (map['currentSpeed'] as num?)?.toDouble() ?? 48.0,
      delayMinutes: (map['delayMinutes'] as num?)?.toDouble() ?? 0.0,
      spoilageRisk: (map['spoilageRisk'] as num?)?.toDouble() ?? 18.0,
      overallRisk: (map['overallRisk'] as num?)?.toDouble() ?? 22.0,
      riskLevel: map['riskLevel'] ?? 'LOW',
      activeRouteId: map['activeRouteId'],
    );
  }
}
