class RouteOptionModel {
  final String routeId;
  final String routeName;
  final double distanceKm;
  final int etaMinutes;
  final double costInr;
  final double spoilageRisk;
  final double delayRisk;
  final double overallScore;
  final bool isRecommended;
  final List<String> highlights;
  final List<String> coldStoragePoints;

  const RouteOptionModel({
    required this.routeId,
    required this.routeName,
    required this.distanceKm,
    required this.etaMinutes,
    required this.costInr,
    required this.spoilageRisk,
    required this.delayRisk,
    required this.overallScore,
    required this.isRecommended,
    required this.highlights,
    required this.coldStoragePoints,
  });

  factory RouteOptionModel.fromJson(Map<String, dynamic> json) {
    return RouteOptionModel(
      routeId: json['routeId'] ?? 'ROUTE-01',
      routeName: json['routeName'] ?? 'Corridor Route',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 160.0,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 240,
      costInr: (json['costInr'] as num?)?.toDouble() ?? 2500.0,
      spoilageRisk: (json['spoilageRisk'] as num?)?.toDouble() ?? 20.0,
      delayRisk: (json['delayRisk'] as num?)?.toDouble() ?? 15.0,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 25.0,
      isRecommended: json['isRecommended'] == true,
      highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      coldStoragePoints: (json['coldStoragePointsEnRoute'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
