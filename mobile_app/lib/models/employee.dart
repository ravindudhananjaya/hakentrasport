
enum DayOfWeek {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday;

  String toJson() => name;
  static DayOfWeek fromJson(String json) => DayOfWeek.values.firstWhere((e) => e.name == json);
}

enum TransportStatus {
  PENDING,
  ON_BOARD,
  DROPPED_OFF,
  SELF_TRAVEL,
  ABSENT;

  String toJson() => name;
  static TransportStatus fromJson(String json) => TransportStatus.values.firstWhere((e) => e.name == json, orElse: () => TransportStatus.PENDING);
}

class Employee {
  final String id;
  final String serialNumber;
  final String name;
  final String pickupLocation;
  final String company;
  final String time;
  final DayOfWeek day;
  final List<TransportStatus> weeklyStatus;
  final String lastUpdated;

  Employee({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.pickupLocation,
    required this.company,
    required this.time,
    required this.day,
    required this.weeklyStatus,
    required this.lastUpdated,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      serialNumber: json['serialNumber'],
      name: json['name'],
      pickupLocation: json['pickupLocation'] ?? '',
      company: json['company'] ?? '',
      time: json['time'],
      day: DayOfWeek.fromJson(json['day'] ?? 'Monday'),
      weeklyStatus: (json['weeklyStatus'] as List).map((e) => TransportStatus.fromJson(e.toString())).toList(),
      lastUpdated: json['lastUpdated'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'name': name,
      'pickupLocation': pickupLocation,
      'company': company,
      'time': time,
      'day': day.toJson(),
      'weeklyStatus': weeklyStatus.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated,
    };
  }
    
    Employee copyWith({
    String? id,
    String? serialNumber,
    String? name,
    String? pickupLocation,
    String? company,
    String? time,
    DayOfWeek? day,
    List<TransportStatus>? weeklyStatus,
    String? lastUpdated,
  }) {
    return Employee(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      company: company ?? this.company,
      time: time ?? this.time,
      day: day ?? this.day,
      weeklyStatus: weeklyStatus ?? this.weeklyStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
