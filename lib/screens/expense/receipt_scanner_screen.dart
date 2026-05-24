import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/receipt_provider.dart';

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState
    extends ConsumerState<ReceiptScannerScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Reset any previous scan state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptScannerProvider.notifier).reset();
    });
  }

  // ─── Image picking ───────────────────────────────────────────────────────

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1920,
      );
      if (picked == null) return; // user cancelled
      if (!mounted) return;
      await ref
          .read(receiptScannerProvider.notifier)
          .processImage(picked.path);
    } on PlatformException {
      if (mounted) {
        ref.read(receiptScannerProvider.notifier).setError(
              source == ImageSource.camera
                  ? 'Camera access denied. Please enable it in Settings.'
                  : 'Photo library access denied. Please enable it in Settings.',
            );
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptScannerProvider);

    // Navigate to preview when result arrives
    ref.listen<ScannerState>(receiptScannerProvider, (prev, next) {
      if (next.hasResult && !(prev?.hasResult ?? false)) {
        context.push('/expenses/scan/preview', extra: next.result);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.isProcessing
                    ? _buildProcessing()
                    : state.hasError
                        ? _buildError(state.errorMessage!)
                        : _buildIdle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Scan Receipt',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Idle state ──────────────────────────────────────────────────────────

  Widget _buildIdle() {
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan your receipt',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or choose from your gallery.\nWe\'ll extract the details automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 44),
            _ScanButton(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              onTap: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 14),
            _ScanButton(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () => _pick(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Processing state ────────────────────────────────────────────────────

  Widget _buildProcessing() {
    return Center(
      key: const ValueKey('processing'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reading your receipt...',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Extracting receipt details...',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error state ─────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            _ScanButton(
              icon: Icons.refresh_rounded,
              label: 'Try Again',
              onTap: () =>
                  ref.read(receiptScannerProvider.notifier).reset(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/expenses/add'),
              child: Text(
                'Fill in Manually Instead',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable button ─────────────────────────────────────────────────────────

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
