import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sahayatri/core/cache/local_db.dart';
import 'package:sahayatri/features/safar_rakshak/haversine_engine.dart';

/// GPS tracking service for Safar Rakshak.
/// Handles location permissions, background tracking, and breadcrumb recording.
class GPSService {
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;

  double? _destinationLat;
  double? _destinationLon;
  int? _yatraId;

  bool get isTracking => _positionSubscription != null;

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    return permission != LocationPermission.deniedForever;
  }

  Future<void> startTracking({
    required int yatraId,
    required double destinationLat,
    required double destinationLon,
  }) async {
    if (!await checkPermission()) return;

    _yatraId = yatraId;
    _destinationLat = destinationLat;
    _destinationLon = destinationLon;

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position position) {
    _positionController.add(position);

    // Store breadcrumb locally
    if (_yatraId != null) {
      LocalDB.addBreadcrumb({
        'yatra_id': _yatraId,
        'lat': position.latitude,
        'lon': position.longitude,
        'snapped_lat': position.latitude,
        'snapped_lon': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Check geofence for "Utarne ki alarm"
    if (_destinationLat != null && _destinationLon != null) {
      final isNear = HaversineEngine.isWithinGeofence(
        position.latitude,
        position.longitude,
        _destinationLat!,
        _destinationLon!,
        radiusKm: 5.0,
      );

      if (isNear) {
        _triggerArrivalAlert();
      }
    }
  }

  void _triggerArrivalAlert() {
    // TODO: trigger local notification for "Utarne ki alarm"
    print('ARRIVAL ALERT: Within 5km of destination!');
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _yatraId = null;
    _destinationLat = null;
    _destinationLon = null;
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
