import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_model.dart';

class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  final _db = FirebaseFirestore.instance;

  DocumentReference _doc(String uid) =>
      _db.collection('users').doc(uid).collection('rewards').doc('data');

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  // ── Stream ────────────────────────────────────────────────────────────────

  Stream<RewardData> watchRewards(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return RewardData.empty;
      return RewardData.fromFirestore(
          snap.data() as Map<String, dynamic>);
    });
  }

  // ── Streak update ─────────────────────────────────────────────────────────

  Future<void> updateStreak(String uid) async {
    final snap = await _doc(uid).get();
    final data =
        snap.exists ? snap.data() as Map<String, dynamic> : <String, dynamic>{};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = (data['currentStreak'] as num? ?? 0).toInt();
    int longestStreak = (data['longestStreak'] as num? ?? 0).toInt();
    final lastTs = data['lastRecordedDate'] as Timestamp?;
    final lastDate = lastTs?.toDate();

    if (lastDate != null) {
      final lastDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) return; // Already recorded today — nothing to do
      if (diff == 1) {
        currentStreak += 1;
      } else {
        currentStreak = 1; // Gap detected, reset
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await _doc(uid).set({
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastRecordedDate': Timestamp.fromDate(today),
      'badges': data['badges'] ?? [],
    }, SetOptions(merge: true));
  }

  // ── No Spend Today ────────────────────────────────────────────────────────

  Future<bool> tapNoSpendToday(String uid) async {
    final snap = await _doc(uid).get();
    final data =
        snap.exists ? snap.data() as Map<String, dynamic> : <String, dynamic>{};
    final lastTs = data['lastRecordedDate'] as Timestamp?;
    final lastDate = lastTs?.toDate();
    final now = DateTime.now();

    if (lastDate != null &&
        lastDate.year == now.year &&
        lastDate.month == now.month &&
        lastDate.day == now.day) {
      return false; // Already tapped today
    }

    await updateStreak(uid);
    return true;
  }

  // ── Badge check ───────────────────────────────────────────────────────────

  Future<List<String>> checkAndAwardBadges(String uid) async {
    final snap = await _doc(uid).get();
    final data =
        snap.exists ? snap.data() as Map<String, dynamic> : <String, dynamic>{};
    final rewards = snap.exists
        ? RewardData.fromFirestore(data)
        : RewardData.empty;

    final earnedIds = rewards.earnedBadges.map((b) => b.id).toSet();
    final newlyEarned = <EarnedBadge>[];
    final now = DateTime.now();
    final monthKey = _monthKey(now);

    // ── First Step ────────────────────────────────────────────────────────
    const firstStepId = 'first_step';
    if (!earnedIds.contains(firstStepId)) {
      final tx = await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .limit(1)
          .get();
      if (tx.docs.isNotEmpty) {
        newlyEarned.add(EarnedBadge(
            id: firstStepId, name: 'First Step', earnedAt: now));
      }
    }

    // ── Streak 7 ──────────────────────────────────────────────────────────
    const streak7Id = 'streak_7';
    if (!earnedIds.contains(streak7Id) && rewards.currentStreak >= 7) {
      newlyEarned.add(EarnedBadge(
          id: streak7Id, name: '7-Day Streak', earnedAt: now));
    }

    // ── Streak 30 ─────────────────────────────────────────────────────────
    const streak30Id = 'streak_30';
    if (!earnedIds.contains(streak30Id) && rewards.currentStreak >= 30) {
      newlyEarned.add(EarnedBadge(
          id: streak30Id, name: '30-Day Streak', earnedAt: now));
    }

    // ── Budget Master (monthly) ────────────────────────────────────────────
    final budgetMasterId = 'budget_master_$monthKey';
    if (!earnedIds.contains(budgetMasterId)) {
      final budgetDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .doc(monthKey)
          .get();
      if (budgetDoc.exists) {
        final cats =
            budgetDoc.data()?['categories'] as List<dynamic>? ?? [];
        double totalBudgeted = 0;
        for (final c in cats) {
          totalBudgeted += ((c['amount'] as num?) ?? 0).toDouble();
        }
        final totalSpent = await _getMonthlySpent(uid, now);
        if (totalBudgeted > 0 && totalSpent <= totalBudgeted) {
          newlyEarned.add(EarnedBadge(
              id: budgetMasterId, name: 'Budget Master', earnedAt: now));
        }
      }
    }

    // ── Saving Hero (monthly) ─────────────────────────────────────────────
    final savingHeroId = 'saving_hero_$monthKey';
    if (!earnedIds.contains(savingHeroId)) {
      final profileDoc =
          await _db.collection('users').doc(uid).get();
      final savingTarget =
          (profileDoc.data()?['savingTarget'] as num? ?? 0).toDouble();
      final monthlyBudget =
          (profileDoc.data()?['monthlyBudget'] as num? ?? 0).toDouble();
      if (savingTarget > 0) {
        final totalSpent = await _getMonthlySpent(uid, now);
        if (monthlyBudget - totalSpent >= savingTarget) {
          newlyEarned.add(EarnedBadge(
              id: savingHeroId, name: 'Saving Hero', earnedAt: now));
        }
      }
    }

    // ── Health Champion (monthly) ─────────────────────────────────────────
    final healthChampionId = 'health_champion_$monthKey';
    if (!earnedIds.contains(healthChampionId)) {
      final healthDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('healthScores')
          .doc(monthKey)
          .get();
      if (healthDoc.exists) {
        final score =
            (healthDoc.data()?['score'] as num? ?? 0).toInt();
        if (score >= 80) {
          newlyEarned.add(EarnedBadge(
              id: healthChampionId,
              name: 'Health Champion',
              earnedAt: now));
        }
      }
    }

    // ── Save new badges ───────────────────────────────────────────────────
    if (newlyEarned.isNotEmpty) {
      final updatedBadges = [
        ...rewards.earnedBadges.map((b) => b.toMap()),
        ...newlyEarned.map((b) => b.toMap()),
      ];
      await _doc(uid).set({'badges': updatedBadges}, SetOptions(merge: true));
    }

    return newlyEarned.map((b) => b.id).toList();
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<double> _getMonthlySpent(String uid, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.fold<double>(
        0, (s, d) => s + ((d.data()['amount'] as num?) ?? 0).toDouble());
  }
}
