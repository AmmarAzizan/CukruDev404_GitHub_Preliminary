import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import 'auth_provider.dart';
import 'budget_provider.dart';

final expenseServiceProvider =
    Provider<ExpenseService>((_) => ExpenseService());

/// Real-time stream of all expenses for the current user, newest first.
final expensesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(expenseServiceProvider).watchExpenses(user.uid);
});

/// Currently selected month for the expense list filter.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Expenses filtered to the selected month, newest first.
final filteredExpensesProvider =
    Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  final all = ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return all.whenData(
    (list) => list
        .where((e) =>
            e.date.year == month.year && e.date.month == month.month)
        .toList(),
  );
});

/// Sum of expense amounts for the selected month.
final monthlyTotalProvider = Provider<double>((ref) {
  return ref.watch(filteredExpensesProvider).whenOrNull(
            data: (list) => list.fold<double>(0.0, (s, e) => s + e.amount),
          ) ??
      0.0;
});

// ─── CRUD notifier (used by add / edit screens) ───────────────────────────────

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  ExpenseNotifier(this._service) : super(const AsyncValue.data(null));

  final ExpenseService _service;

  Future<void> addExpense(ExpenseModel expense) async {
    state = const AsyncValue.loading();
    try {
      await _service.addExpense(expense);
      state = const AsyncValue.data(null);
    } on FirebaseException catch (e) {
      state = AsyncValue.error(_msg(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateExpense(expense);
      state = const AsyncValue.data(null);
    } on FirebaseException catch (e) {
      state = AsyncValue.error(_msg(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }

  String _msg(FirebaseException e) =>
      e.code == 'permission-denied' ? 'Permission denied.' : 'Error: ${e.message}';
}

final expenseNotifierProvider =
    StateNotifierProvider.autoDispose<ExpenseNotifier, AsyncValue<void>>(
  (ref) => ExpenseNotifier(ref.watch(expenseServiceProvider)),
);

// ─── Dashboard providers (always based on current calendar month) ─────────────

/// Expenses for the current calendar month, newest first.
final currentMonthExpensesProvider =
    Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  final all = ref.watch(expensesStreamProvider);
  final now = DateTime.now();
  return all.whenData(
    (list) => list
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList(),
  );
});

/// Total spent in the current calendar month.
final dashboardMonthlyTotalProvider = Provider<double>((ref) {
  return ref.watch(currentMonthExpensesProvider).whenOrNull(
            data: (list) => list.fold<double>(0.0, (s, e) => s + e.amount),
          ) ??
      0.0;
});

/// Spending grouped by category value for the current month.
final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final expenses =
      ref.watch(currentMonthExpensesProvider).valueOrNull ?? [];
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
});

/// Spending grouped by day-of-month for the current month.
final dailySpendingProvider = Provider<Map<int, double>>((ref) {
  final expenses =
      ref.watch(currentMonthExpensesProvider).valueOrNull ?? [];
  final map = <int, double>{};
  for (final e in expenses) {
    map[e.date.day] = (map[e.date.day] ?? 0) + e.amount;
  }
  return map;
});

/// The 5 most recent expenses across all months.
final recentTransactionsProvider =
    Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  return ref.watch(expensesStreamProvider).whenData(
        (list) => list.take(5).toList(),
      );
});

// ─── Dynamic category list ────────────────────────────────────────────────────

/// Returns budget categories for the current month when a budget exists,
/// otherwise falls back to [kCategories]. 'Savings' is always excluded
/// since it is not a spendable expense category.
final categoryListProvider = Provider<List<ExpenseCategory>>((ref) {
  final budget = ref.watch(currentBudgetProvider).valueOrNull;
  if (budget == null) return kCategories;

  final cats = budget.categories
      .where((c) => c.category != 'Savings')
      .map((c) => ExpenseCategory(
            value: c.category,
            label: c.category,
            icon: c.flutterIcon,
            color: c.flutterColor,
          ))
      .toList();

  return cats.isEmpty ? kCategories : cats;
});
