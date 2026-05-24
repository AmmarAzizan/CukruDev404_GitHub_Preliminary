import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../models/receipt_data.dart';
import '../../widgets/gradient_button.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final ReceiptData receipt;
  const ReceiptPreviewScreen({super.key, required this.receipt});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _merchantCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;
    _amountCtrl = TextEditingController(
      text: (r.amount != null && r.amount! > 0)
          ? r.amount!.toStringAsFixed(2)
          : '',
    );
    _merchantCtrl =
        TextEditingController(text: r.merchant ?? '');
    _selectedCategory = _validCategory(r.category);
    _selectedDate = r.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  String _validCategory(String? cat) {
    const valid = [
      'Food', 'Transport', 'Entertainment',
      'Shopping', 'Education', 'Health', 'Others'
    ];
    return (cat != null && valid.contains(cat)) ? cat : 'Others';
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

  void _confirm() {
    final raw = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = double.tryParse(raw);
    final prefill = ReceiptData(
      amount: (amount != null && amount > 0) ? amount : null,
      merchant: _merchantCtrl.text.trim().isEmpty
          ? null
          : _merchantCtrl.text.trim(),
      category: _selectedCategory,
      date: _selectedDate,
      imagePath: widget.receipt.imagePath,
    );
    context.push('/expenses/add', extra: prefill);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
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
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.grey[700],
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Review Receipt',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image thumbnail
                    if (widget.receipt.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 170,
                          child: Image.file(
                            File(widget.receipt.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // AI badge
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_fix_high_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Parsed by AI — review and edit before saving',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Form card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Amount (RM)'),
                          const SizedBox(height: 8),
                          _buildAmountField(),
                          const SizedBox(height: 18),
                          _sectionLabel('Description / Merchant'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _merchantCtrl,
                            hint: 'e.g. McDonald\'s',
                            icon: Icons.storefront_rounded,
                          ),
                          const SizedBox(height: 18),
                          _sectionLabel('Category'),
                          const SizedBox(height: 8),
                          _buildCategoryDropdown(),
                          const SizedBox(height: 18),
                          _sectionLabel('Date'),
                          const SizedBox(height: 8),
                          _buildDateField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Bottom actions ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  GradientButton(
                    text: 'Confirm & Add Expense',
                    onPressed: _confirm,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Scan Again',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        height: 16,
                        width: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      TextButton(
                        onPressed: () => context.push('/expenses/add'),
                        child: Text(
                          'Fill Manually',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Field builders ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      );

  Widget _buildAmountField() {
    return Container(
      decoration: _boxDecoration(),
      child: TextFormField(
        controller: _amountCtrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.poppins(
            fontSize: 15, color: AppColors.textDark),
        decoration: _inputDecoration(
          hint: 'e.g. 25.00',
          prefix: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Text(
              'RM',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: _boxDecoration(),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
            fontSize: 15, color: AppColors.textDark),
        decoration: _inputDecoration(
          hint: hint,
          prefix: Padding(
            padding:
                const EdgeInsets.only(left: 14, right: 8, top: 15),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary),
          style: GoogleFonts.poppins(
              fontSize: 14, color: AppColors.textDark),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
          items: kCategories.map((cat) {
            return DropdownMenuItem(
              value: cat.value,
              child: Row(
                children: [
                  Icon(cat.icon, size: 18, color: cat.color),
                  const SizedBox(width: 10),
                  Text(cat.label),
                ],
              ),
            );
          }).toList(),
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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

  BoxDecoration _boxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  InputDecoration _inputDecoration({
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
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      );
}
