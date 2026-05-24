import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((_) => ProfileService());

/// Fetches the full user profile document from Firestore.
/// Invalidate this provider after any profile update to force a refetch.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  return ref.read(profileServiceProvider).getUserProfile();
});

class ProfileSetupNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileSetupNotifier(this._service) : super(const AsyncValue.data(null));

  final ProfileService _service;

  Future<void> saveProfile({
    required String profileType,
    required double monthlyBudget,
    double savingTarget = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.saveProfile(
        profileType: profileType,
        monthlyBudget: monthlyBudget,
        savingTarget: savingTarget,
      );
      state = const AsyncValue.data(null);
    } on FirebaseException catch (e) {
      state = AsyncValue.error(_error(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }

  Future<void> updateProfile({
    required String profileType,
    required double monthlyBudget,
    double savingTarget = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateProfile(
        profileType: profileType,
        monthlyBudget: monthlyBudget,
        savingTarget: savingTarget,
      );
      state = const AsyncValue.data(null);
    } on FirebaseException catch (e) {
      state = AsyncValue.error(_error(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }

  String _error(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Permission denied. Check Firestore security rules.';
    }
    return 'Failed to save profile. Please try again.';
  }
}

final profileSetupProvider =
    StateNotifierProvider.autoDispose<ProfileSetupNotifier, AsyncValue<void>>(
  (ref) => ProfileSetupNotifier(ref.watch(profileServiceProvider)),
);
