import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/features/agency/models/agency_models.dart';

class HRScreen extends StatelessWidget {
  const HRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final employees = [
      AgencyEmployee(
        id: '1',
        name: 'Nicolas Norton',
        role: 'Director',
        email: 'nicolas@inhaus.agency',
        avatarUrl: '', // Use fallback
        status: EmployeeStatus.active,
        joinDate: DateTime(2023, 1, 15),
      ),
      AgencyEmployee(
        id: '2',
        name: 'Sofia Martinez',
        role: 'Creative Lead',
        email: 'sofia@inhaus.agency',
        avatarUrl: '',
        status: EmployeeStatus.active,
        joinDate: DateTime(2023, 3, 10),
      ),
      AgencyEmployee(
        id: '3',
        name: 'Brian',
        role: 'AI Router Agent',
        email: 'brian@system.ai',
        avatarUrl: '',
        status: EmployeeStatus.active,
        joinDate: DateTime(2025, 1, 1),
      ),
       AgencyEmployee(
        id: '4',
        name: 'Proposal Specialist',
        role: 'AI Specialist',
        email: 'proposals@system.ai',
        avatarUrl: '',
        status: EmployeeStatus.active,
        joinDate: DateTime(2025, 2, 5),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Team & HR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeamSummary(context, employees),
            const SizedBox(height: 24),
            const Text('Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                      child: Text(
                        employee.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ),
                    title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${employee.role} • ${employee.email}'),
                    trailing: _buildStatusChip(context, employee.status),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSummary(BuildContext context, List<AgencyEmployee> employees) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(context, 'Total Staff', employees.length.toString(), Icons.people_outline, Colors.blue),
            _buildSummaryItem(context, 'Active', employees.where((e) => e.status == EmployeeStatus.active).length.toString(), Icons.check_circle_outline, Colors.green),
            _buildSummaryItem(context, 'On Leave', employees.where((e) => e.status == EmployeeStatus.onLeave).length.toString(), Icons.beach_access, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, EmployeeStatus status) {
    Color color;
    switch (status) {
      case EmployeeStatus.active: color = Colors.green; break;
      case EmployeeStatus.onLeave: color = Colors.orange; break;
      case EmployeeStatus.terminated: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
