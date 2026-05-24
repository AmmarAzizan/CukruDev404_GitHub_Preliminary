import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_score_model.dart';

class HealthScoreService {
  static final HealthScoreService _instance = HealthScoreService._internal();
  factory HealthScoreService() => _instance;
  HealthScoreService._internal();

  final _db = FirebaseFirestore.instance;

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Stream<HealthScoreModel?> watchCurrentScore(String uid) {
    final key = _monthKey(DateTime.now());
    return _db
        .collection('users')
        .doc(uid)
        .collection('healthScores')
        .doc(key)
        .snapshots()
        .map((snap) => snap.exists
            ? HealthScoreModel.fromFirestore(snap.data()!)
            : null);
  }

  Future<HealthScoreModel> calculate(String uid) async {
    final now = DateTime.now();
    final monthKey = _monthKey(now);

    // ── Load data ────────────────────────────────────────────────────────────

    final profileDoc =
        await _db.collection('users').doc(uid).get();
    final profile = profileDoc.data() ?? {};
    final monthlyBudget = (profile['monthlyBudget'] as num? ?? 0).toDouble();
    final savingTarget = (profile['savingTarget'] as num? ?? 0).toDouble();

    final budgetDoc = await _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(monthKey)
        .get();

    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final txSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    // ── Compute totals ───────────────────────────────────────────────────────

    double totalSpent = 0;
    final dailyTotals = <int, double>{};
    for (final doc in txSnap.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final date = (data['date'] as Timestamp).toDate();
      totalSpent += amount;
      dailyTotals[date.day] = (dailyTotals[date.day] ?? 0) + amount;
    }

    double totalBudgeted = 0;
    if (budgetDoc.exists) {
      final cats = budgetDoc.data()!['categories'] as List<dynamic>? ?? [];
      for (final c in cats) {
        totalBudgeted += ((c['amount'] as num?) ?? 0).toDouble();
      }
    }

    // ── Factor 1: Budget Adherence (0–40) ────────────────────────────────────

    int budgetAdherence;
    if (totalBudgeted <= 0) {
      budgetAdherence = 20;
    } else {
      final ratio = totalSpent / totalBudgeted;
      if (ratio <= 0.60) {
        budgetAdherence = 40;
      } else if (ratio <= 0.80) {
        budgetAdherence = 30;
      } else if (ratio <= 1.00) {
        budgetAdherence = 20;
      } else {
        budgetAdherence = 5;
      }
    }

    // ── Factor 2: Saving Progress (0–35) ─────────────────────────────────────

    int savingProgress;
    final saved = monthlyBudget - totalSpent;
    if (savingTarget <= 0) {
      savingProgress = saved > 0 ? 35 : 10;
    } else {
      final ratio = saved / savingTarget;
      if (ratio >= 1.0) {
        savingProgress = 35;
      } else if (ratio >= 0.50) {
        savingProgress = 26;
      } else if (ratio > 0) {
        savingProgress = 12;
      } else {
        savingProgress = 0;
      }
    }

    // ── Factor 3: Spending Consistency (0–25) ────────────────────────────────

    int spendingConsistency;
    if (dailyTotals.length < 3) {
      spendingConsistency = 18;
    } else {
      final values = dailyTotals.values.toList();
      final mean = values.reduce((a, b) => a + b) / values.length;
      if (mean <= 0) {
        spendingConsistency = 25;
      } else {
        final variance =
            values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
                values.length;
        final stdDev = sqrt(variance);
        final cv = stdDev / mean;
        if (cv <= 0.5) {
          spendingConsistency = 25;
        } else if (cv <= 1.0) {
          spendingConsistency = 15;
        } else {
          spendingConsistency = 5;
        }
      }
    }

    // ── Total score & status ─────────────────────────────────────────────────

    final score = budgetAdherence + savingProgress + spendingConsistency;
    String status;
    if (score >= 80) {
      status = 'Excellent';
    } else if (score >= 65) {
      status = 'Good';
    } else if (score >= 50) {
      status = 'Fair';
    } else {
      status = 'Needs Improvement';
    }

    // ── Trend ────────────────────────────────────────────────────────────────

    final prevMonthDate = DateTime(now.year, now.month - 1);
    final prevSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('healthScores')
        .doc(_monthKey(prevMonthDate))
        .get();

    String trend = 'stable';
    if (prevSnap.exists) {
      final prevScore = (prevSnap.data()!['score'] as num? ?? 0).toInt();
      final diff = score - prevScore;
      if (diff > 5) {
        trend = 'improving';
      } else if (diff < -5) {
        trend = 'declining';
      }
    }

    // ── Tips ─────────────────────────────────────────────────────────────────

    final tips = <String>[];
    if (score >= 80) {
      tips.add('Great job! You\'re managing your money well this month.');
    } else {
      final baPct = budgetAdherence / 40;
      final spPct = savingProgress / 35;
      final scPct = spendingConsistency / 25;

      final factors = [
        (pct: baPct, tip: 'Try to reduce spending in your highest category this week.'),
        (pct: spPct, tip: 'You\'re behind on your saving target. Try cutting discretionary spending.'),
        (pct: scPct, tip: 'Your spending has big spikes. Try to spread expenses more evenly.'),
      ]..sort((a, b) => a.pct.compareTo(b.pct));

      tips.add(factors[0].tip);
      if (factors[1].pct < 0.7) tips.add(factors[1].tip);
    }

    // ── Save & return ─────────────────────────────────────────────────────────

    final model = HealthScoreModel(
      month: monthKey,
      score: score,
      status: status,
      budgetAdherence: budgetAdherence,
      savingProgress: savingProgress,
      spendingConsistency: spendingConsistency,
      trend: trend,
      tips: tips,
      calculatedAt: DateTime.now(),
    );

    await _db
        .collection('users')
        .doc(uid)
        .collection('healthScores')
        .doc(monthKey)
        .set(model.toMap());

    return model;
  }
}
