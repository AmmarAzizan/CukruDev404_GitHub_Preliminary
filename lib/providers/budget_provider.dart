import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../services/ai_service.dart';
import '../services/budget_service.dart';
import 'auth_provider.dart';

final budgetServiceProvider = Provider<BudgetService>((_) => BudgetService());

/// Real-time stream of the current month's budget from Firestore.
final currentBudgetProvider = StreamProvider<BudgetModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(budgetServiceProvider).watchCurrentBudget();
});

// ─── Save notifier ────────────────────────────────────────────────────────────

class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  BudgetNotifier(this._service) : super(const AsyncValue.data(null));

  final BudgetService _service;

  Future<void> saveBudget(List<BudgetCategory> categories) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveBudget(categories);
      state = const AsyncValue.data(null);
    } on FirebaseException catch (e) {
      state = AsyncValue.error(
          e.message ?? 'Failed to save budget.', StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}

final budgetNotifierProvider =
    StateNotifierProvider.autoDispose<BudgetNotifier, AsyncValue<void>>(
  (ref) => BudgetNotifier(ref.watch(budgetServiceProvider)),
);

// ─── AI generation notifier (used by Budget Screen → Regenerate) ──────────────

class BudgetGenerationNotifier
    extends StateNotifier<AsyncValue<List<BudgetCategory>?>> {
  BudgetGenerationNotifier() : super(const AsyncValue.data(null));

  Future<void> generate({
    required String profileType,
    required double monthlyBudget,
    required double savingTarget,
  }) async {
    state = const AsyncValue.loading();
    try {
      final categories = await AiService().generateBudget(
        profileType: profileType,
        monthlyBudget: monthlyBudget,
        savingTarget: savingTarget,
      );
      state = AsyncValue.data(categories);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final budgetGenerationProvider = StateNotifierProvider.autoDispose<
    BudgetGenerationNotifier, AsyncValue<List<BudgetCategory>?>>(
  (_) => BudgetGenerationNotifier(),
);
