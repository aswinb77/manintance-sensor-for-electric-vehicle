class SensorData {
  final double motorHealth;
  final double batteryHealth;
  final double brakeHealth;
  final double motorTemp;
  final double batteryTemp;
  final double batteryVoltage;
  final double batteryCurrent;
  final double vibrationLevel;
  final DateTime timestamp;
  final String? status;

  SensorData({
    required this.motorHealth,
    required this.batteryHealth,
    required this.brakeHealth,
    required this.motorTemp,
    required this.batteryTemp,
    required this.batteryVoltage,
    required this.batteryCurrent,
    required this.vibrationLevel,
    required this.timestamp,
    this.status,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      motorHealth: (json['motorHealth'] as num?)?.toDouble() ?? 0.0,
      batteryHealth: (json['batteryHealth'] as num?)?.toDouble() ?? 0.0,
      brakeHealth: (json['brakeHealth'] as num?)?.toDouble() ?? 0.0,
      motorTemp: (json['motorTemp'] as num?)?.toDouble() ?? 0.0,
      batteryTemp: (json['batteryTemp'] as num?)?.toDouble() ?? 0.0,
      batteryVoltage: (json['batteryVoltage'] as num?)?.toDouble() ?? 0.0,
      batteryCurrent: (json['batteryCurrent'] as num?)?.toDouble() ?? 0.0,
      vibrationLevel: (json['vibrationLevel'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'motorHealth': motorHealth,
      'batteryHealth': batteryHealth,
      'brakeHealth': brakeHealth,
      'motorTemp': motorTemp,
      'batteryTemp': batteryTemp,
      'batteryVoltage': batteryVoltage,
      'batteryCurrent': batteryCurrent,
      'vibrationLevel': vibrationLevel,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}