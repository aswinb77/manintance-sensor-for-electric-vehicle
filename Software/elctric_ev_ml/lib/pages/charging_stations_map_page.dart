import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/charging_station.dart';
import '../services/map_navigation_service.dart';

class ChargingStationsMapPage extends StatefulWidget {
  const ChargingStationsMapPage({
    super.key,
    required this.stations,
    required this.currentLocation,
    this.selectedStation,
  });

  final List<ChargingStation> stations;
  final LatLng currentLocation;
  final ChargingStation? selectedStation;

  @override
  State<ChargingStationsMapPage> createState() =>
      _ChargingStationsMapPageState();
}

class _ChargingStationsMapPageState extends State<ChargingStationsMapPage> {
  GoogleMapController? _mapController;
  ChargingStation? _selectedStation;
  
  // Ultra minimal black map
  final String _darkMapStyle = '''
  [
    {
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "administrative",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "landscape",
      "stylers": [{"color": "#000000"}]
    },
    {
      "featureType": "poi",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#111111"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#111111"}]
    },
    {
      "featureType": "transit",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "water",
      "stylers": [{"color": "#000000"}]
    },
    {
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.selectedStation;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle(_darkMapStyle);
    
    if (_selectedStation != null) {
      _focusOnStation(_selectedStation!);
    }
  }

  void _focusOnStation(ChargingStation station) {
    setState(() => _selectedStation = station);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(station.latitude, station.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  void _centerOnUser() {
    setState(() => _selectedStation = null);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: widget.currentLocation,
          zoom: 13,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // User Location Marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: widget.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        zIndex: 2,
      ),
    );

    // Station Markers
    for (final station in widget.stations) {
      final isSelected = _selectedStation?.id == station.id;
      
      markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _focusOnStation(station),
          zIndex: isSelected ? 1 : 0,
        ),
      );
    }
    return markers;
  }
  
  Set<Polyline> _buildPolylines() {
    if (_selectedStation == null) return {};
    
    // Create a straight "tactical" red line to the station
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          widget.currentLocation,
          LatLng(_selectedStation!.latitude, _selectedStation!.longitude),
        ],
        color: const Color(0xFF3B82F6), // Strong Blue Route
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)], // dotted route
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: widget.currentLocation,
                zoom: 13,
              ),
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // top glass bar
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(10, 10, 10, 0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.ev_station,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EV Tactical Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap any station to locate',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _centerOnUser,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            if (_selectedStation != null)
              Positioned(
                left: 18,
                right: 18,
                bottom: 22,
                child: _buildStationPanel(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationPanel() {
    final station = _selectedStation!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.45),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.electric_bolt,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            station.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => MapNavigationService.openExternalMap(station),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Open Navigation'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
