class ChargingStation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String distance;
  final String provider;
  final int availableSlots;
  final int totalSlots;
  final String price;
  final bool isFastCharging;
  final List<String> socketTypes;
  final bool isOpen;

  ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.provider,
    required this.availableSlots,
    required this.totalSlots,
    required this.price,
    required this.isFastCharging,
    this.socketTypes = const [],
    this.isOpen = true,
  });

  // For backward compatibility with existing code
  ChargingStation.fromLegacy({
    required this.name,
    required this.address,
    required this.distance,
    required this.provider,
    required this.availableSlots,
    required this.totalSlots,
    required this.price,
    required this.isFastCharging,
  }) : id = '',
       latitude = 0.0,
       longitude = 0.0,
       socketTypes = [],
       isOpen = true;

  @override
  String toString() {
    return 'ChargingStation(id: $id, name: $name, address: $address)';
  }
}
