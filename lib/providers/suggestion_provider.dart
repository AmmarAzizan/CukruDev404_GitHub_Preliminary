import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/suggestion_service.dart';
import 'expense_provider.dart';
import 'profile_provider.dart';
import 'budget_provider.dart';
import 'reward_provider.dart';

/// Derives smart spending suggestions from live data streams.
/// Returns AsyncLoading while any source is loading, AsyncData otherwise.
final suggestionProvider = Provider<AsyncValue<List<Suggestion>>>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final profileAsync = ref.watch(userProfileProvider);
  final budgetAsync = ref.watch(currentBudgetProvider);
  final rewardAsync = ref.watch(rewardStreamProvider);

  if (expensesAsync.isLoading ||
      profileAsync.isLoading ||
      budgetAsync.isLoading ||
      rewardAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final allExpenses = expensesAsync.valueOrNull ?? <ExpenseModel>[];
  final profile = profileAsync.valueOrNull;
  final budget = budgetAsync.valueOrNull;
  final reward = rewardAsync.valueOrNull;

  // Filter to current month only
  final now = DateTime.now();
  final expenses = allExpenses
      .where((e) => e.date.year == now.year && e.date.month == now.month)
      .toList();

  final monthlyBudget =
      (profile?['monthlyBudget'] as num?)?.toDouble() ?? 0.0;
  final savingTarget =
      (profile?['savingTarget'] as num?)?.toDouble() ?? 0.0;

  final categoryBudgets = <String, double>{};
  if (budget != null) {
    for (final cat in budget.categories) {
      categoryBudgets[cat.category] = cat.amount;
    }
  }

  final suggestions = SuggestionService().generate(
    expenses: expenses,
    monthlyBudget: monthlyBudget,
    savingTarget: savingTarget,
    categoryBudgets: categoryBudgets,
    streak: reward?.currentStreak ?? 0,
  );

  return AsyncValue.data(suggestions);
});
