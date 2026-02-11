import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../services/storage_service.dart';
import '../constants.dart';

enum AppViewMode { USER, ADMIN }

class AppState with ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Employee> _employees = [];
  List<String> _pickupLocations = [];
  List<String> _companies = [];
  AppViewMode _viewMode = AppViewMode.USER;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  List<Employee> get employees => _employees;
  List<String> get pickupLocations => _pickupLocations;
  List<String> get companies => _companies;
  AppViewMode get viewMode => _viewMode;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  AppState() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex =
          prefs.getInt('theme_mode') ?? 0; // Default to system (0)
      _themeMode = ThemeMode.values[themeIndex];

      _employees = await _storage.getEmployees();

      // Load Dropdowns
      _pickupLocations = await _storage.getPickupLocations();
      if (_pickupLocations.isEmpty) {
        // Seed default locations
        print("Seeding locations...");
        for (var loc in PICKUP_LOCATIONS) {
          await _storage.addPickupLocation(loc);
        }
        _pickupLocations = List.from(PICKUP_LOCATIONS);
      }

      _companies = await _storage.getCompanies();
      if (_companies.isEmpty) {
        // Seed default companies
        print("Seeding companies...");
        for (var com in COMPANIES) {
          await _storage.addCompany(com);
        }
        _companies = List.from(COMPANIES);
      }
    } catch (e) {
      print("Error fetching employees: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // Load attendance overlay
    await loadAttendanceForMonth(DateTime.now());
  }

  Future<void> addPickupLocation(String name) async {
    if (_pickupLocations.contains(name)) return;

    _pickupLocations.add(name);
    _pickupLocations.sort();
    notifyListeners();

    await _storage.addPickupLocation(name);
  }

  Future<void> addCompany(String name) async {
    if (_companies.contains(name)) return;

    _companies.add(name);
    _companies.sort();
    notifyListeners();

    await _storage.addCompany(name);
  }

  void setViewMode(AppViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> updateEmployeeStatus(
    String id,
    int weekIndex,
    TransportStatus status, {
    required bool isPickup,
  }) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emp = _employees[index];

      final newPickup = List<TransportStatus>.from(emp.weeklyPickupStatus);
      final newDropoff = List<TransportStatus>.from(emp.weeklyDropoffStatus);

      if (isPickup) {
        if (weekIndex < newPickup.length) newPickup[weekIndex] = status;
      } else {
        if (weekIndex < newDropoff.length) newDropoff[weekIndex] = status;
      }

      final updatedEmp = emp.copyWith(
        weeklyPickupStatus: newPickup,
        weeklyDropoffStatus: newDropoff,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      _employees[index] = updatedEmp;
      notifyListeners();

      // Save to historical attendance
      try {
        final date = calculateDate(emp.day, weekIndex);
        await _storage.saveAttendance(
          emp.id,
          emp.name,
          emp.serialNumber,
          date,
          status,
          isPickup: isPickup,
        );
      } catch (e) {
        print("Error saving attendance history: $e");
      }
    }
  }

  Future<void> updateEmployeeHealthCheck(
    String id,
    int weekIndex,
    String healthCondition,
    double temperature,
  ) async {
    print('=== Updating Health Check ===');
    print('Employee ID: $id');
    print('Week Index: $weekIndex');
    print('Health Condition: $healthCondition');
    print('Temperature: $temperature');

    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emp = _employees[index];
      print('Found employee: ${emp.name}');
      print('Current health checks: ${emp.weeklyHealthChecks}');

      final newHealthChecks = List<HealthCheckData?>.from(
        emp.weeklyHealthChecks,
      );

      newHealthChecks[weekIndex] = HealthCheckData(
        healthCondition: healthCondition,
        temperature: temperature,
        timestamp: DateTime.now().toIso8601String(),
      );

      print('New health checks: $newHealthChecks');

      final updatedEmp = emp.copyWith(
        weeklyHealthChecks: newHealthChecks,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      _employees[index] = updatedEmp;
      notifyListeners();

      // Save to storage
      print('Saving to Firebase...');
      await _storage.updateEmployee(updatedEmp);
      print('✓ Saved to Firebase successfully');
    } else {
      print('ERROR: Employee not found with ID: $id');
    }
  }

  Future<void> saveAttendanceWithHealth(
    String id,
    int weekIndex,
    TransportStatus status,
    String? healthCondition,
    double? temperature, {
    required bool isPickup,
  }) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emp = _employees[index];
      final date = calculateDate(emp.day, weekIndex);

      print('=== Saving Attendance with Health Data ===');
      print('Employee: ${emp.name}');
      print('Date: $date');
      print('Status: $status');
      if (healthCondition != null || temperature != null) {
        print(
          'Health: ${healthCondition ?? "N/A"} - ${temperature != null ? "$temperature°C" : "N/A"}',
        );
      }

      await _storage.saveAttendance(
        emp.id,
        emp.name,
        emp.serialNumber,
        date,
        status,
        isPickup: isPickup,
        healthCondition: healthCondition,
        temperature: temperature,
      );

      print('✓ Saved to attendance collection');
    }
  }

  // Load attendance overlays for the displayed time period
  // This fetches for all employees across relevant dates for the REFERENCE MONTH
  Future<void> loadAttendanceForMonth(DateTime referenceDate) async {
    // We scan the entire month day-by-day to ensure we catch all attendance,
    // even if an employee shows up on a day they are not scheduled.
    // We map each day to a 'weekIndex' (0-4) based on 7-day blocks.
    // Day 1-7 -> Week 0
    // Day 8-14 -> Week 1
    // ...

    final daysInMonth = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      0,
    ).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final weekIndex = (day - 1) ~/ 7;
      if (weekIndex >= 5) continue; // Only track up to 5 weeks

      final date = DateTime(referenceDate.year, referenceDate.month, day);
      final attendanceMap = await _storage.getAttendance(date);

      if (attendanceMap.isNotEmpty) {
        for (var entry in attendanceMap.entries) {
          final empId = entry.key;
          final record = entry.value; // Map<String, TransportStatus>

          final index = _employees.indexWhere((e) => e.id == empId);
          if (index != -1) {
            final emp = _employees[index];

            final newPickup = List<TransportStatus>.from(
              emp.weeklyPickupStatus,
            );
            final newDropoff = List<TransportStatus>.from(
              emp.weeklyDropoffStatus,
            );
            bool changed = false;

            if (record.containsKey('pickup') && weekIndex < newPickup.length) {
              newPickup[weekIndex] = record['pickup']!;
              changed = true;
            }
            if (record.containsKey('dropoff') &&
                weekIndex < newDropoff.length) {
              newDropoff[weekIndex] = record['dropoff']!;
              changed = true;
            }

            if (changed) {
              _employees[index] = emp.copyWith(
                weeklyPickupStatus: newPickup,
                weeklyDropoffStatus: newDropoff,
              );
            }
          }
        }
      }
    }
    notifyListeners();
  }

  DateTime calculateDate(
    DayOfWeek day,
    int weekIndex, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    // Start from the 1st of the REFERENCE month
    DateTime firstOfMonth = DateTime(now.year, now.month, 1);

    // Find the first occurrence of the specific day in this month
    int targetWeekday = -1;
    switch (day) {
      case DayOfWeek.Monday:
        targetWeekday = 1;
        break;
      case DayOfWeek.Tuesday:
        targetWeekday = 2;
        break;
      case DayOfWeek.Wednesday:
        targetWeekday = 3;
        break;
      case DayOfWeek.Thursday:
        targetWeekday = 4;
        break;
      case DayOfWeek.Friday:
        targetWeekday = 5;
        break;
      case DayOfWeek.Saturday:
        targetWeekday = 6;
        break;
      case DayOfWeek.Sunday:
        targetWeekday = 7;
        break;
    }

    int daysToAdd = (targetWeekday - firstOfMonth.weekday + 7) % 7;
    DateTime firstOccurrence = firstOfMonth.add(Duration(days: daysToAdd));

    // Add weeks
    return firstOccurrence.add(Duration(days: weekIndex * 7));
  }

  Future<void> updateEmployee(Employee updatedEmp) async {
    final index = _employees.indexWhere((e) => e.id == updatedEmp.id);
    if (index != -1) {
      _employees[index] = updatedEmp;
      await _storage.updateEmployee(updatedEmp);
    } else {
      _employees.insert(0, updatedEmp); // Add new
      await _storage.addEmployee(updatedEmp);
    }
    notifyListeners();
  }

  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e.id == id);
    notifyListeners();
    await _storage.deleteEmployee(id);
  }

  Future<void> resetData() async {
    _employees = await _storage.resetData();
    notifyListeners();
  }
}
