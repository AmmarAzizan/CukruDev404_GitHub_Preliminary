import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbars.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/gradient_button.dart';

class BudgetReviewScreen extends ConsumerStatefulWidget {
  final BudgetReviewArgs args;
  const BudgetReviewScreen({super.key, required this.args});

  @override
  ConsumerState<BudgetReviewScreen> createState() =>
      _BudgetReviewScreenState();
}

class _BudgetReviewScreenState extends ConsumerState<BudgetReviewScreen> {
  late List<BudgetCategory> _categories;
  late List<TextEditingController> _controllers;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.args.categories);
    _controllers = _categories
        .map((c) => TextEditingController(text: c.amount.toStringAsFixed(2)))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total => _categories.fold(0.0, (s, c) => s + c.amount);

  void _syncAmount(int index, String value) {
    final amount = double.tryParse(value.replaceAll(',', '')) ?? 0;
    setState(() {
      _categories[index] = _categories[index].copyWith(amount: amount);
    });
  }

  void _deleteAt(int index) {
    _controllers[index].dispose();
    setState(() {
      _controllers.removeAt(index);
      _categories.removeAt(index);
    });
  }

  void _addCategory(BudgetCategory cat) {
    setState(() {
      _categories.add(cat);
      _controllers.add(
          TextEditingController(text: cat.amount.toStringAsFixed(2)));
    });
  }

  Future<void> _regenerate() async {
    setState(() => _isRegenerating = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) return;
      final cats = await AiService().generateBudget(
        profileType: profile['profileType'] as String,
        monthlyBudget: (profile['monthlyBudget'] as num).toDouble(),
        savingTarget: (profile['savingTarget'] as num? ?? 0).toDouble(),
      );
      if (!mounted) return;
      for (final c in _controllers) {
        c.dispose();
      }
      setState(() {
        _categories = cats;
        _controllers = cats
            .map((c) =>
                TextEditingController(text: c.amount.toStringAsFixed(2)))
            .toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              errorSnackBar('Failed to regenerate. Check your connection.'));
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _save() async {
    await ref.read(budgetNotifierProvider.notifier).saveBudget(_categories);
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(budgetNotifierProvider);
    final monthlyBudget = _getBudgetLimit();

    ref.listen<AsyncValue<void>>(budgetNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(successSnackBar('Budget saved!'));
          if (widget.args.fromSetup) {
            context.go('/home');
          } else {
            context.pop();
          }
        },
        error: (e, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(errorSnackBar(e.toString()));
        },
      );
    });

    final isOverBudget = monthlyBudget != null && _total > monthlyBudget;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Row(
                children: [
                  if (!widget.args.fromSetup) ...[
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
                  Expanded(
                    child: Text(
                      'Review Budget',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  // Regenerate button
                  GestureDetector(
                    onTap: _isRegenerating ? null : _regenerate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isRegenerating
                            ? Colors.grey[100]
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isRegenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_fix_high_rounded,
                                    size: 15, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Text(
                                  'Regenerate',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.auto_fix_high_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'AI-generated — edit amounts as needed',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Category list ─────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categories.length + 1,
                itemBuilder: (context, i) {
                  if (i == _categories.length) {
                    return _buildAddButton();
                  }
                  return _buildCategoryCard(i);
                },
              ),
            ),

            // ── Total + Save ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Budget',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      Text(
                        'RM ${_total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isOverBudget
                              ? Colors.red[500]
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (isOverBudget) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.red[400]),
                        const SizedBox(width: 6),
                        Text(
                          'Exceeds monthly budget of RM ${monthlyBudget.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.red[400]),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  GradientButton(
                    text: 'Save Budget',
                    isLoading: saveState.isLoading,
                    onPressed: saveState.isLoading ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(int index) {
    final cat = _categories[index];
    return Dismissible(
      key: ValueKey('${cat.category}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteAt(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: cat.flutterColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.flutterColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cat.flutterIcon, color: cat.flutterColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat.category,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
              ),
              // Amount field
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _controllers[index],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  onChanged: (v) => _syncAmount(index, v),
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                  decoration: InputDecoration(
                    prefixText: 'RM ',
                    prefixStyle: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddCategorySheet(onAdd: _addCategory),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
              style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _getBudgetLimit() {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) return null;
    return (profile['monthlyBudget'] as num?)?.toDouble();
  }
}

// ─── Add Category Bottom Sheet ────────────────────────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  final void Function(BudgetCategory) onAdd;
  const _AddCategorySheet({required this.onAdd});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedIcon = 'category';
  String _selectedColor = '#00897B';

  static final _iconEntries = BudgetCategory.iconMap.entries.toList();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
    if (name.isEmpty) return;
    widget.onAdd(BudgetCategory(
      category: name,
      icon: _selectedIcon,
      amount: amount,
      color: _selectedColor,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Category',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 20),

            // Name field
            _label('Category Name'),
            const SizedBox(height: 8),
            _inputField(
                controller: _nameCtrl, hint: 'e.g. Groceries'),
            const SizedBox(height: 16),

            // Amount field
            _label('Budgeted Amount (RM)'),
            const SizedBox(height: 8),
            _inputField(
                controller: _amountCtrl,
                hint: 'e.g. 200.00',
                isNumber: true),
            const SizedBox(height: 16),

            // Icon picker
            _label('Icon'),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _iconEntries.length,
              itemBuilder: (_, i) {
                final entry = _iconEntries[i];
                final sel = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(entry.value,
                        size: 22,
                        color: sel
                            ? AppColors.primary
                            : Colors.grey[500]),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Color picker
            _label('Color'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: BudgetCategory.presetColors.map((hex) {
                final sel = _selectedColor == hex;
                final color = BudgetCategory(
                        category: '',
                        icon: '',
                        amount: 0,
                        color: hex)
                    .flutterColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.black54 : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Add Category',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600]));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style:
              GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      );
}
