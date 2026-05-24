import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';
import 'auth_provider.dart';

final rewardStreamProvider = StreamProvider<RewardData>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(RewardData.empty);
  return RewardService().watchRewards(user.uid);
});

class RewardNotifier extends StateNotifier<AsyncValue<List<String>>> {
  RewardNotifier() : super(const AsyncValue.data([]));

  Future<List<String>> updateStreakAndCheckBadges(String uid) async {
    state = const AsyncValue.loading();
    try {
      await RewardService().updateStreak(uid);
      final newBadges = await RewardService().checkAndAwardBadges(uid);
      state = AsyncValue.data(newBadges);
      return newBadges;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return [];
    }
  }

  Future<bool> tapNoSpendToday(String uid) async {
    try {
      final accepted = await RewardService().tapNoSpendToday(uid);
      if (accepted) {
        await RewardService().checkAndAwardBadges(uid);
      }
      return accepted;
    } catch (_) {
      return false;
    }
  }
}

final rewardNotifierProvider =
    StateNotifierProvider<RewardNotifier, AsyncValue<List<String>>>(
  (_) => RewardNotifier(),
);
