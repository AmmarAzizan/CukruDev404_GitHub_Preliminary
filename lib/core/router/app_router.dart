import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/expense_model.dart';
import '../../screens/splash_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/onboarding/profile_setup_screen.dart';
import '../../screens/settings/edit_profile_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/expense/expense_list_screen.dart';
import '../../screens/expense/add_expense_screen.dart';
import '../../screens/expense/edit_expense_screen.dart';
import '../../screens/expense/receipt_scanner_screen.dart';
import '../../screens/expense/receipt_preview_screen.dart';
import '../../models/receipt_data.dart';
import '../../screens/budget/budget_screen.dart';
import '../../screens/budget/budget_review_screen.dart';
import '../../screens/health/health_score_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/rewards/rewards_screen.dart';
import '../../models/budget_model.dart';
import '../../widgets/main_shell.dart';

/// Wraps a Stream as a [Listenable] so go_router can refresh on auth changes.
class _StreamListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _StreamListenable(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable =
      _StreamListenable(FirebaseAuth.instance.authStateChanges());
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final path = state.uri.path;

      // Splash handles its own navigation
      if (path == '/splash') return null;

      final isAuthPage = path == '/login' ||
          path == '/register' ||
          path == '/forgot-password';

      if (!isLoggedIn && !isAuthPage) return '/login';
      // Logged-in users on auth pages go through onboarding check
      if (isLoggedIn && isAuthPage) return '/onboarding';
      return null;
    },
    routes: [
      // ── Unauthenticated screens ──────────────────────────────────────────
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) =>
            _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, state) =>
            _fadePage(state, const ForgotPasswordScreen()),
      ),

      // ── Onboarding / settings (no bottom nav) ───────────────────────────
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, state) =>
            _fadePage(state, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        pageBuilder: (_, state) =>
            _fadePage(state, const EditProfileScreen()),
      ),

      // ── Health score (no bottom nav) ────────────────────────────────────
      GoRoute(
        path: '/health',
        pageBuilder: (_, state) =>
            _fadePage(state, const HealthScoreScreen()),
      ),

      // ── Profile (no bottom nav — accessed from Home header) ─────────────
      GoRoute(
        path: '/profile',
        pageBuilder: (_, state) =>
            _fadePage(state, const ProfileScreen()),
      ),

      // ── Budget review (no bottom nav) ───────────────────────────────────
      GoRoute(
        path: '/budget/review',
        pageBuilder: (_, state) {
          final args = state.extra as BudgetReviewArgs;
          return _fadePage(state, BudgetReviewScreen(args: args));
        },
      ),

      // ── Add / Edit / Scan expense (no bottom nav) ───────────────────────
      GoRoute(
        path: '/expenses/add',
        pageBuilder: (_, state) {
          final prefill = state.extra as ReceiptData?;
          return _fadePage(state, AddExpenseScreen(prefill: prefill));
        },
      ),
      GoRoute(
        path: '/expenses/scan',
        pageBuilder: (_, state) =>
            _fadePage(state, const ReceiptScannerScreen()),
      ),
      GoRoute(
        path: '/expenses/scan/preview',
        pageBuilder: (_, state) {
          final receipt = state.extra as ReceiptData;
          return _fadePage(state, ReceiptPreviewScreen(receipt: receipt));
        },
      ),
      GoRoute(
        path: '/expenses/edit/:id',
        pageBuilder: (_, state) {
          final expense = state.extra as ExpenseModel;
          return _fadePage(state, EditExpenseScreen(expense: expense));
        },
      ),

      // ── Main shell (Home / Expenses / Budget / Rewards tabs) ────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) =>
            MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, state) =>
                  const NoTransitionPage(child: DashboardScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/expenses',
              pageBuilder: (_, state) => const NoTransitionPage(
                child: ExpenseListScreen(showBackButton: false),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/budget',
              pageBuilder: (_, state) =>
                  const NoTransitionPage(child: BudgetScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/rewards',
              pageBuilder: (_, state) =>
                  const NoTransitionPage(child: RewardsScreen()),
            ),
          ]),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
