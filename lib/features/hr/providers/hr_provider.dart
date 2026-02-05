import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hr_model.dart';
import '../services/hr_service.dart';

// Service Provider
final hrServiceProvider = Provider<HRService>((ref) {
  return HRService();
});

// Mock Storage
class HRNotifier extends StateNotifier<List<Employee>> {
  HRNotifier() : super(_getMockEmployees());

  void addEmployee(Employee emp) {
    state = [...state, emp];
  }

  static List<Employee> _getMockEmployees() {
    return [
      Employee(
        id: '1',
        fullName: 'Carlos Andrade',
        role: 'Senior Graphic Designer',
        department: Department.creative,
        status: EmployeeStatus.active,
        hireDate: DateTime(2023, 5, 12),
        salary: 1200.00,
        email: 'carlos@inhaus.ec',
      ),
      Employee(
        id: '2',
        fullName: 'Sofia Mera',
        role: 'Account Manager',
        department: Department.accounts,
        status: EmployeeStatus.active,
        hireDate: DateTime(2024, 1, 15),
        salary: 1500.00,
        email: 'sofia@inhaus.ec',
      ),
      Employee(
        id: '3',
        fullName: 'David Torres',
        role: 'Junior Dev',
        department: Department.tech,
        status: EmployeeStatus.probation,
        hireDate: DateTime.now().subtract(const Duration(days: 45)), // In probation
        salary: 800.00,
        email: 'david@inhaus.ec',
      ),
    ];
  }
}

final hrEmployeesProvider = StateNotifierProvider<HRNotifier, List<Employee>>((ref) {
  return HRNotifier();
});
