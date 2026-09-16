class LiveTelemetryModel {
  final String batchId;
  final double latitude;
  final double longitude;
  final double temperature;
  final double humidity;
  final double speed;
  final int battery;
  final String deviceStatus;
  final bool anomalyFlag;
  final int timestamp;

  const LiveTelemetryModel({
    required this.batchId,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.humidity,
    required this.speed,
    required this.battery,
    required this.deviceStatus,
    required this.anomalyFlag,
    required this.timestamp,
  });

  factory LiveTelemetryModel.fromMap(Map<dynamic, dynamic> map) {
    return LiveTelemetryModel(
      batchId: map['batchId']?.toString() ?? 'AGRI-2026-TOM-000124',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 19.4521,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 73.3421,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 20.8,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 67.5,
      speed: (map['speed'] as num?)?.toDouble() ?? 48.0,
      battery: (map['battery'] as num?)?.toInt() ?? 94,
      deviceStatus: map['deviceStatus']?.toString() ?? 'online',
      anomalyFlag: map['anomalyFlag'] == true,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
