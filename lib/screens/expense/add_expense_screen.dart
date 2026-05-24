import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbars.dart';
import '../../models/expense_model.dart';
import '../../models/receipt_data.dart';
import '../../providers/expense_provider.dart';
import '../../providers/health_score_provider.dart';
import '../../providers/reward_provider.dart';
import '../../screens/rewards/rewards_screen.dart';
import '../../services/alert_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/spending_alert_banner.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ReceiptData? prefill;
  const AddExpenseScreen({super.key, this.prefill});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedCategory;
  late DateTime _selectedDate;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    final cats = ref.read(categoryListProvider);
    _selectedCategory = _validCategory(p?.category, cats) ?? cats.first.value;
    _selectedDate = p?.date ?? DateTime.now();
    _amountCtrl = TextEditingController(
      text: (p?.amount != null && p!.amount! > 0)
          ? p.amount!.toStringAsFixed(2)
          : '',
    );
    _noteCtrl = TextEditingController(text: p?.merchant ?? '');

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String? _validCategory(String? cat, List<ExpenseCategory> cats) {
    if (cat == null) return null;
    return cats.any((c) => c.value == cat) ? cat : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', ''));
    final expense = ExpenseModel(
      id: '',
      amount: amount,
      category: _selectedCategory,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
    );
    await ref.read(expenseNotifierProvider.notifier).addExpense(expense);
  }

  Future<void> _handleSaveSuccess() async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Check overspending alerts
      try {
        final alerts = await AlertService().checkAlerts(uid);
        for (final alert in alerts) {
          if (!mounted) break;
          await SpendingAlertBanner.show(context, alert);
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (_) {}

      // Update streak + check badges, show celebration for new ones
      try {
        final newBadges = await ref
            .read(rewardNotifierProvider.notifier)
            .updateStreakAndCheckBadges(uid);
        for (final badgeId in newBadges) {
          if (!mounted) break;
          await BadgeCelebration.show(context, badgeId);
        }
      } catch (_) {}

      // Recalculate health score in background
      ref.read(healthScoreNotifierProvider.notifier).recalculate(uid).ignore();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(successSnackBar('Expense added successfully!'));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final state = ref.watch(expenseNotifierProvider);

    // Auto-reset selected category if it's removed from the budget
    ref.listen<List<ExpenseCategory>>(categoryListProvider, (_, next) {
      if (!next.any((c) => c.value == _selectedCategory)) {
        setState(() => _selectedCategory = next.first.value);
      }
    });

    ref.listen<AsyncValue<void>>(expenseNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) => _handleSaveSuccess(),
        error: (e, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(errorSnackBar(e.toString()));
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                _buildHeader('Add Expense'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _sectionLabel('Category'),
                          const SizedBox(height: 12),
                          _buildCategoryChips(categories),
                          const SizedBox(height: 24),
                          _sectionLabel('Amount'),
                          const SizedBox(height: 8),
                          _buildAmountField(),
                          const SizedBox(height: 20),
                          _sectionLabel('Date'),
                          const SizedBox(height: 8),
                          _buildDateField(),
                          const SizedBox(height: 20),
                          _sectionLabel('Note (Optional)'),
                          const SizedBox(height: 8),
                          _buildNoteField(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: GradientButton(
                    text: 'Save Expense',
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sub-builders ───────────────────────────────────────────────────────────

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
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
            title,
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

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      );

  Widget _buildCategoryChips(List<ExpenseCategory> categories) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final selected = _selectedCategory == cat.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? cat.color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? cat.color : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? cat.color.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: selected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon,
                    size: 16,
                    color: selected ? Colors.white : cat.color),
                const SizedBox(width: 6),
                Text(
                  cat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: _fieldBoxDecoration(),
      child: TextFormField(
        controller: _amountCtrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style:
            GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Please enter an amount';
          final n = double.tryParse(v.trim().replaceAll(',', ''));
          if (n == null) return 'Enter a valid number';
          if (n <= 0) return 'Amount must be greater than 0';
          return null;
        },
        decoration: _fieldDecoration(
          hint: 'e.g. 25.00',
          prefix: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Text('RM',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('d MMMM yyyy').format(_selectedDate),
              style: GoogleFonts.poppins(
                  fontSize: 15, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: _fieldBoxDecoration(),
      child: TextFormField(
        controller: _noteCtrl,
        maxLines: 2,
        maxLength: 100,
        style:
            GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
        decoration: _fieldDecoration(
          hint: 'e.g. Lunch at restaurant',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8, top: 14),
            child: Icon(Icons.notes_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────

  BoxDecoration _fieldBoxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
        prefixIcon: prefix,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        errorStyle: GoogleFonts.poppins(fontSize: 12),
      );
}
