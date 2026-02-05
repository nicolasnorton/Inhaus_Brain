
import 'package:flutter/material.dart';

enum EmployeeStatus { active, onLeave, terminated }
enum LeadStatus { newLead, contacted, qualified, proposalSent, negotiation, closedWon, closedLost }

class AgencyEmployee {
  final String id;
  final String name;
  final String role;
  final String email;
  final String avatarUrl;
  final EmployeeStatus status;
  final DateTime joinDate;

  AgencyEmployee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.avatarUrl,
    required this.status,
    required this.joinDate,
  });
}

class SalesLead {
  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final LeadStatus status;
  final double estimatedValue;
  final DateTime lastContacted;
  final String notes;

  SalesLead({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.status,
    required this.estimatedValue,
    required this.lastContacted,
    required this.notes,
  });
}

class FinanceMetric {
  final String label;
  final double value;
  final double percentChange;
  final bool isPositiveTrend;
  final IconData icon;
  final Color color;

  FinanceMetric({
    required this.label,
    required this.value,
    required this.percentChange,
    required this.isPositiveTrend,
    required this.icon,
    required this.color,
  });
}
