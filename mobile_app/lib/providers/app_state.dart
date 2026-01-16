
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
    _employees = await _storage.getEmployees();
    _isLoading = false;
    notifyListeners();
  }

  void setViewMode(AppViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  Future<void> updateEmployeeStatus(String id, int weekIndex, TransportStatus status) async {
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
      await _storage.saveEmployees(_employees);
    }
  }

  Future<void> updateEmployee(Employee updatedEmp) async {
    final index = _employees.indexWhere((e) => e.id == updatedEmp.id);
    if (index != -1) {
      _employees[index] = updatedEmp;
    } else {
      _employees.insert(0, updatedEmp); // Add new
    }
    notifyListeners();
    await _storage.saveEmployees(_employees);
  }

  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e.id == id);
    notifyListeners();
    await _storage.saveEmployees(_employees);
  }

  Future<void> resetData() async {
    _employees = await _storage.resetData();
    notifyListeners();
  }
}
