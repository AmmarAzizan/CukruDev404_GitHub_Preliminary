import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbars.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/gradient_button.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen>
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
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
    _amountCtrl =
        TextEditingController(text: widget.expense.amount.toStringAsFixed(2));
    _noteCtrl =
        TextEditingController(text: widget.expense.note ?? '');

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
    final updated = widget.expense.copyWith(
      amount: amount,
      category: _selectedCategory,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: _selectedDate,
    );
    await ref.read(expenseNotifierProvider.notifier).updateExpense(updated);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseNotifierProvider);

    ref.listen<AsyncValue<void>>(expenseNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(successSnackBar('Expense updated successfully!'));
          context.pop();
        },
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
                _buildHeader(),
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
                          _buildCategoryChips(),
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
                    text: 'Update Expense',
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

  Widget _buildHeader() {
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
            'Edit Expense',
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

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kCategories.map((cat) {
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
                    color:
                        selected ? Colors.white : AppColors.textDark,
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
            padding:
                EdgeInsets.only(left: 14, right: 8, top: 14),
            child: Icon(Icons.notes_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

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
