import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbars.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const ExpenseListScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _now = DateTime.now();

  void _previousMonth() {
    final cur = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(cur.year, cur.month - 1);
  }

  void _nextMonth() {
    final cur = ref.read(selectedMonthProvider);
    final next = DateTime(cur.year, cur.month + 1);
    final thisMonth = DateTime(_now.year, _now.month);
    if (next.isAfter(thisMonth)) return;
    ref.read(selectedMonthProvider.notifier).state = next;
  }

  bool get _isCurrentMonth {
    final sel = ref.read(selectedMonthProvider);
    return sel.year == _now.year && sel.month == _now.month;
  }

  Future<bool> _confirmAndDelete(
      BuildContext context, ExpenseModel expense) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Expense',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(
          'Delete "${expense.category}" expense of '
          'RM ${expense.amount.toStringAsFixed(2)}?',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.red[400], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    try {
      await ref.read(expenseServiceProvider).deleteExpense(expense.id);
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(successSnackBar('Expense deleted.'));
      }
      return true;
    } catch (_) {
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(errorSnackBar('Failed to delete. Try again.'));
      }
      return false;
    }
  }

  // ─── Date grouping helpers ──────────────────────────────────────────────────

  String _dateLabel(DateTime date) {
    final today = DateTime(_now.year, _now.month, _now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('d MMMM yyyy').format(date);
  }

  Map<String, List<ExpenseModel>> _groupByDate(List<ExpenseModel> list) {
    final groups = <String, List<ExpenseModel>>{};
    for (final e in list) {
      groups.putIfAbsent(_dateLabel(e.date), () => []).add(e);
    }
    return groups;
  }

  // Each element is either a ({String label, double total}) record or
  // an ExpenseModel — used by ListView.builder.
  List<Object> _buildFlatItems(List<ExpenseModel> expenses) {
    final flat = <Object>[];
    final groups = _groupByDate(expenses);
    for (final entry in groups.entries) {
      final dayTotal =
          entry.value.fold<double>(0.0, (s, e) => s + e.amount);
      flat.add((label: entry.key, total: dayTotal));
      flat.addAll(entry.value);
    }
    return flat;
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final filteredAsync = ref.watch(filteredExpensesProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
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
                  ],
                  Text(
                    'Expenses',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  // Scan receipt button
                  GestureDetector(
                    onTap: () => context.push('/expenses/scan'),
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
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Month selector ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  _NavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _isCurrentMonth ? null : _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Monthly total card ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 16),
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
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spending',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          'RM ${monthlyTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    filteredAsync.whenOrNull(
                          data: (list) => Text(
                            '${list.length} item${list.length == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color:
                                  Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ) ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Expense list ─────────────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load expenses.',
                      style: GoogleFonts.poppins(color: AppColors.textMuted)),
                ),
                data: (expenses) {
                  if (expenses.isEmpty) return _buildEmptyState(selectedMonth);
                  final flat = _buildFlatItems(expenses);
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: flat.length,
                    itemBuilder: (context, i) {
                      final item = flat[i];
                      if (item
                          is ({String label, double total})) {
                        return _DateSectionHeader(
                            label: item.label, total: item.total);
                      }
                      final expense = item as ExpenseModel;
                      return _buildExpenseTile(context, expense);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, ExpenseModel expense) {
    final cat = categoryFor(expense.category);
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmAndDelete(context, expense),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      child: GestureDetector(
        onTap: () =>
            context.push('/expenses/edit/${expense.id}', extra: expense),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 14),
              // Label + note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      Text(
                        expense.note!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Amount + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '- RM ${expense.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(expense.date),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DateTime month) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses in ${DateFormat('MMMM').format(month)}',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first expense',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(icon,
            size: 22,
            color: onTap != null ? AppColors.textDark : Colors.grey[400]),
      ),
    );
  }
}

class _DateSectionHeader extends StatelessWidget {
  final String label;
  final double total;
  const _DateSectionHeader({required this.label, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            'RM ${total.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
