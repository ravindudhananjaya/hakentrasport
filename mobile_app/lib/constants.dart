
import 'package:uuid/uuid.dart';
import 'models/employee.dart';

const uuid = Uuid();

const List<String> PICKUP_LOCATIONS = [
  'Eki',
  'Kodomo',
  'Rokumachi', 
  'Shi-mae',
  'Eki Cycle Park',
  'Apart',
  'Self',
];

const List<String> COMPANIES = [
  'Dai 1',
  'Dai 2',
  'Dai 3',
  'Akagi',
  'Haga-A',
  'Haga-B',
];

List<TransportStatus> defaultWeeks([TransportStatus initialStatus = TransportStatus.PENDING]) {
  final weeks = List.filled(5, TransportStatus.PENDING);
  weeks[0] = initialStatus;
  return weeks;
}

Employee createEmp(String serial, String name, String pickup, String company, String time, {DayOfWeek day = DayOfWeek.Monday, TransportStatus status = TransportStatus.PENDING}) {
  return Employee(
    id: uuid.v4(),
    serialNumber: serial,
    name: name,
    pickupLocation: pickup,
    company: company,
    time: time,
    day: day,
    weeklyStatus: defaultWeeks(status),
    lastUpdated: DateTime.now().toIso8601String(),
  );
}

final List<Employee> INITIAL_DATA = [
  // Monday Shifts
  createEmp("1", "Kanchan", "Apart", "Dai 1", "03:10", day: DayOfWeek.Monday),
  createEmp("2", "Roshan Sharma", "Eki", "Dai 2", "04:20", day: DayOfWeek.Monday),
  createEmp("3", "Binaya Adhikari", "Kodomo", "Dai-2", "04:20", day: DayOfWeek.Monday),
  createEmp("4", "Laxmi", "Kodomo", "Dai 1", "04:20", day: DayOfWeek.Monday),
  createEmp("5", "Sonika Pathak", "Kodomo", "Dai-1", "04:25", day: DayOfWeek.Monday),
  createEmp("8", "Kamal Bhandari", "Rokumachi", "Akagi", "04:00", day: DayOfWeek.Monday),
  createEmp("9", "Harka", "Rokumachi", "Akagi", "04:00", day: DayOfWeek.Monday),
  createEmp("10", "Saleem", "Rokumachi", "Dai-3", "04:00", day: DayOfWeek.Monday),
  createEmp("11", "Mohiddin", "Eki", "Dai-3", "04:20", day: DayOfWeek.Monday),
  createEmp("12", "Dorje Tamang", "Shi-mae", "Dai-1", "05:00", day: DayOfWeek.Monday),
  createEmp("14", "Mina", "Shi-mae", "Akagi", "05:00", day: DayOfWeek.Monday),
  createEmp("20", "Kushal", "EKI", "Dai 2", "05:20", day: DayOfWeek.Monday),
  createEmp("24", "Niru Dhakal Kharel", "Self", "Haga-A", "05:20", day: DayOfWeek.Monday, status: TransportStatus.SELF_TRAVEL),
  createEmp("26", "Amir Shrestha", "Self", "Dai-3", "05:20", day: DayOfWeek.Monday, status: TransportStatus.SELF_TRAVEL),
  createEmp("30", "Kabir", "Rokumachi", "Dai-1", "06:00", day: DayOfWeek.Monday),
  createEmp("34", "Bikram Bogati", "EKI", "Dai 3", "06:20", day: DayOfWeek.Monday),
  createEmp("38", "Rome", "Eki", "Haga-B", "06:20", day: DayOfWeek.Monday, status: TransportStatus.SELF_TRAVEL),
  createEmp("45", "Harris", "Rokumachi", "Dai-3", "07:00", day: DayOfWeek.Monday),
  createEmp("50", "Hein", "Eki", "Dai 1", "07:20", day: DayOfWeek.Monday),
  createEmp("60", "Kushal Thapa", "Eki", "Dai-1", "09:20", day: DayOfWeek.Monday),
  createEmp("70", "Dumidu", "EKI", "DAI 3", "13:20", day: DayOfWeek.Monday),
  createEmp("72", "Prashan", "Eki", "Haga-A", "13:20", day: DayOfWeek.Monday, status: TransportStatus.SELF_TRAVEL),
  createEmp("74", "Manoj Tiwari", "Eki Cycle Park", "Akagi", "14:20", day: DayOfWeek.Monday),
  createEmp("100", "Deinaru", "Eki Cycle Park", "Dai 3", "15:20", day: DayOfWeek.Monday, status: TransportStatus.SELF_TRAVEL),

  // Sample Tuesday Shifts
  createEmp("T1", "John Doe", "Eki", "Dai 1", "08:00", day: DayOfWeek.Tuesday),
  createEmp("T2", "Jane Smith", "Kodomo", "Dai 2", "08:30", day: DayOfWeek.Tuesday),
];
