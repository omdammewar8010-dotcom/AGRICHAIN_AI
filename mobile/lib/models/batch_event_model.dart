class BatchEventModel {
  final String eventId;
  final String batchId;
  final String? shipmentId;
  final String stage; // harvest, collection, transport, warehouse, retail
  final String type;
  final String locationName;
  final double latitude;
  final double longitude;
  final double temperature;
  final double humidity;
  final String performedBy;
  final String role;
  final String description;
  final String timestamp;

  const BatchEventModel({
    required this.eventId,
    required this.batchId,
    this.shipmentId,
    required this.stage,
    required this.type,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.humidity,
    required this.performedBy,
    required this.role,
    required this.description,
    required this.timestamp,
  });

  factory BatchEventModel.fromMap(Map<String, dynamic> map, String id) {
    final loc = map['location'] as Map<String, dynamic>?;
    return BatchEventModel(
      eventId: id,
      batchId: map['batchId'] ?? '',
      shipmentId: map['shipmentId'],
      stage: map['stage'] ?? 'harvest',
      type: map['type'] ?? 'checkpoint',
      locationName: loc?['address'] ?? 'Transit Location',
      latitude: (loc?['latitude'] as num?)?.toDouble() ?? 19.45,
      longitude: (loc?['longitude'] as num?)?.toDouble() ?? 73.34,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 21.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 66.0,
      performedBy: map['performedBy'] ?? 'Operator',
      role: map['role'] ?? 'farmer',
      description: map['description'] ?? '',
      timestamp: map['timestamp']?.toString() ?? '2026-09-16 08:30',
    );
  }
}
