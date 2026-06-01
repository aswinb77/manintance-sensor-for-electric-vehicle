import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<Map<String, dynamic>> _alertStream;

  @override
  void initState() {
    super.initState();
    _alertStream = _firebaseService.getAlertsStream();
  }

  Future<void> _refreshAlerts() async {
    setState(() {
      _alertStream = _firebaseService.getAlertsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAlerts,
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _alertStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertData = snapshot.data ?? {
            'isCritical': false,
            'status': 'NORMAL',
            'confidence': 0.0,
            'message': 'All systems are operating normally.',
            'timestamp': DateTime.now().toIso8601String(),
          };

          final isCritical = alertData['isCritical'] as bool? ?? false;
          final confidence = (alertData['confidence'] as num?)?.toDouble() ?? 0.0;
          final message = alertData['message']?.toString() ?? 'No issues detected';
          final status = alertData['status']?.toString() ?? 'NORMAL';
          final timestamp = alertData['timestamp']?.toString() ?? DateTime.now().toIso8601String();

          final accent = isCritical ? const Color(0xFFE53935) : const Color(0xFF2E7D32);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero safety banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCritical
                          ? const [Color(0xFFFFEAEA), Color(0xFFFFF5F5)]
                          : const [Color(0xFFEAFBF0), Color(0xFFF5FFF8)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              isCritical ? Icons.crisis_alert : Icons.verified_user,
                              color: accent,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Safety Hub',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCritical
                                      ? 'Immediate attention required'
                                      : 'Vehicle safety is stable',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // quick stats
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Status',
                        status,
                        Icons.shield,
                        accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Confidence',
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        Icons.analytics,
                        const Color(0xFF3652B5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  'Alert Insight',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _timelineTile(Icons.sensors, 'Sensor anomaly detected', accent),
                      _timelineDivider(),
                      _timelineTile(Icons.psychology_alt, 'AI confidence score evaluated', const Color(0xFF3652B5)),
                      _timelineDivider(),
                      _timelineTile(Icons.access_time, _formatTimestamp(timestamp), Colors.grey.shade700),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 14,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _timelineTile(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        )
      ],
    );
  }

  Widget _timelineDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: Colors.grey.shade200, height: 1),
      );

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return 'Updated ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }
}
