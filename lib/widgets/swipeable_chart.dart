import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class SwipeableChartCard extends ConsumerStatefulWidget {
  const SwipeableChartCard({super.key});

  @override
  ConsumerState<SwipeableChartCard> createState() =>
      _SwipeableChartCardState();
}

class _SwipeableChartCardState extends ConsumerState<SwipeableChartCard> {
  final _controller = PageController();
  int _page = 0;

  static const _titles = ['Spending by Category', 'Daily Spending'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(categoryBreakdownProvider);
    final daily = ref.watch(dailySpendingProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Text(
              _titles[_page],
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Swipeable chart area
          SizedBox(
            height: 188,
            child: PageView(
              controller: _controller,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _PieChartPage(breakdown: breakdown),
                _BarChartPage(daily: daily),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppColors.primary
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─── Pie chart page ───────────────────────────────────────────────────────────

class _PieChartPage extends StatelessWidget {
  final Map<String, double> breakdown;
  const _PieChartPage({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return _empty();

    final total =
        breakdown.values.fold(0.0, (s, v) => s + v);

    final sections = breakdown.entries.map((e) {
      final cat = categoryFor(e.key);
      return PieChartSectionData(
        value: e.value,
        color: cat.color,
        title: '',
        radius: 54,
      );
    }).toList();

    // Sort legend by amount descending, cap at 5 items
    final legendEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 38,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legendEntries.take(5).map((e) {
                final cat = categoryFor(e.key);
                final pct = (e.value / total * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cat.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Text(
          'No expenses this month',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      );
}

// ─── Bar chart page ───────────────────────────────────────────────────────────

class _BarChartPage extends StatelessWidget {
  final Map<int, double> daily;
  const _BarChartPage({required this.daily});

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return Center(
        child: Text(
          'No expenses this month',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final maxVal =
        daily.values.isEmpty ? 1.0 : daily.values.reduce(max);

    final groups = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: daily[day] ?? 0,
            color: AppColors.primary,
            width: 5,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: BarChart(
        BarChartData(
          barGroups: groups,
          maxY: maxVal * 1.35,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (day != 1 && day % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '$day',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                'RM ${rod.toY.toStringAsFixed(2)}',
                GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
