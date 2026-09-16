import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class GoogleMapView extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String originName;
  final String destName;
  final double currentSpeed;
  final bool isBreached;
  final double height;

  const GoogleMapView({
    super.key,
    required this.currentLat,
    required this.currentLng,
    this.originLat = 19.9975,
    this.originLng = 73.7898,
    this.destLat = 19.0760,
    this.destLng = 72.8777,
    this.originName = 'Nashik Farm Hub',
    this.destName = 'APMC Market Vashi',
    this.currentSpeed = 48.5,
    this.isBreached = false,
    this.height = 240,
  });

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> with SingleTickerProviderStateMixin {
  int _zoom = 10;
  String _mapType = 'roadmap'; // roadmap, satellite, terrain
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _buildStaticMapUrl() {
    final apiKey = AppConstants.googleMapsApiKey;
    final lat = widget.currentLat;
    final lng = widget.currentLng;
    final oLat = widget.originLat;
    final oLng = widget.originLng;
    final dLat = widget.destLat;
    final dLng = widget.destLng;

    // Google Maps Dark Style parameters for Roadmap
    final darkStyle = _mapType == 'roadmap'
        ? '&style=element:geometry%7Ccolor:0x1b202c'
          '&style=element:labels.text.stroke%7Ccolor:0x1b202c'
          '&style=element:labels.text.fill%7Ccolor:0x8ec3b9'
          '&style=feature:water%7Celement:geometry%7Ccolor:0x0e1726'
          '&style=feature:road%7Celement:geometry%7Ccolor:0x2d3748'
          '&style=feature:road.highway%7Celement:geometry%7Ccolor:0x3b82f6'
        : '';

    // Markers: Origin (Green), Destination (Blue), Live Truck (Red/Amber)
    final markers = '&markers=color:0x00E676%7Clabel:O%7C$oLat,$oLng'
        '&markers=color:0x29B6F6%7Clabel:D%7C$dLat,$dLng'
        '&markers=color:0xFF5252%7Clabel:T%7C$lat,$lng';

    // Route Polyline Corridor
    final path = '&path=color:0x00E676CC%7Cweight:4%7C$oLat,$oLng%7C$lat,$lng%7C$dLat,$dLng';

    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$lat,$lng&zoom=$_zoom&size=640x360&scale=2'
        '&maptype=$_mapType'
        '$markers$path$darkStyle&key=$apiKey';
  }

  Future<void> _openInExternalGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${widget.originLat},${widget.originLng}'
      '&destination=${widget.destLat},${widget.destLng}'
      '&waypoints=${widget.currentLat},${widget.currentLng}'
      '&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coordinates: ${widget.currentLat.toStringAsFixed(4)}, ${widget.currentLng.toStringAsFixed(4)}'),
            backgroundColor: AppTheme.darkSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isBreached ? AppTheme.criticalRed : AppTheme.darkBorder,
          width: widget.isBreached ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // 1. Google Maps Static Image or Fallback Radar
            Positioned.fill(
              child: Image.network(
                _buildStaticMapUrl(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildRadarCanvasFallback();
                },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Stack(
                          children: [
                            _buildRadarCanvasFallback(),
                            const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),

            // 2. Animated Center Pulsing Radar on Live Truck
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.8);
                  final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (widget.isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen).withOpacity(opacity * 0.8),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: widget.isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen).withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Top Gradient with Live Telemetry Pill
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBg.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.isBreached ? AppTheme.criticalRed : AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.currentLat.toStringAsFixed(4)}° N, ${widget.currentLng.toStringAsFixed(4)}° E',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Google Maps Live Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Google Maps',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. Map View Controls (Zoom in/out, Map Type switch, External Navigation)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Map Type Toggle
                  _controlButton(
                    icon: _mapType == 'roadmap' ? Icons.layers_outlined : Icons.satellite_alt,
                    tooltip: 'Toggle Satellite / Roadmap',
                    onTap: () {
                      setState(() {
                        _mapType = _mapType == 'roadmap' ? 'satellite' : 'roadmap';
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  // Zoom In
                  _controlButton(
                    icon: Icons.add,
                    tooltip: 'Zoom In',
                    onTap: () {
                      if (_zoom < 16) setState(() => _zoom++);
                    },
                  ),
                  const SizedBox(width: 6),
                  // Zoom Out
                  _controlButton(
                    icon: Icons.remove,
                    tooltip: 'Zoom Out',
                    onTap: () {
                      if (_zoom > 6) setState(() => _zoom--);
                    },
                  ),
                  const SizedBox(width: 6),
                  // Open in External Google Maps Directions
                  _controlButton(
                    icon: Icons.open_in_new,
                    tooltip: 'Open in Google Maps Navigation',
                    color: const Color(0xFF1A73E8),
                    onTap: _openInExternalGoogleMaps,
                  ),
                ],
              ),
            ),

            // 5. Bottom Left: Origin ➔ Destination Corridor Summary
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, size: 12, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.currentSpeed.toInt()} km/h',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Colors.white38)),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.originName} ➔ ${widget.destName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color ?? AppTheme.darkBg.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRadarCanvasFallback() {
    final z = _zoom.clamp(6, 13);
    final n = math.pow(2.0, z).toDouble();
    final x = ((widget.currentLng + 180.0) / 360.0 * n).floor();
    final latRad = widget.currentLat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    final tileUrl = 'https://basemaps.cartocdn.com/dark_all/$z/$x/$y.png';

    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            tileUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.darkSurface,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _MapGridPainter(),
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Route corridor line
    final routePaint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.5)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.35, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.65, size.width * 0.85, size.height * 0.25);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
