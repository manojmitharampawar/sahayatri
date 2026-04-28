import 'dart:math';

/// Haversine formula for calculating great-circle distance between two
/// latitude/longitude points on Earth. Used for offline distance calculations
/// and geofence-based arrival alerts.
class HaversineEngine {
  static const double _earthRadiusKm = 6371.0;

  /// Calculate distance in kilometers between two coordinates.
  static double distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Calculate distance in meters.
  static double distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    return distanceKm(lat1, lon1, lat2, lon2) * 1000;
  }

  /// Check if a point is within the geofence radius (in km).
  static bool isWithinGeofence(
      double lat, double lon, double fenceLat, double fenceLon,
      {double radiusKm = 5.0}) {
    return distanceKm(lat, lon, fenceLat, fenceLon) <= radiusKm;
  }

  /// Determine adaptive polling interval based on distance to destination.
  /// Closer distances get more frequent GPS polls to save battery.
  static Duration adaptivePollingInterval(double distanceKm) {
    if (distanceKm > 100) return const Duration(minutes: 5);
    if (distanceKm > 50) return const Duration(minutes: 3);
    if (distanceKm > 20) return const Duration(minutes: 2);
    if (distanceKm > 5) return const Duration(minutes: 1);
    return const Duration(seconds: 30);
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
