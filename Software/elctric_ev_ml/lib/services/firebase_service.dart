import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Stream<SensorData> getSensorDataStream() {
    return _database.child('motor_monitor').onValue.map((event) {
      final data = event.snapshot.value;
      
      if (data == null) {
        return SensorData(
          motorHealth: 0,
          batteryHealth: 0,
          brakeHealth: 0,
          motorTemp: 0,
          batteryTemp: 0,
          batteryVoltage: 0,
          batteryCurrent: 0,
          vibrationLevel: 0,
          timestamp: DateTime.now(),
        );
      }

      // Handle different data types safely
      Map<dynamic, dynamic> dataMap;
      if (data is Map) {
        dataMap = data;
      } else {
        // If data is not a map, create a default map
        dataMap = <dynamic, dynamic>{};
      }

      // The brake_wear data is at the root level, not nested
      // So we use the entire dataMap as brakeWearData
      return SensorData(
        motorHealth: (dataMap['motor_health'] as num?)?.toDouble() ?? 0.0,
        batteryHealth: 0, // Removed battery percentage calculation
        brakeHealth: _calculateBrakeHealth(dataMap), // Pass entire dataMap
        motorTemp: (dataMap['temperature'] as num?)?.toDouble() ?? 0.0,
        batteryTemp: 0.0, // Removed battery temperature
        batteryVoltage: (dataMap['voltage'] as num?)?.toDouble() ?? 0.0,
        batteryCurrent: (dataMap['current'] as num?)?.toDouble() ?? 0.0,
        vibrationLevel: (dataMap['vibration'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.now(),
        status: dataMap['result']?.toString() ?? 'NORMAL',
      );
    });
  }

  Stream<Map<String, dynamic>> getCriticalAlertStream() {
    return _database.child('motor_monitor').onValue.map((event) {
      final data = event.snapshot.value;
      
      if (data == null) {
        return {
          'isCritical': false,
          'status': 'NORMAL',
          'confidence': 0.0,
          'message': 'System operating normally'
        };
      }

      // Handle different data types safely
      Map<dynamic, dynamic> dataMap;
      if (data is Map) {
        dataMap = data;
      } else {
        // If data is not a map, create a default map with correct structure
        dataMap = <dynamic, dynamic>{
          'result': 'NORMAL',
          'critical': 0.0,
          'warning': 0.0,
          'normal': 1.0
        };
      }

      final result = dataMap['result']?.toString() ?? 'NORMAL';
      final confidence = _calculateConfidence(dataMap);
      final isCritical = result.toUpperCase() == 'CRITICAL';

      return {
        'isCritical': isCritical,
        'status': result,
        'confidence': confidence,
        'message': isCritical 
          ? 'Critical vehicle health issue detected!'
          : 'System operating normally',
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  double _calculateConfidence(Map<dynamic, dynamic> data) {
    // The brake_wear values are at the root level of the data map
    final critical = (data['critical'] as num?)?.toDouble() ?? 0.0;
    final warning = (data['warning'] as num?)?.toDouble() ?? 0.0;
    final normal = (data['normal'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate confidence as the highest probability among the three conditions
    // This represents the model's confidence in its prediction
    final maxConfidence = [critical, warning, normal].reduce((a, b) => a > b ? a : b);
    
    return maxConfidence.clamp(0.0, 1.0);
  }

  Stream<Map<String, dynamic>> getAlertsStream() {
    return getCriticalAlertStream();
  }

  double _calculateBrakeHealth(Map<dynamic, dynamic> data) {
    // The brake_wear value is 0 (low) or 1 (safe)
    final brakeWear = (data['brake_wear'] as num?)?.toDouble() ?? 0.0;
    
    // Return the brake_wear value directly (0 or 1)
    return brakeWear.clamp(0.0, 1.0);
  }

  Future<void> updateChargingSettings(Map<String, dynamic> settings) async {
    await _database.child('charging_settings').update(settings);
  }

  Future<Map<String, dynamic>?> getChargingSettings() async {
    final snapshot = await _database.child('charging_settings').get();
    return snapshot.value as Map<String, dynamic>?;
  }
}
