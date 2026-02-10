enum DayOfWeek {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday;

  String toJson() => name;
  static DayOfWeek fromJson(String json) =>
      DayOfWeek.values.firstWhere((e) => e.name == json);
}

enum TransportStatus {
  PENDING,
  ON_BOARD,
  DROPPED_OFF,
  SELF_TRAVEL,
  ABSENT;

  String toJson() => name;
  static TransportStatus fromJson(String json) => TransportStatus.values
      .firstWhere((e) => e.name == json, orElse: () => TransportStatus.PENDING);
}

class HealthCheckData {
  final String healthCondition; // "Good", "Not Good", "Diarrhea"
  final double temperature; // Body temperature in °C
  final String timestamp; // When the health check was recorded

  HealthCheckData({
    required this.healthCondition,
    required this.temperature,
    required this.timestamp,
  });

  factory HealthCheckData.fromJson(Map<String, dynamic> json) {
    return HealthCheckData(
      healthCondition: json['healthCondition'] ?? '',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'healthCondition': healthCondition,
      'temperature': temperature,
      'timestamp': timestamp,
    };
  }
}

class Employee {
  final String id;
  final String serialNumber;
  final String name;
  final String phoneNumber;
  final String pickupLocation;
  final String company;
  final String time;
  final String dropOffTime;
  final DayOfWeek day;
  final List<TransportStatus> weeklyPickupStatus;
  final List<TransportStatus> weeklyDropoffStatus;
  final List<HealthCheckData?>
  weeklyHealthChecks; // Health data for each week (5 weeks)
  final String lastUpdated;

  Employee({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.phoneNumber,
    required this.pickupLocation,
    required this.company,
    required this.time,
    required this.dropOffTime,
    required this.day,
    required this.weeklyPickupStatus,
    required this.weeklyDropoffStatus,
    required this.weeklyHealthChecks,
    required this.lastUpdated,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Migration Logic:
    // If 'weeklyPickupStatus' exists, use it.
    // If not, use 'weeklyStatus' (legacy) as pickup status.
    // Default to PENDING.

    List<TransportStatus> parseStatusList(dynamic list) {
      if (list is List) {
        return list.map((e) => TransportStatus.fromJson(e.toString())).toList();
      }
      return List.filled(5, TransportStatus.PENDING);
    }

    final pickupList = json['weeklyPickupStatus'] != null
        ? parseStatusList(json['weeklyPickupStatus'])
        : (json['weeklyStatus'] != null
              ? parseStatusList(json['weeklyStatus'])
              : List.filled(5, TransportStatus.PENDING));

    final dropoffList = parseStatusList(json['weeklyDropoffStatus']);

    return Employee(
      id: json['id'],
      serialNumber: json['serialNumber'],
      name: json['name'],
      phoneNumber: json['phoneNumber'] ?? '',
      pickupLocation: json['pickupLocation'] ?? '',
      company: json['company'] ?? '',
      time: json['time'],
      dropOffTime: json['dropOffTime'] ?? '17:00',
      day: DayOfWeek.fromJson(json['day'] ?? 'Monday'),
      weeklyPickupStatus: pickupList,
      weeklyDropoffStatus: dropoffList,
      weeklyHealthChecks:
          (json['weeklyHealthChecks'] as List? ?? List.filled(5, null))
              .map(
                (e) => e != null
                    ? HealthCheckData.fromJson(e as Map<String, dynamic>)
                    : null,
              )
              .toList(),
      lastUpdated: json['lastUpdated'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'name': name,
      'phoneNumber': phoneNumber,
      'pickupLocation': pickupLocation,
      'company': company,
      'time': time,
      'dropOffTime': dropOffTime,
      'day': day.toJson(),
      'weeklyPickupStatus': weeklyPickupStatus.map((e) => e.toJson()).toList(),
      'weeklyDropoffStatus': weeklyDropoffStatus
          .map((e) => e.toJson())
          .toList(),
      'weeklyHealthChecks': weeklyHealthChecks.map((e) => e?.toJson()).toList(),
      'lastUpdated': lastUpdated,
    };
  }

  Employee copyWith({
    String? id,
    String? serialNumber,
    String? name,
    String? phoneNumber,
    String? pickupLocation,
    String? company,
    String? time,
    String? dropOffTime,
    DayOfWeek? day,
    List<TransportStatus>? weeklyPickupStatus,
    List<TransportStatus>? weeklyDropoffStatus,
    List<HealthCheckData?>? weeklyHealthChecks,
    String? lastUpdated,
  }) {
    return Employee(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      company: company ?? this.company,
      time: time ?? this.time,
      dropOffTime: dropOffTime ?? this.dropOffTime,
      day: day ?? this.day,
      weeklyPickupStatus: weeklyPickupStatus ?? this.weeklyPickupStatus,
      weeklyDropoffStatus: weeklyDropoffStatus ?? this.weeklyDropoffStatus,
      weeklyHealthChecks: weeklyHealthChecks ?? this.weeklyHealthChecks,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
