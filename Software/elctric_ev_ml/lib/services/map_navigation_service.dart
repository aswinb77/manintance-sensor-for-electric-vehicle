import 'package:url_launcher/url_launcher.dart';
import '../models/charging_station.dart';

class MapNavigationService {
  static Future<void> showNavigationMap(
    ChargingStation station,
    double userLat,
    double userLon,
  ) async {
    try {
      // Open external map directly (simpler implementation)
      await openExternalMap(station);
    } catch (e) {
      print('Error showing navigation map: $e');
    }
  }

  static Future<void> openExternalMap(ChargingStation station) async {
    try {
      // Use Google Maps URL for better compatibility
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback to OpenStreetMap
        final osmUrl = 'https://www.openstreetmap.org/directions?engine=osrm_car&route=${station.latitude},${station.longitude}';
        if (await canLaunchUrl(Uri.parse(osmUrl))) {
          await launchUrl(Uri.parse(osmUrl), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('Error opening external map: $e');
    }
  }
}
