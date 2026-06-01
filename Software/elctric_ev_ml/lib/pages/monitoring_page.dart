import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<SensorData> _sensorDataStream;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sensorDataStream = _firebaseService.getSensorDataStream();
  }

  Future<void> _refreshData() async {
    setState(() {
      _sensorDataStream = _firebaseService.getSensorDataStream();
      _lastUpdated = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: StreamBuilder<SensorData>(
        stream: _sensorDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No sensor data available'));
          }

          final data = snapshot.data!;
          final statusColor = _getStatusColor(data.status);
          _lastUpdated = DateTime.now();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // HERO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3652B5), Color(0xFF30489D)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle Health',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Simple real-time battery and safety overview',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              data.status ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Updated ${_formatTime(_lastUpdated)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // CONTENT
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Metrics',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _metricCard('Motor Temperature', '${data.motorTemp.toStringAsFixed(1)}°C', Icons.thermostat, const Color(0xFFFFF1F1)),
                          _metricCard('Battery Voltage', '${data.batteryVoltage.toStringAsFixed(1)} V', Icons.bolt, const Color(0xFFFFF8E8)),
                          _metricCard('Battery Current', '${data.batteryCurrent.toStringAsFixed(1)} A', Icons.electric_car, const Color(0xFFEFF8FF)),
                          _metricCard('Vibration', '${data.vibrationLevel.toStringAsFixed(2)}', Icons.graphic_eq, const Color(0xFFF3F0FF)),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Brake Condition',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _brakeHealthCard(data.brakeHealth),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF3652B5)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          )
        ],
      ),
    );
  }

  Widget _brakeHealthCard(double health) {
    final percent = (health * 100).clamp(0, 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14204F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$percent% Healthy',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            percent > 70 ? 'Brake system is in good condition' : 'Brake service needed soon',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: health.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:$minute $suffix';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'NORMAL':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
