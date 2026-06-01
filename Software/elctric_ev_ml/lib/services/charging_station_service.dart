import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/charging_station.dart';

class ChargingStationService {
  static Future<List<ChargingStation>> getNearbyChargingStations(
    Position currentLocation, {
    double radius = 50000,
  }) async {
    // Immediate return of highly realistic mock data around user's location
    await Future.delayed(const Duration(milliseconds: 500)); // slight realistic delay
    return _generateMockStations(currentLocation);
  }

  static List<ChargingStation> _generateMockStations(Position currentLocation) {
    final List<ChargingStation> stations = [];
    final random = Random();

    final providers = ['EV FastCharge', 'Tata Power EZ', 'Ather Grid', 'Zeon Charging', 'ChargePoint'];
    final names = ['City Center', 'Mall Plaza', 'Highway Stop', 'Tech Park', 'Green Valley'];

    // Generate 25 nearby stations within ~5-10 km radius
    for (int i = 0; i < 25; i++) {
        // Offset latitude and longitude slightly
        double latOffset = (random.nextDouble() - 0.5) * 0.1; // ~5km spread
        double lonOffset = (random.nextDouble() - 0.5) * 0.1;
        
        double lat = currentLocation.latitude + latOffset;
        double lon = currentLocation.longitude + lonOffset;

        final distanceMeters = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          lat,
          lon,
        );

        final provider = providers[random.nextInt(providers.length)];
        final isFast = random.nextBool();
        final capacity = random.nextInt(4) + 1; // 1 to 4

        stations.add(
            ChargingStation(
                id: 'mock_$i',
                name: '$provider ${names[random.nextInt(names.length)]}',
                address: 'Lat ${lat.toStringAsFixed(4)}, Lon ${lon.toStringAsFixed(4)}',
                latitude: lat,
                longitude: lon,
                distance: '${(distanceMeters / 1000).toStringAsFixed(1)} km',
                provider: provider,
                availableSlots: random.nextInt(capacity + 1),
                totalSlots: capacity,
                price: random.nextBool() ? 'Paid' : 'Free',
                isFastCharging: isFast,
                socketTypes: isFast ? ['Type2', 'CHAdeMO'] : ['Type2'],
                isOpen: true,
            )
        );
    }

    // Sort by distance exactly like original
    stations.sort((a, b) {
      final da = double.tryParse(a.distance.split(' ').first) ?? 9999;
      final db = double.tryParse(b.distance.split(' ').first) ?? 9999;
      return da.compareTo(db);
    });

    return stations;
  }
}