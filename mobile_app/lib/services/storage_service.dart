
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../constants.dart';

class StorageService {
  static const String STORAGE_KEY = 'transport_schedule_db_v3';

  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(STORAGE_KEY);

    if (stored == null) {
      // Seed initial data
      await saveEmployees(INITIAL_DATA);
      return INITIAL_DATA;
    }

    try {
      final List<dynamic> parsedData = jsonDecode(stored);
      if (parsedData.isNotEmpty) {
         return parsedData.map((e) => Employee.fromJson(e)).toList();
      }
      return INITIAL_DATA;
    } catch (e) {
      print("Failed to parse storage: $e");
      return INITIAL_DATA;
    }
  }

  Future<void> saveEmployees(List<Employee> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(employees.map((e) => e.toJson()).toList());
    await prefs.setString(STORAGE_KEY, jsonString);
  }

  Future<List<Employee>> resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(STORAGE_KEY); // Clear old
    await saveEmployees(INITIAL_DATA); // Reset to default
    return INITIAL_DATA;
  }
}
