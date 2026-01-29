import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../services/storage_service.dart';

enum AppViewMode { USER, ADMIN }

class AppState with ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Employee> _employees = [];
  AppViewMode _viewMode = AppViewMode.USER;
  bool _isLoading = true;

  List<Employee> get employees => _employees;
  AppViewMode get viewMode => _viewMode;
  bool get isLoading => _isLoading;

  AppState() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _employees = await _storage.getEmployees();
    } catch (e) {
      print("Error fetching employees: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // Load attendance overlay
    await loadAttendanceForMonth(DateTime.now());
  }

  void setViewMode(AppViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> updateEmployeeStatus(
    String id,
    int weekIndex,
    TransportStatus status,
  ) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emp = _employees[index];
      final newWeeks = List<TransportStatus>.from(emp.weeklyStatus);
      newWeeks[weekIndex] = status;

      final updatedEmp = emp.copyWith(
        weeklyStatus: newWeeks,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      _employees[index] = updatedEmp;
      notifyListeners();

      // Removed: await _storage.updateEmployee(updatedEmp);
      // We no longer update the employee roster for attendance changes.

      // Save to historical attendance
      try {
        final date = calculateDate(emp.day, weekIndex);
        await _storage.saveAttendance(
          emp.id,
          emp.name,
          emp.serialNumber,
          date,
          status,
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
    String healthCondition,
    double temperature,
  ) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emp = _employees[index];
      final date = calculateDate(emp.day, weekIndex);

      print('=== Saving Attendance with Health Data ===');
      print('Employee: ${emp.name}');
      print('Date: $date');
      print('Status: $status');
      print('Health: $healthCondition - $temperature°C');

      await _storage.saveAttendance(
        emp.id,
        emp.name,
        emp.serialNumber,
        date,
        status,
        healthCondition: healthCondition,
        temperature: temperature,
      );

      print('✓ Saved to attendance collection');
    }
  }

  // Load attendance overlays for the displayed time period
  // This fetches for all employees across relevant dates for the REFERENCE MONTH
  Future<void> loadAttendanceForMonth(DateTime referenceDate) async {
    // Iterate through employees, calculate their specific date for the month, and fetch.

    // We scan 5 weeks to cover all possible days in a month view
    for (int weekIndex = 0; weekIndex < 5; weekIndex++) {
      final uniqueDates = <String, DateTime>{};

      for (var emp in _employees) {
        final date = calculateDate(
          emp.day,
          weekIndex,
          referenceDate: referenceDate,
        );
        uniqueDates["${date.year}-${date.month}-${date.day}"] = date;
      }

      for (var date in uniqueDates.values) {
        final attendanceMap = await _storage.getAttendance(date);
        if (attendanceMap.isNotEmpty) {
          for (var entry in attendanceMap.entries) {
            final empId = entry.key;
            final status = entry.value;

            final index = _employees.indexWhere((e) => e.id == empId);
            if (index != -1) {
              final emp = _employees[index];

              // Verify if this employee's day/week corresponds to this date
              final empDate = calculateDate(
                emp.day,
                weekIndex,
                referenceDate: referenceDate,
              );

              if (empDate.year == date.year &&
                  empDate.month == date.month &&
                  empDate.day == date.day) {
                final newWeeks = List<TransportStatus>.from(emp.weeklyStatus);
                // Ensure list is large enough (rare edge case if we go beyond initial 5)
                if (weekIndex < newWeeks.length) {
                  newWeeks[weekIndex] = status;
                  _employees[index] = emp.copyWith(weeklyStatus: newWeeks);
                }
              }
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

  Future<void> saveDailyShift(DateTime date, List<Employee> employees) async {
    await _storage.saveDailyShift(date, employees);
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
