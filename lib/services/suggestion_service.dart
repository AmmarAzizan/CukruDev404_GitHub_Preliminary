import 'package:flutter/material.dart';
import '../models/expense_model.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum SuggestionLevel { positive, warning, critical }

class Suggestion {
  final String text;
  final IconData icon;
  final SuggestionLevel level;

  const Suggestion({
    required this.text,
    required this.icon,
    required this.level,
  });

  Color get color => switch (level) {
        SuggestionLevel.positive => const Color(0xFF4CAF50),
        SuggestionLevel.warning => const Color(0xFFFF9800),
        SuggestionLevel.critical => const Color(0xFFF44336),
      };
}

// ─── Service ──────────────────────────────────────────────────────────────────

class SuggestionService {
  /// Generates 2–3 personalised suggestions from local data only.
  /// Returns an empty list when [expenses] is empty (caller handles that case).
  List<Suggestion> generate({
    required List<ExpenseModel> expenses,
    required double monthlyBudget,
    required double savingTarget,
    required Map<String, double> categoryBudgets,
    required int streak,
  }) {
    if (expenses.isEmpty) return const [];

    // Build category spending map for this month
    final spent = <String, double>{};
    for (final e in expenses) {
      spent[e.category] = (spent[e.category] ?? 0) + e.amount;
    }
    final total = spent.values.fold(0.0, (a, b) => a + b);

    // Pool of (priority, suggestion) — lower priority number = shown first
    final pool = <(int, Suggestion)>[];

    // ── 1. Overall budget status ───────────────────────────────────────────
    if (monthlyBudget > 0) {
      final pct = total / monthlyBudget;
      if (pct > 0.9) {
        pool.add((1, Suggestion(
          text: 'You\'ve used ${(pct * 100).round()}% of your monthly budget. '
              'Slow down your spending for the rest of the month.',
          icon: Icons.speed_rounded,
          level: SuggestionLevel.critical,
        )));
      } else if (pct < 0.5) {
        pool.add((4, Suggestion(
          text: 'You\'ve only used ${(pct * 100).round()}% of your budget — '
              'excellent financial discipline this month!',
          icon: Icons.thumb_up_rounded,
          level: SuggestionLevel.positive,
        )));
      }
    }

    // ── 2. Category overspending (worst offender only) ─────────────────────
    if (categoryBudgets.isNotEmpty) {
      final overBudget = <String, double>{};
      for (final entry in spent.entries) {
        final budgeted = categoryBudgets[entry.key] ?? 0;
        if (budgeted > 0) {
          final ratio = entry.value / budgeted;
          if (ratio > 0.8) overBudget[entry.key] = ratio;
        }
      }
      if (overBudget.isNotEmpty) {
        final worst = overBudget.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        final ratio = worst.value;
        if (ratio > 1.0) {
          pool.add((1, Suggestion(
            text: '${worst.key} spending is at ${(ratio * 100).round()}% of '
                'its budget. ${_reduceTip(worst.key)}',
            icon: Icons.warning_rounded,
            level: SuggestionLevel.critical,
          )));
        } else {
          pool.add((2, Suggestion(
            text: '${worst.key} is at ${(ratio * 100).round()}% of its budget. '
                '${_reduceTip(worst.key)}',
            icon: Icons.trending_up_rounded,
            level: SuggestionLevel.warning,
          )));
        }
      }
    }

    // ── 3. Saving target progress ──────────────────────────────────────────
    if (savingTarget > 0 && monthlyBudget > 0) {
      final projected = monthlyBudget - total;
      if (projected < savingTarget) {
        final cut = _topNonEssential(spent);
        pool.add((2, Suggestion(
          text: cut != null
              ? 'You\'re behind on your saving target. Cutting $cut spending '
                  'this week could help you reach it.'
              : 'You\'re behind on your saving target. Review your spending '
                  'to save more this month.',
          icon: Icons.savings_rounded,
          level: SuggestionLevel.warning,
        )));
      }
    }

    // ── 4. Top spending category tip ───────────────────────────────────────
    if (spent.isNotEmpty) {
      final top =
          spent.entries.reduce((a, b) => a.value > b.value ? a : b);
      pool.add((3, Suggestion(
        text: _topCategoryTip(top.key),
        icon: _categoryIcon(top.key),
        level: SuggestionLevel.warning,
      )));
    }

    // ── 5. Streak motivation ───────────────────────────────────────────────
    if (streak > 0) {
      pool.add((4, Suggestion(
        text: 'You\'re on a $streak-day tracking streak! '
            'Keep it up to stay on top of your finances.',
        icon: Icons.local_fire_department_rounded,
        level: SuggestionLevel.positive,
      )));
    }

    // Sort by priority and cap at 3
    pool.sort((a, b) => a.$1.compareTo(b.$1));
    var results = pool.map((p) => p.$2).take(3).toList();

    // Guarantee minimum 2
    if (results.length < 2) {
      final fallbacks = _fallbacks();
      results = [...results, ...fallbacks.take(2 - results.length)];
    }

    return results;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _reduceTip(String category) => switch (category) {
        'Food' => 'Try cooking at home more this week.',
        'Transport' => 'Consider carpooling or public transport.',
        'Entertainment' => 'Look for free alternatives.',
        'Shopping' => 'Apply the 24-hour rule before buying.',
        'Education' => 'Check for free resources online.',
        'Health' => 'Schedule preventive care to avoid bigger costs.',
        _ => 'Review this category to find savings.',
      };

  String _topCategoryTip(String category) => switch (category) {
        'Food' => 'Food is your top expense this month. '
            'Meal prepping can significantly cut daily costs.',
        'Transport' => 'Transport is your top expense. '
            'Public transport or carpooling could save you more.',
        'Entertainment' => 'Entertainment is your top expense. '
            'Try free events, parks, or streaming alternatives.',
        'Shopping' => 'Shopping is your top expense. '
            'Wait 24 hours before non-essential purchases.',
        'Education' => 'Education is your top expense. '
            'Explore free online courses and open-access materials.',
        'Health' => 'Health is your top expense. '
            'Preventive checkups can reduce bigger costs later.',
        _ => 'Review your top spending category to find opportunities to save.',
      };

  IconData _categoryIcon(String category) => switch (category) {
        'Food' => Icons.restaurant_rounded,
        'Transport' => Icons.directions_car_rounded,
        'Entertainment' => Icons.sports_esports_rounded,
        'Shopping' => Icons.shopping_bag_rounded,
        'Education' => Icons.school_rounded,
        'Health' => Icons.favorite_rounded,
        _ => Icons.category_rounded,
      };

  String? _topNonEssential(Map<String, double> spent) {
    const nonEssential = ['Entertainment', 'Shopping', 'Others'];
    String? result;
    double max = 0;
    for (final cat in nonEssential) {
      if ((spent[cat] ?? 0) > max) {
        max = spent[cat]!;
        result = cat;
      }
    }
    return max > 0 ? result : null;
  }

  List<Suggestion> _fallbacks() => const [
        Suggestion(
          text: 'Review your spending patterns regularly '
              'to stay on track with your financial goals.',
          icon: Icons.analytics_rounded,
          level: SuggestionLevel.positive,
        ),
        Suggestion(
          text: 'Small daily savings add up. Try to identify '
              'one expense you can reduce this week.',
          icon: Icons.lightbulb_rounded,
          level: SuggestionLevel.positive,
        ),
      ];
}
