import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/reward_model.dart';
import '../../providers/reward_provider.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scale = CurvedAnimation(
        parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardAsync = ref.watch(rewardStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: rewardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => Center(
            child: Text('Failed to load rewards.',
                style: GoogleFonts.poppins(color: AppColors.textMuted)),
          ),
          data: (data) => FadeTransition(
            opacity: _fade,
            child: _buildContent(data),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(RewardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep your streak alive every day!',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _StreakCard(data: data, scaleAnim: _scale),
          const SizedBox(height: 16),
          _NoSpendButton(data: data),
        ],
      ),
    );
  }
}

// ─── Streak card ─────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final RewardData data;
  final Animation<double> scaleAnim;
  const _StreakCard({required this.data, required this.scaleAnim});

  // true = that day was part of the streak
  List<bool> _dots() {
    return List.generate(7, (i) {
      final daysAgo = 6 - i;
      if (!data.recordedToday) {
        return daysAgo >= 1 && daysAgo <= data.currentStreak;
      }
      return daysAgo < data.currentStreak;
    });
  }

  // Date labels for each dot (e.g. "22", "23" ...)
  List<String> _dateLabels() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return '${date.day}';
    });
  }

  String get _milestoneText {
    final s = data.currentStreak;
    if (s >= 30) return "You've hit the highest milestone! 🏆";
    if (s >= 7) {
      final r = 30 - s;
      return '$r more day${r == 1 ? '' : 's'} to 30-Day streak 💪';
    }
    final r = 7 - s;
    return '$r more day${r == 1 ? '' : 's'} to 7-Day streak 📅';
  }

  @override
  Widget build(BuildContext context) {
    final hasStreak = data.currentStreak > 0;
    final dots = _dots();
    final labels = _dateLabels();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasStreak
              ? const [Color(0xFF00897B), Color(0xFF00BFA5)]
              : [Colors.grey.shade600, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (hasStreak ? AppColors.primary : Colors.grey)
                .withValues(alpha: 0.40),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Best streak chip — top right
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    'Best: ${data.longestStreak} day${data.longestStreak == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Flame + number
          ScaleTransition(
            scale: scaleAnim,
            child: Text(
              hasStreak ? '🔥' : '💤',
              style: const TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Text(
              '${data.currentStreak}',
              key: ValueKey(data.currentStreak),
              style: GoogleFonts.poppins(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          Text(
            data.currentStreak == 1 ? 'Day Streak' : 'Days Streak',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 28),

          // 7-day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final filled = dots[i];
              final isToday = i == 6;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.18),
                      border: isToday
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: filled
                        ? const Center(
                            child: Text('🔥',
                                style: TextStyle(fontSize: 17)))
                        : null,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[i],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color:
                          Colors.white.withValues(alpha: isToday ? 1.0 : 0.65),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),

          // Next milestone hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _milestoneText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No Spend Today button ────────────────────────────────────────────────────

class _NoSpendButton extends ConsumerWidget {
  final RewardData data;
  const _NoSpendButton({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorded = data.recordedToday;
    final hasStreak = data.currentStreak > 0;

    final label = recorded
        ? 'Streak Maintained Today ✓'
        : hasStreak
            ? 'No Spend Today'
            : 'Start My Streak! 🔥';

    final icon = recorded
        ? Icons.check_circle_rounded
        : Icons.wb_sunny_outlined;

    return GestureDetector(
      onTap: recorded ? null : () => _tap(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: recorded ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: recorded ? Colors.grey[300]! : AppColors.primary,
            width: 1.5,
          ),
          boxShadow: recorded
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: recorded ? Colors.grey : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: recorded ? Colors.grey : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tap(BuildContext context, WidgetRef ref) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final accepted = await ref
        .read(rewardNotifierProvider.notifier)
        .tapNoSpendToday(uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted ? '🔥 Streak maintained! Keep it up!' : 'Already recorded today.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: accepted ? AppColors.primary : Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Celebration overlay (used from add_expense_screen) ──────────────────────

class BadgeCelebration {
  static Future<void> show(BuildContext context, String badgeId) async {
    final def = BadgeDefinition.all.firstWhere(
      (d) => badgeId.startsWith(d.id),
      orElse: () => BadgeDefinition.all.first,
    );
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Badge earned',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => _CelebrationContent(definition: def),
      transitionBuilder: (_, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _CelebrationContent extends StatefulWidget {
  final BadgeDefinition definition;
  const _CelebrationContent({required this.definition});

  @override
  State<_CelebrationContent> createState() => _CelebrationContentState();
}

class _CelebrationContentState extends State<_CelebrationContent> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'New Badge Earned!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.definition.emoji,
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 10),
              Text(
                widget.definition.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.definition.description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
