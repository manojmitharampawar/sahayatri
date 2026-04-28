import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sahayatri/features/safar_rakshak/gps_service.dart';
import 'package:sahayatri/features/safar_rakshak/haversine_engine.dart';

class SafarRakshakScreen extends StatefulWidget {
  const SafarRakshakScreen({super.key});

  @override
  State<SafarRakshakScreen> createState() => _SafarRakshakScreenState();
}

class _SafarRakshakScreenState extends State<SafarRakshakScreen> {
  final GPSService _gpsService = GPSService();
  Position? _currentPosition;
  double? _distanceToDestination;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _gpsService.positionStream.listen((position) {
      setState(() {
        _currentPosition = position;
        if (_isTracking) {
          // Example destination - would come from YatraCard
          _distanceToDestination = HaversineEngine.distanceKm(
            position.latitude,
            position.longitude,
            28.6139, // Delhi as example
            77.2090,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safar Rakshak')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isTracking ? Icons.gps_fixed : Icons.gps_off,
                      size: 48,
                      color: _isTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isTracking ? 'Tracking Active' : 'Tracking Off',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPosition != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Current Location'),
                  subtitle: Text(
                    '${_currentPosition!.latitude.toStringAsFixed(4)}, '
                    '${_currentPosition!.longitude.toStringAsFixed(4)}',
                  ),
                ),
              ),
            ],
            if (_distanceToDestination != null) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Distance to Destination'),
                  subtitle:
                      Text('${_distanceToDestination!.toStringAsFixed(1)} km'),
                ),
              ),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _toggleTracking,
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _gpsService.stopTracking();
      setState(() => _isTracking = false);
    } else {
      await _gpsService.startTracking(
        yatraId: 1,
        destinationLat: 28.6139,
        destinationLon: 77.2090,
      );
      setState(() => _isTracking = true);
    }
  }

  @override
  void dispose() {
    _gpsService.dispose();
    super.dispose();
  }
}
