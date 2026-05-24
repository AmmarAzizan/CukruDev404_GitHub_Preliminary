import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/budget_model.dart';
import '../../providers/profile_provider.dart';
import '../../services/ai_service.dart';
import '../../widgets/gradient_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  int _step = 1;
  String? _selectedType;
  bool _isChecking = true;
  bool _isGeneratingBudget = false;

  final _budgetCtrl = TextEditingController();
  final _savingCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
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
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final isCompleted =
          await ref.read(profileServiceProvider).isProfileCompleted();
      if (!mounted) return;
      if (isCompleted) {
        context.go('/home');
      } else {
        setState(() => _isChecking = false);
        _animCtrl.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isChecking = false);
        _animCtrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _savingCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (_selectedType == null) return;
    setState(() => _step = 2);
    _animCtrl.forward(from: 0);
  }

  void _goToStep1() {
    setState(() => _step = 1);
    _animCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final budget =
        double.tryParse(_budgetCtrl.text.trim().replaceAll(',', '')) ?? 0;
    final saving =
        double.tryParse(_savingCtrl.text.trim().replaceAll(',', '')) ?? 0;
    await ref.read(profileSetupProvider.notifier).saveProfile(
          profileType: _selectedType!,
          monthlyBudget: budget,
          savingTarget: saving,
        );
  }

  Future<void> _generateBudgetAndNavigate() async {
    setState(() => _isGeneratingBudget = true);
    try {
      final budget =
          double.tryParse(_budgetCtrl.text.trim().replaceAll(',', '')) ?? 0;
      final saving =
          double.tryParse(_savingCtrl.text.trim().replaceAll(',', '')) ?? 0;
      final categories = await AiService().generateBudget(
        profileType: _selectedType!,
        monthlyBudget: budget,
        savingTarget: saving,
      );
      if (!mounted) return;
      context.go('/budget/review',
          extra: BudgetReviewArgs(categories: categories, fromSetup: true));
    } catch (_) {
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _isGeneratingBudget = false);
    }
  }

  String get _budgetLabel {
    switch (_selectedType) {
      case 'student':
        return 'Monthly Allowance';
      case 'employed':
        return 'Monthly Income';
      default:
        return 'Monthly Allocation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(profileSetupProvider);

    ref.listen<AsyncValue<void>>(profileSetupProvider, (_, next) {
      next.whenOrNull(
        data: (_) => _generateBudgetAndNavigate(),
        error: (error, _) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(error.toString(),
                    style: GoogleFonts.poppins(fontSize: 13)),
                backgroundColor: Colors.red[400],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
        },
      );
    });

    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: _ProgressBar(step: _step),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _step == 1 ? _buildStep1() : _buildStep2(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                  child: _step == 1
                      ? GradientButton(
                          text: 'Next →',
                          onPressed: _selectedType != null ? _goToStep2 : null,
                        )
                      : GradientButton(
                          text: _isGeneratingBudget
                              ? 'Setting up your budget...'
                              : 'Get Started',
                          isLoading:
                              setupState.isLoading || _isGeneratingBudget,
                          onPressed: (setupState.isLoading ||
                                  _isGeneratingBudget)
                              ? null
                              : _submit,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Profile',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the option that best describes your current situation.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        _ProfileTypeCard(
          emoji: '🎓',
          label: 'Student',
          subtitle: 'University or school student',
          value: 'student',
          isSelected: _selectedType == 'student',
          onTap: () => setState(() => _selectedType = 'student'),
        ),
        const SizedBox(height: 14),
        _ProfileTypeCard(
          emoji: '💼',
          label: 'Employed',
          subtitle: 'Has a steady income',
          value: 'employed',
          isSelected: _selectedType == 'employed',
          onTap: () => setState(() => _selectedType = 'employed'),
        ),
        const SizedBox(height: 14),
        _ProfileTypeCard(
          emoji: '🏠',
          label: 'Unemployed',
          subtitle: 'Dependent on allowance',
          value: 'unemployed',
          isSelected: _selectedType == 'unemployed',
          onTap: () => setState(() => _selectedType = 'unemployed'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _goToStep1,
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
        const SizedBox(height: 24),
        Text(
          'Set Your Budget',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This helps Spendly track your spending accurately.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _AmountField(
                label: _budgetLabel,
                hint: 'e.g. 1200.00',
                controller: _budgetCtrl,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              _AmountField(
                label: 'Saving Target (Optional)',
                hint: 'e.g. 300.00',
                controller: _savingCtrl,
                isRequired: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $step of 2',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [1, 2].map((i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProfileTypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileTypeCard({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;

  const _AmountField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
            validator: isRequired
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(v.trim().replaceAll(',', '')) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  }
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Padding(
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
            ),
          ),
        ),
      ],
    );
  }
}
