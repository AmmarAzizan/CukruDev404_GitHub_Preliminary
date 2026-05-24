import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/gig_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameAsync = ref.watch(userNameProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';

    final budget = ref.watch(currentBudgetProvider).valueOrNull;
    final spending = ref.watch(categoryBreakdownProvider);

    // Detect if any category exceeds 100% of its budget
    final isOverspending = budget != null &&
        budget.categories.any((cat) =>
            cat.amount > 0 &&
            (spending[cat.category] ?? 0) >= cat.amount);

    final profileType =
        profileAsync.valueOrNull?['profileType'] as String? ?? 'student';
    final monthlyBudget =
        (profileAsync.valueOrNull?['monthlyBudget'] as num?)?.toDouble() ?? 0;
    final savingTarget =
        (profileAsync.valueOrNull?['savingTarget'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.grey[700], size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/settings/edit-profile'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // ── Avatar + name + email + badge ──────────────────────
                    Center(
                      child: Column(
                        children: [
                          userNameAsync.when(
                            loading: () => _avatar('?'),
                            error: (_, _) => _avatar('?'),
                            data: (name) => _avatar(
                              name?.isNotEmpty == true
                                  ? name![0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          const SizedBox(height: 14),
                          userNameAsync.when(
                            loading: () => Container(
                              height: 22,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (name) => Text(
                              name ?? 'User',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _profileTypeLabel(profileType),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Financial info card ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Monthly Budget',
                              value: monthlyBudget > 0
                                  ? 'RM ${monthlyBudget.toStringAsFixed(2)}'
                                  : 'Not set',
                            ),
                            if (savingTarget > 0) ...[
                              const Divider(height: 24),
                              _InfoRow(
                                icon: Icons.savings_rounded,
                                label: 'Saving Target',
                                value:
                                    'RM ${savingTarget.toStringAsFixed(2)}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Earn Extra Income ──────────────────────────────────
                    _EarnExtraSection(
                      profileType: profileType,
                      isOverspending: isOverspending,
                    ),
                    const SizedBox(height: 28),

                    // ── Sign Out ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref.read(authServiceProvider).signOut();
                            if (context.mounted) context.go('/login');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.red, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.red,
                          ),
                          child: Text(
                            'Sign Out',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String letter) => Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.poppins(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );

  String _profileTypeLabel(String type) => switch (type) {
        'employed' => 'Employed',
        'unemployed' => 'Unemployed',
        _ => 'Student',
      };
}

// ─── Earn Extra Income section ────────────────────────────────────────────────

class _EarnExtraSection extends StatelessWidget {
  final String profileType;
  final bool isOverspending;

  const _EarnExtraSection({
    required this.profileType,
    required this.isOverspending,
  });

  @override
  Widget build(BuildContext context) {
    final gigs = gigsForProfile(profileType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: isOverspending
              ? _OverspendingBanner()
              : _NormalHeader(),
        ),
        const SizedBox(height: 16),

        // Horizontal scrollable gig cards
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: gigs.length,
            itemBuilder: (_, i) => GigCard(gig: gigs[i]),
          ),
        ),
      ],
    );
  }
}

class _NormalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('💰', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earn Extra Income',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              'Explore ways to boost your income',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverspendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You've exceeded your budget!",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Here are some ways to earn extra:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark),
        ),
      ],
    );
  }
}
