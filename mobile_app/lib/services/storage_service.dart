import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../constants.dart';

class StorageService {
  final CollectionReference _employeesRef = FirebaseFirestore.instance
      .collection('employees');

  Future<List<Employee>> getEmployees() async {
    try {
      final snapshot = await _employeesRef.get();

      if (snapshot.docs.isEmpty) {
        // Optional: Seed if completely empty, or just return empty
        // For now, let's return empty list to avoid auto-seeding constantly on new dbs
        // unless we strictly want INITIAL_DATA.
        // Let's seed IF functionality implies a demo state, but for production, empty is better.
        // But to keep behavior same as before:
        // return INITIAL_DATA;
        // Actually, let's return what is in DB. If user wants seed, we can add a seed button.
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID logic is consistent
        return Employee.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error fetching employees: $e");
      return [];
    }
  }

  // Modified to handle single operations for efficiency

  Future<void> addEmployee(Employee employee) async {
    await _employeesRef.doc(employee.id).set(employee.toJson());
  }

  Future<void> updateEmployee(Employee employee) async {
    final jsonData = employee.toJson();
    print('=== Firebase Update ===');
    print('Document ID: ${employee.id}');
    print('Employee Name: ${employee.name}');
    print('Weekly Health Checks Count: ${employee.weeklyHealthChecks.length}');

    // Print each health check
    for (int i = 0; i < employee.weeklyHealthChecks.length; i++) {
      final hc = employee.weeklyHealthChecks[i];
      if (hc != null) {
        print('  Week $i: ${hc.healthCondition} - ${hc.temperature}°C');
      } else {
        print('  Week $i: null');
      }
    }

    print('Full JSON Data:');
    print(jsonData);

    // Use set with merge instead of update to handle missing fields
    await _employeesRef.doc(employee.id).set(jsonData, SetOptions(merge: true));

    print('✓ Firebase document saved');
  }

  Future<void> deleteEmployee(String id) async {
    await _employeesRef.doc(id).delete();
  }

  // Deprecated/Modified: Previously we saved the whole list.
  // We will keep this for compatibility if AppState still calls it,
  // but we should refactor AppState to use granular methods.
  // Implementing 'saveEmployees' as a bulk update is expensive (batch writes).
  // Let's defer this and update AppState first.
  Future<void> saveEmployees(List<Employee> employees) async {
    // This was used to overwrite everything.
    // We will leave this empty or throw error to force refactor.
    print(
      "WARNING: saveEmployees (bulk) called. Preferred to use add/update/delete.",
    );
  }

  Future<List<Employee>> resetData() async {
    // Delete all
    final snapshot = await _employeesRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return [];
  }

  Future<void> saveAttendance(
    String empId,
    String empName,
    String serialNumber,
    DateTime date,
    TransportStatus status, {
    String? healthCondition,
    double? temperature,
  }) async {
    // Format date as YYYY-MM-DD
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> data = {
      'employeeId': empId,
      'name': empName,
      'serialNumber': serialNumber,
      'status': status.name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add health check data if provided
    if (healthCondition != null && temperature != null) {
      data['healthCondition'] = healthCondition;
      data['temperature'] = temperature;
      print(
        'Saving health data to attendance: $healthCondition, $temperature°C',
      );
    }

    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(dateStr)
        .collection('records')
        .doc(empId)
        .set(data);
  }

  Future<void> saveDailyShift(DateTime date, List<Employee> employees) async {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final batch = FirebaseFirestore.instance.batch();
    final dayRef = FirebaseFirestore.instance
        .collection('daily_shifts')
        .doc(dateStr);

    // Set metadata for the shift
    batch.set(dayRef, {
      'date': dateStr,
      'timestamp': DateTime.now().toIso8601String(),
      'totalPassengers': employees.length,
    });

    // Save each employee as a subcollection item or array?
    // Subcollection is safer for large lists (Firestore document limit 1MB).
    final recordsRef = dayRef.collection('manifest');

    // Delete old manifest if exists (to ensure clean snapshot)
    // Warning: Batch limits (500 ops). If list is huge, this might fail.
    // Assuming small list (<100) for now.
    // To be safe, let's just write.

    for (var emp in employees) {
      final docRef = recordsRef.doc(emp.id);
      batch.set(docRef, emp.toJson());
    }

    await batch.commit();
  }

  Future<Map<String, TransportStatus>> getAttendance(DateTime date) async {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(dateStr)
          .collection('records')
          .get();

      final Map<String, TransportStatus> attendanceMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('status') && data.containsKey('employeeId')) {
          final statusStr = data['status'] as String;
          final empId = data['employeeId'] as String;
          // Parse status safely
          final status = TransportStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => TransportStatus.PENDING,
          );
          attendanceMap[empId] = status;
        }
      }
      return attendanceMap;
    } catch (e) {
      print("Error fetching attendance for $dateStr: $e");
      return {};
    }
  }
}
