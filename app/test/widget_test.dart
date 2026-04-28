import 'package:flutter_test/flutter_test.dart';
import 'package:sahayatri/features/safar_rakshak/haversine_engine.dart';

void main() {
  group('HaversineEngine', () {
    test('calculates distance between two known points', () {
      // Mumbai to Delhi ~ 1148 km
      final distance = HaversineEngine.distanceKm(
        19.0760, 72.8777, // Mumbai
        28.6139, 77.2090, // Delhi
      );
      expect(distance, greaterThan(1100));
      expect(distance, lessThan(1200));
    });

    test('returns zero for same point', () {
      final distance = HaversineEngine.distanceKm(
        28.6139, 77.2090,
        28.6139, 77.2090,
      );
      expect(distance, equals(0.0));
    });

    test('geofence check works', () {
      // Point within 5km of destination
      final isNear = HaversineEngine.isWithinGeofence(
        28.6140, 77.2091,
        28.6139, 77.2090,
        radiusKm: 5.0,
      );
      expect(isNear, isTrue);

      // Point far from destination
      final isFar = HaversineEngine.isWithinGeofence(
        19.0760, 72.8777, // Mumbai
        28.6139, 77.2090, // Delhi
        radiusKm: 5.0,
      );
      expect(isFar, isFalse);
    });

    test('adaptive polling interval varies with distance', () {
      expect(
        HaversineEngine.adaptivePollingInterval(200).inMinutes,
        equals(5),
      );
      expect(
        HaversineEngine.adaptivePollingInterval(3).inSeconds,
        equals(30),
      );
    });
  });
}
