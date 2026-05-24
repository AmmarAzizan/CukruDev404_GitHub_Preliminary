import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/gradient_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedType;
  bool _isLoading = true;

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
      duration: const Duration(milliseconds: 450),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(profileServiceProvider).getUserProfile();
      if (!mounted) return;
      const validTypes = ['student', 'employed', 'unemployed'];
      final raw = profile?['profileType'] as String? ?? '';
      setState(() {
        _selectedType = validTypes.contains(raw) ? raw : null;
        final budget = profile?['monthlyBudget'];
        final saving = profile?['savingTarget'];
        _budgetCtrl.text =
            budget != null ? (budget as num).toStringAsFixed(2) : '';
        _savingCtrl.text =
            saving != null && saving != 0 ? (saving as num).toStringAsFixed(2) : '';
        _isLoading = false;
      });
      _animCtrl.forward();
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _save() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Please select a profile type.',
                style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final budget =
        double.tryParse(_budgetCtrl.text.trim().replaceAll(',', '')) ?? 0;
    final saving =
        double.tryParse(_savingCtrl.text.trim().replaceAll(',', '')) ?? 0;
    await ref.read(profileSetupProvider.notifier).updateProfile(
          profileType: _selectedType!,
          monthlyBudget: budget,
          savingTarget: saving,
        );
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
    final saveState = ref.watch(profileSetupProvider);

    ref.listen<AsyncValue<void>>(profileSetupProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.invalidate(userProfileProvider);
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text('Profile updated successfully!',
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ],
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          context.pop();
        },
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

    if (_isLoading) {
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
                // Header
                Padding(
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
                        'Edit Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Scrollable form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Type',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ProfileTypeCard(
                            emoji: '🎓',
                            label: 'Student',
                            subtitle: 'University or school student',
                            value: 'student',
                            isSelected: _selectedType == 'student',
                            onTap: () =>
                                setState(() => _selectedType = 'student'),
                          ),
                          const SizedBox(height: 12),
                          _ProfileTypeCard(
                            emoji: '💼',
                            label: 'Employed',
                            subtitle: 'Has a steady income',
                            value: 'employed',
                            isSelected: _selectedType == 'employed',
                            onTap: () =>
                                setState(() => _selectedType = 'employed'),
                          ),
                          const SizedBox(height: 12),
                          _ProfileTypeCard(
                            emoji: '🏠',
                            label: 'Unemployed',
                            subtitle: 'Dependent on allowance',
                            value: 'unemployed',
                            isSelected: _selectedType == 'unemployed',
                            onTap: () =>
                                setState(() => _selectedType = 'unemployed'),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Financial Details',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _AmountField(
                            label: _budgetLabel,
                            hint: 'e.g. 1200.00',
                            controller: _budgetCtrl,
                            isRequired: true,
                          ),
                          const SizedBox(height: 18),
                          _AmountField(
                            label: 'Saving Target (Optional)',
                            hint: 'e.g. 300.00',
                            controller: _savingCtrl,
                            isRequired: false,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                // Save button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: GradientButton(
                    text: 'Save Changes',
                    isLoading: saveState.isLoading,
                    onPressed: saveState.isLoading ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textMuted),
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
