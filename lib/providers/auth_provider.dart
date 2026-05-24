import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService());

/// Streams Firebase auth state (User? — null means logged out)
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

/// Holds transient form state (loading / error) for login & register screens
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._service) : super(const AsyncValue.data(null));

  final AuthService _service;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _service.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_service.getErrorMessage(e), StackTrace.current);
    } on FirebaseException catch (e) {
      state = AsyncValue.error(_firestoreError(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.register(name: name, email: email, password: password);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_service.getErrorMessage(e), StackTrace.current);
    } on FirebaseException catch (e) {
      // Auth user was created but Firestore write failed (usually security rules)
      state = AsyncValue.error(_firestoreError(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }

  String _firestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Database permission denied. Please update your Firestore security rules.';
    }
    return 'Database error (${e.code}): ${e.message}';
  }
}

/// autoDispose so state resets when the screen is left (no stale errors)
final authNotifierProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);

/// Manages forgot-password flow: data(false) = idle, data(true) = email sent
class ForgotPasswordNotifier extends StateNotifier<AsyncValue<bool>> {
  ForgotPasswordNotifier(this._service) : super(const AsyncValue.data(false));

  final AuthService _service;

  Future<void> sendReset({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _service.sendPasswordResetEmail(email);
      state = const AsyncValue.data(true);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(_service.getErrorMessage(e), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error('Unexpected error: $e', StackTrace.current);
    }
  }
}

final forgotPasswordProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordNotifier, AsyncValue<bool>>(
  (ref) => ForgotPasswordNotifier(ref.watch(authServiceProvider)),
);

/// Fetches display name from Firestore, falling back to Firebase Auth displayName
final userNameProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['name'] as String? ?? user.displayName;
  } catch (_) {
    return user.displayName;
  }
});
