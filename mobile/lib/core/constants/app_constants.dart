class AppConstants {
  static const String appName = 'AgriChain AI';
  static const String appTagline = 'AI-Powered Agricultural Supply Chain Intelligence';

  // FastAPI Base URL (Local emulator/device default or desktop)
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // Google Maps API Key (Dedicated Maps API key on agrichain-ai-hackathon)
  static const String googleMapsApiKey = 'AIzaSyAoII5Nbw6q9woVYFgeTJ-CtS31n6dwHPQ';

  // Demo Fallback Flag
  static const bool useMockFallbackIfFirebaseOffline = true;

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleFarmer = 'farmer';
  static const String roleTransporter = 'transporter';
  static const String roleWarehouseManager = 'warehouse_manager';
  static const String roleBuyer = 'buyer';

  // Crop list
  static const List<String> supportedCrops = [
    'Tomato',
    'Grapes',
    'Pomegranate',
    'Banana',
    'Milk',
    'Greens',
  ];
}
