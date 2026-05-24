import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_score_model.dart';
import '../services/health_score_service.dart';
import 'auth_provider.dart';

final healthScoreStreamProvider = StreamProvider<HealthScoreModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return HealthScoreService().watchCurrentScore(user.uid);
});

class HealthScoreNotifier extends StateNotifier<AsyncValue<void>> {
  HealthScoreNotifier() : super(const AsyncValue.data(null));

  Future<void> recalculate(String uid) async {
    state = const AsyncValue.loading();
    try {
      await HealthScoreService().calculate(uid);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final healthScoreNotifierProvider =
    StateNotifierProvider<HealthScoreNotifier, AsyncValue<void>>(
  (_) => HealthScoreNotifier(),
);
