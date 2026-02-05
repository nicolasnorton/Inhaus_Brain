import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_model.dart';
import '../services/finance_service.dart';

// Service Provider
final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService();
});

// Mock Storage
class FinanceNotifier extends StateNotifier<List<FinanceTransaction>> {
  FinanceNotifier() : super(_getMockTransactions());

  void addTransaction(FinanceTransaction tx) {
    state = [...state, tx];
  }

  static List<FinanceTransaction> _getMockTransactions() {
    final now = DateTime.now();
    return [
      FinanceTransaction.create(
        title: 'Retainer - Café Del Sol',
        amount: 2500.00,
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 2)),
        clientId: '1',
      ),
      FinanceTransaction.create(
        title: 'Project Fee - TechSolutions',
        amount: 4000.00,
        type: TransactionType.income,
        date: now.subtract(const Duration(days: 5)),
        clientId: '2',
      ),
      FinanceTransaction.create(
        title: 'Meta Ads - Café Del Sol Campaign',
        amount: 800.00,
        type: TransactionType.expense,
        category: ExpenseCategory.ad_spend,
        date: now.subtract(const Duration(days: 3)),
        clientId: '1',
      ),
      FinanceTransaction.create(
        title: 'Google Cloud Platform',
        amount: 150.00,
        type: TransactionType.expense,
        category: ExpenseCategory.software_subscription,
        date: now.subtract(const Duration(days: 15)),
      ),
      FinanceTransaction.create(
        title: 'Office Rent - Quito',
        amount: 1200.00,
        type: TransactionType.expense,
        category: ExpenseCategory.rent,
        date: now.subtract(const Duration(days: 20)),
      ),
       FinanceTransaction.create(
        title: 'SRI - Pago IVA Mensual',
        amount: 320.00,
        type: TransactionType.tax_payment,
        category: ExpenseCategory.taxes_sri,
        date: now.subtract(const Duration(days: 25)),
      ),
    ];
  }
}

final financeTransactionsProvider = StateNotifierProvider<FinanceNotifier, List<FinanceTransaction>>((ref) {
  return FinanceNotifier();
});

// Derived Provider: Snapshot
final financeSnapshotProvider = Provider<FinanceSnapshot>((ref) {
  final txs = ref.watch(financeTransactionsProvider);
  
  double income = 0;
  double expense = 0;
  
  for (var t in txs) {
    if (t.type == TransactionType.income) income += t.amount;
    if (t.type == TransactionType.expense || t.type == TransactionType.tax_payment) expense += t.amount;
  }

  // Very rough estimation just for demo
  double taxLiability = (income - expense) * 0.15; // 15% IVA rough est

  return FinanceSnapshot(
    totalRevenue: income,
    totalExpenses: expense,
    netProfit: income - expense,
    currentBurnRate: expense, // Monthly burn roughly equals total expenses in this window
    estimatedTaxLiability: taxLiability > 0 ? taxLiability : 0,
  );
});
