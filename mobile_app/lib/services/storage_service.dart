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
    await _employeesRef.doc(employee.id).update(employee.toJson());
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
}
