import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt_data.dart';
import '../services/ocr_service.dart';

final ocrServiceProvider = Provider<OcrService>((_) => OcrService());

// ─── State ────────────────────────────────────────────────────────────────────

class ScannerState {
  final bool isProcessing;
  final String? errorMessage;
  final ReceiptData? result;

  const ScannerState({
    this.isProcessing = false,
    this.errorMessage,
    this.result,
  });

  bool get isIdle =>
      !isProcessing && errorMessage == null && result == null;
  bool get hasError => errorMessage != null;
  bool get hasResult => result != null;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ReceiptScannerNotifier extends StateNotifier<ScannerState> {
  ReceiptScannerNotifier({required OcrService ocr})
      : _ocr = ocr,
        super(const ScannerState());

  final OcrService _ocr;

  Future<void> processImage(String imagePath) async {
    state = const ScannerState(isProcessing: true);

    try {
      final data = await _ocr.processReceipt(imagePath);

      state = ScannerState(
        result: data.copyWith(imagePath: imagePath),
      );
    } catch (e) {
      debugPrint('[ReceiptScanner] Error: $e');
      state = ScannerState(
        errorMessage:
            'Could not read the receipt.\nPlease try a clearer photo.',
      );
    }
  }

  void reset() => state = const ScannerState();

  void setError(String message) =>
      state = ScannerState(errorMessage: message);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final receiptScannerProvider = StateNotifierProvider.autoDispose<
    ReceiptScannerNotifier, ScannerState>(
  (ref) => ReceiptScannerNotifier(ocr: ref.watch(ocrServiceProvider)),
);
