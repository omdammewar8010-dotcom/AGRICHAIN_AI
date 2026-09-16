import '../core/network/api_client.dart';
import '../models/route_model.dart';

class RouteRepository {
  final ApiClient _apiClient;

  RouteRepository(this._apiClient);

  Future<List<RouteOptionModel>> getOptimizedRoutes({
    double timeWeight = 0.35,
    double costWeight = 0.25,
    double riskWeight = 0.40,
    double currentTemp = 21.0,
    double currentDelay = 0.0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/routes/optimize',
        data: {
          'origin': {'latitude': 19.9975, 'longitude': 73.7898, 'name': 'Nashik Farm Hub'},
          'destination': {'latitude': 19.0760, 'longitude': 72.8777, 'name': 'APMC Market Vashi'},
          'cropType': 'Tomato',
          'cargoWeightKg': 2000.0,
          'currentTemperature': currentTemp,
          'currentDelayMinutes': currentDelay,
          'timeWeight': timeWeight,
          'costWeight': costWeight,
          'riskWeight': riskWeight,
        },
      );
      final list = (response.data['routes'] as List)
          .map((r) => RouteOptionModel.fromJson(r))
          .toList();
      return list;
    } catch (_) {
      // Fallback data
      return [
        const RouteOptionModel(
          routeId: 'ROUTE-EXPRESS-01',
          routeName: 'Corridor A: Samruddhi Express Highway (Optimal Freshness)',
          distanceKm: 178.2,
          etaMinutes: 165,
          costInr: 3250.0,
          spoilageRisk: 12.0,
          delayRisk: 15.0,
          overallScore: 21.4,
          isRecommended: true,
          highlights: ['Zero Ghat bottlenecks', 'Continuous high-speed airflow', 'Road Quality 0.95'],
          coldStoragePoints: ['Igatpuri Cold Hub (KM 45)', 'Bhiwandi Integrated Logistics Park (KM 130)'],
        ),
        const RouteOptionModel(
          routeId: 'ROUTE-STANDARD-02',
          routeName: 'Corridor B: NH-160 via Kasara Ghat',
          distanceKm: 165.0,
          etaMinutes: 220,
          costInr: 2850.0,
          spoilageRisk: 38.0,
          delayRisk: 42.0,
          overallScore: 36.8,
          isRecommended: false,
          highlights: ['Direct distance', 'Ghat incline congestion', 'Moderate road bumps'],
          coldStoragePoints: ['Ghoti APMC Storage (KM 32)', 'Kalyan Agro Depot (KM 140)'],
        ),
        const RouteOptionModel(
          routeId: 'ROUTE-ECONOMY-03',
          routeName: 'Corridor C: Rural State Bypass (Lowest Toll)',
          distanceKm: 194.5,
          etaMinutes: 305,
          costInr: 2150.0,
          spoilageRisk: 52.0,
          delayRisk: 55.0,
          overallScore: 48.2,
          isRecommended: false,
          highlights: ['Minimal toll charges', 'Rough rural pavement', 'Higher ambient vibration'],
          coldStoragePoints: ['Murbad Agri Cooperative (KM 95)'],
        ),
      ];
    }
  }
}
