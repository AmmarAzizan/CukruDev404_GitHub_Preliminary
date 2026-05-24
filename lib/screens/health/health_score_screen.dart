import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/health_score_model.dart';
import '../../providers/health_score_provider.dart';

class HealthScoreScreen extends ConsumerStatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  ConsumerState<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends ConsumerState<HealthScoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _recalculate();
  }

  Future<void> _recalculate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await ref.read(healthScoreNotifierProvider.notifier).recalculate(uid);
    if (mounted) _animCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(healthScoreStreamProvider);
    final isCalculating =
        ref.watch(healthScoreNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: scoreAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, _) => Center(
                  child: Text('Failed to load score.',
                      style: GoogleFonts.poppins(color: AppColors.textMuted)),
                ),
                data: (score) {
                  if (isCalculating && score == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }
                  if (score == null) return _buildEmpty();
                  return _buildContent(score);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
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
            'Financial Health',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.monitor_heart_outlined,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'No Data Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see your financial health score.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HealthScoreModel score) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        children: [
          // ── Score circle ───────────────────────────────────────────────
          _ScoreCircle(score: score, progress: _progress),
          const SizedBox(height: 32),

          // ── Factor breakdown ───────────────────────────────────────────
          _sectionTitle('Score Breakdown'),
          const SizedBox(height: 12),
          _FactorCard(
            label: 'Budget Adherence',
            icon: Icons.account_balance_wallet_rounded,
            value: score.budgetAdherence,
            max: 40,
            progress: _progress,
          ),
          const SizedBox(height: 10),
          _FactorCard(
            label: 'Saving Progress',
            icon: Icons.savings_rounded,
            value: score.savingProgress,
            max: 35,
            progress: _progress,
          ),
          const SizedBox(height: 10),
          _FactorCard(
            label: 'Spending Consistency',
            icon: Icons.show_chart_rounded,
            value: score.spendingConsistency,
            max: 25,
            progress: _progress,
          ),
          const SizedBox(height: 28),

          // ── Tips ───────────────────────────────────────────────────────
          if (score.tips.isNotEmpty) ...[
            _sectionTitle('Tips for You'),
            const SizedBox(height: 12),
            ...score.tips.map((tip) => _TipCard(tip: tip)),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      );
}

// ─── Score circle ─────────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final HealthScoreModel score;
  final Animation<double> progress;
  const _ScoreCircle({required this.score, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: progress,
          builder: (_, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: (score.score / 100) * progress.value,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[100],
                  valueColor:
                      AlwaysStoppedAnimation(score.scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(score.score * progress.value).toInt()}',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: score.scoreColor,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Status badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: score.scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            score.status,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: score.scoreColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Trend row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(score.trendIcon, size: 18, color: score.trendColor),
            const SizedBox(width: 4),
            Text(
              score.trendLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: score.trendColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Factor card ──────────────────────────────────────────────────────────────

class _FactorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int max;
  final Animation<double> progress;

  const _FactorCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.progress,
  });

  Color get _barColor {
    final pct = value / max;
    if (pct >= 0.75) return const Color(0xFF2ECC71);
    if (pct >= 0.5) return const Color(0xFFE67E22);
    return const Color(0xFFE74C3C);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _barColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                '$value / $max',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: progress,
            builder: (_, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / max) * progress.value,
                minHeight: 7,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tip card ─────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFECB3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFFF9A825), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF795548),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
