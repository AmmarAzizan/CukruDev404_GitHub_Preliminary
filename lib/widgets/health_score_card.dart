import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/health_score_model.dart';
import '../providers/health_score_provider.dart';

class HealthScoreCard extends ConsumerWidget {
  const HealthScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(healthScoreStreamProvider);

    return scoreAsync.when(
      loading: () => const _Skeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (score) => score == null
          ? _buildEmpty(context)
          : _buildCard(context, score),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Health Score',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add some expenses to see your score.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, HealthScoreModel score) {
    return GestureDetector(
      onTap: () => context.push('/health'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Financial Health Score',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Circular score
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score.score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[100],
                        valueColor:
                            AlwaysStoppedAnimation(score.scoreColor),
                      ),
                    ),
                    Text(
                      '${score.score}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: score.scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status + trend
                      Row(
                        children: [
                          Text(
                            score.status,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: score.scoreColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(score.trendIcon,
                              size: 16, color: score.trendColor),
                          Text(
                            score.trendLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: score.trendColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Mini factor bars
                      _MiniBar(
                        label: 'Budget',
                        value: score.budgetAdherence / 40,
                        color: score.scoreColor,
                      ),
                      const SizedBox(height: 5),
                      _MiniBar(
                        label: 'Saving',
                        value: score.savingProgress / 35,
                        color: score.scoreColor,
                      ),
                      const SizedBox(height: 5),
                      _MiniBar(
                        label: 'Consistency',
                        value: score.spendingConsistency / 25,
                        color: score.scoreColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MiniBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
