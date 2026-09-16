class RiskFactorModel {
  final String factor;
  final double impact;
  final String? description;

  const RiskFactorModel({
    required this.factor,
    required this.impact,
    this.description,
  });

  factory RiskFactorModel.fromJson(Map<String, dynamic> json) {
    return RiskFactorModel(
      factor: json['factor'] ?? 'Environmental Baseline',
      impact: (json['impact'] as num?)?.toDouble() ?? 10.0,
      description: json['description'],
    );
  }
}

class RiskPredictionModel {
  final double spoilageRisk;
  final double delayRisk;
  final double anomalyRisk;
  final double overallRisk;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final List<RiskFactorModel> factors;
  final String recommendedAction;
  final String calculatedAt;

  const RiskPredictionModel({
    required this.spoilageRisk,
    required this.delayRisk,
    required this.anomalyRisk,
    required this.overallRisk,
    required this.riskLevel,
    required this.factors,
    required this.recommendedAction,
    required this.calculatedAt,
  });

  factory RiskPredictionModel.fromJson(Map<String, dynamic> json) {
    final factorsRaw = (json['factors'] as List?) ?? [];
    return RiskPredictionModel(
      spoilageRisk: (json['spoilageRisk'] as num?)?.toDouble() ?? 15.0,
      delayRisk: (json['delayRisk'] as num?)?.toDouble() ?? 10.0,
      anomalyRisk: (json['anomalyRisk'] as num?)?.toDouble() ?? 5.0,
      overallRisk: (json['overallRisk'] as num?)?.toDouble() ?? 12.0,
      riskLevel: json['riskLevel'] ?? 'LOW',
      factors: factorsRaw.map((f) => RiskFactorModel.fromJson(f as Map<String, dynamic>)).toList(),
      recommendedAction: json['recommendedAction'] ?? 'Optimal conditions; maintain schedule.',
      calculatedAt: json['calculatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}
