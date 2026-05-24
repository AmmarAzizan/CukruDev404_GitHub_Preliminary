import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbars.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/profile_provider.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(currentBudgetProvider);
    final categorySpent = ref.watch(categoryBreakdownProvider);
    final generationState = ref.watch(budgetGenerationProvider);

    // Navigate to review when AI generation completes
    ref.listen<AsyncValue<List<BudgetCategory>?>>(budgetGenerationProvider,
        (prev, next) {
      if (prev?.isLoading == true &&
          next.hasValue &&
          next.valueOrNull != null) {
        final cats = next.valueOrNull!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(budgetGenerationProvider.notifier).reset();
          context.push('/budget/review',
              extra: BudgetReviewArgs(categories: cats, fromSetup: false));
        });
      } else if (next.hasError && prev?.isLoading == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(errorSnackBar('${next.error}'));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: budgetAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
              child: Text('Error loading budget.',
                  style: GoogleFonts.poppins(color: AppColors.textMuted))),
          data: (budget) => budget == null
              ? _buildEmptyState(context, generationState)
              : _buildContent(
                  context, budget, categorySpent, generationState),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context,
      AsyncValue<List<BudgetCategory>?> generationState) {
    return Column(
      children: [
        _buildHeader(context, generationState, isEmpty: true),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.pie_chart_outline_rounded,
                      color: AppColors.primary, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Budget Yet',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let AI plan your monthly budget\nbased on your financial profile.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 28),
                _RegenerateButton(
                  isLoading: generationState.isLoading,
                  label: 'Generate My Budget',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    BudgetModel budget,
    Map<String, double> categorySpent,
    AsyncValue<List<BudgetCategory>?> generationState,
  ) {
    final totalSpent = budget.categories
        .fold<double>(0, (s, c) => s + (categorySpent[c.category] ?? 0));
    final totalBudget = budget.totalBudgeted;
    final now = DateTime.now();

    return Column(
      children: [
        _buildHeader(context, generationState),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            DateFormat('MMMM yyyy').format(now),
            style:
                GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 16),
        // Total summary card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _TotalCard(totalSpent: totalSpent, totalBudget: totalBudget),
        ),
        const SizedBox(height: 16),
        // Category list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            itemCount: budget.categories.length,
            itemBuilder: (_, i) {
              final cat = budget.categories[i];
              final spent = categorySpent[cat.category] ?? 0;
              return _CategoryCard(category: cat, spent: spent);
            },
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<List<BudgetCategory>?> generationState, {
    bool isEmpty = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
      child: Row(
        children: [
          Text(
            'My Budget',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const Spacer(),
          if (!isEmpty)
            _RegenerateButton(
              isLoading: generationState.isLoading,
              label: 'Regenerate',
              compact: true,
            ),
        ],
      ),
    );
  }
}

// ─── Regenerate button ────────────────────────────────────────────────────────

class _RegenerateButton extends ConsumerWidget {
  final bool isLoading;
  final String label;
  final bool compact;

  const _RegenerateButton({
    required this.isLoading,
    required this.label,
    this.compact = false,
  });

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) return;
    ref.read(budgetGenerationProvider.notifier).generate(
          profileType: profile['profileType'] as String,
          monthlyBudget: (profile['monthlyBudget'] as num).toDouble(),
          savingTarget: (profile['savingTarget'] as num? ?? 0).toDouble(),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return GestureDetector(
        onTap: isLoading ? null : () => _generate(context, ref),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isLoading
                ? Colors.grey[100]
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_fix_high_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(label,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
        ),
      );
    }

    return GestureDetector(
      onTap: isLoading ? null : () => _generate(context, ref),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          color: isLoading ? Colors.grey[200] : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text('Generating...',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted)),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
      ),
    );
  }
}

// ─── Total summary card ───────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final double totalSpent;
  final double totalBudget;
  const _TotalCard({required this.totalSpent, required this.totalBudget});

  @override
  Widget build(BuildContext context) {
    final pct = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final color = pct <= 0.6
        ? const Color(0xFF2ECC71)
        : pct <= 0.85
            ? const Color(0xFFE67E22)
            : Colors.red[500]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Spent',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8))),
                  Text('RM ${totalSpent.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Budget',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8))),
                  Text('RM ${totalBudget.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% of budget used',
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

// ─── Category progress card ───────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final double spent;
  const _CategoryCard({required this.category, required this.spent});

  @override
  Widget build(BuildContext context) {
    final pct = category.amount > 0
        ? (spent / category.amount).clamp(0.0, 1.0)
        : 0.0;
    final barColor = pct <= 0.6
        ? const Color(0xFF2ECC71)
        : pct <= 0.85
            ? const Color(0xFFE67E22)
            : Colors.red[500]!;
    final catColor = category.flutterColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: catColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.flutterIcon,
                    color: catColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.category,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    Text(
                      'RM ${spent.toStringAsFixed(2)} / RM ${category.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
