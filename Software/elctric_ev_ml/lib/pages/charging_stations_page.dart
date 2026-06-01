import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/charging_station.dart';
import '../services/location_service.dart';
import '../services/charging_station_service.dart';
import '../services/map_navigation_service.dart';
import 'charging_stations_map_page.dart';

class ChargingStationsPage extends StatefulWidget {
  const ChargingStationsPage({super.key});

  @override
  State<ChargingStationsPage> createState() => _ChargingStationsPageState();
}

class _ChargingStationsPageState extends State<ChargingStationsPage> {
  Position? _currentLocation;
  List<ChargingStation> _stations = [];
  List<ChargingStation> _filteredStations = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChargingStations();
    _searchController.addListener(_filterStations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChargingStations() async {
    setState(() => _isLoading = true);
    try {
      final location = await LocationService.getCurrentLocation();
      if (location == null) {
        _showErrorDialog('Location Error', 'Unable to get your current location. Please enable location services.');
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _currentLocation = location);
      final stations = await ChargingStationService.getNearbyChargingStations(location);

      setState(() {
        _stations = stations;
        _filteredStations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error', 'Failed to load charging stations: $e');
    }
  }

  void _filterStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStations = _stations.where((station) {
        return station.name.toLowerCase().contains(query) ||
            station.address.toLowerCase().contains(query) ||
            station.provider.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _openStationMap([ChargingStation? selectedStation]) async {
    if (_currentLocation == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChargingStationsMapPage(
          stations: _filteredStations.isNotEmpty ? _filteredStations : _stations,
          currentLocation: LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
          selectedStation: selectedStation,
        ),
      ),
    );
  }

  Future<void> _navigateToStation(ChargingStation station) async {
    if (_currentLocation == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigate to Station'),
        content: Text('Navigate to ${station.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MapNavigationService.showNavigationMap(
                station,
                _currentLocation!.latitude,
                _currentLocation!.longitude,
              );
            },
            child: const Text('Show Route'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              MapNavigationService.openExternalMap(station);
            },
            child: const Text('External Map'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'EXPLORE CHARGERS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search charging stations',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => _openStationMap(),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredStations.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _filteredStations.length,
                            itemBuilder: (context, index) {
                              return _buildStationCard(_filteredStations[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ev_station, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 18),
          Text(
            _stations.isEmpty
                ? 'No charging stations found nearby'
                : 'No stations match your filters',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          if (_stations.isEmpty)
            TextButton(
              onPressed: _loadChargingStations,
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Widget _buildStationCard(ChargingStation station) {
    final distanceParts = station.distance.split(' ');
    final distanceValue = distanceParts.isNotEmpty ? distanceParts.first : station.distance;
    final distanceUnit = distanceParts.length > 1 ? distanceParts.last.toUpperCase() : 'KM';

    Color accent;
    final provider = station.provider.toLowerCase();
    if (provider.contains('fast')) {
      accent = const Color(0xFF16A34A);
    } else if (provider.contains('ultra') || provider.contains('tata')) {
      accent = const Color(0xFF2563EB);
    } else if (provider.contains('ather') || provider.contains('type')) {
      accent = const Color(0xFFF59E0B);
    } else {
      accent = const Color(0xFFEF4444);
    }

    return InkWell(
      onTap: () => _openStationMap(station),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    distanceValue,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    distanceUnit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.provider.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _navigateToStation(station),
                    child: Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    station.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${station.availableSlots}/${station.totalSlots} slots • ${station.price}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tap station name to navigate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
