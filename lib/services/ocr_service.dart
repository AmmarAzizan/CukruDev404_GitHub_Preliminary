import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_data.dart';

class OcrService {
  /// Extracts all text from the given image file path using ML Kit.
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  /// Full pipeline: OCR → parse → ReceiptData. Works fully offline.
  Future<ReceiptData> processReceipt(String imagePath) async {
    final text = await extractText(imagePath);
    final parsed = parseReceiptText(text);
    return ReceiptData.fromJson(parsed);
  }

  // ─── Parser ──────────────────────────────────────────────────────────────

  Map<String, dynamic> parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return {
      'amount': _extractAmount(text, lines),
      'merchant': _extractMerchant(lines),
      'date': _extractDate(text),
      'category': 'Others',
    };
  }

  // ── Amount ────────────────────────────────────────────────────────────────

  double _extractAmount(String text, List<String> lines) {
    final keywords = RegExp(
      r'(TOTAL|JUMLAH|AMOUNT|AMAUN|GRAND|SUBTOTAL|SUB-TOTAL|SUB TOTAL|RM|MYR)',
      caseSensitive: false,
    );

    // Phase 1: lines that contain a receipt total keyword
    double highest = 0;
    for (final line in lines) {
      if (!keywords.hasMatch(line)) continue;
      final nums = _numbersIn(line);
      for (final v in nums) {
        if (v > highest) highest = v;
      }
    }
    if (highest > 0) return highest;

    // Phase 2: fallback — largest decimal number in the whole text
    final nums = _numbersIn(text);
    for (final v in nums) {
      if (v > highest && v < 10000) highest = v;
    }
    return highest;
  }

  /// Finds all decimal numbers in [s], normalising comma-as-decimal.
  List<double> _numbersIn(String s) {
    final results = <double>[];
    // Matches: 1,234.50 | 1.234,50 | 25.50 | 25,50
    for (final m
        in RegExp(r'\d[\d,.]*\d|\d').allMatches(s)) {
      var raw = m.group(0)!;
      // Determine decimal separator: if last separator is comma, swap
      final lastComma = raw.lastIndexOf(',');
      final lastDot = raw.lastIndexOf('.');
      if (lastComma > lastDot) {
        // Comma is decimal separator (e.g. 25,50 or 1.234,50)
        raw = raw.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Dot is decimal separator (e.g. 25.50 or 1,234.50)
        raw = raw.replaceAll(',', '');
      }
      final v = double.tryParse(raw);
      if (v != null && v > 0) results.add(v);
    }
    return results;
  }

  // ── Merchant ──────────────────────────────────────────────────────────────

  String _extractMerchant(List<String> lines) {
    final skip = RegExp(
      r'^(RECEIPT|RESIT|INVOICE|TAX INVOICE|BILL|THANK YOU|TERIMA KASIH|'
      r'NO\.|TEL|FAX|DATE|TARIKH|TIME|MASA|GST|SST|REG|CASHIER)',
      caseSensitive: false,
    );

    for (final line in lines.take(8)) {
      if (line.length < 3 || line.length > 60) continue;
      if (skip.hasMatch(line)) continue;
      if (!line.contains(RegExp(r'[a-zA-Z]'))) continue;
      if (RegExp(r'^\d').hasMatch(line)) continue;

      final clean = line
          .replaceAll(RegExp(r"[^\w\s&\-'\.\@\/]"), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (clean.length >= 3) return clean;
    }
    return '';
  }

  // ── Date ─────────────────────────────────────────────────────────────────

  String _extractDate(String text) {
    // YYYY-MM-DD or YYYY/MM/DD
    final ymd =
        RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})');
    final ymatch = ymd.firstMatch(text);
    if (ymatch != null) {
      final y = int.parse(ymatch.group(1)!);
      final m = int.parse(ymatch.group(2)!);
      final d = int.parse(ymatch.group(3)!);
      if (y >= 2000 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return '${ymatch.group(1)!}-'
            '${ymatch.group(2)!.padLeft(2, '0')}-'
            '${ymatch.group(3)!.padLeft(2, '0')}';
      }
    }

    // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmy =
        RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})');
    final dmatch = dmy.firstMatch(text);
    if (dmatch != null) {
      final d = int.parse(dmatch.group(1)!);
      final m = int.parse(dmatch.group(2)!);
      final y = int.parse(dmatch.group(3)!);
      if (y >= 2000 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
        return '${dmatch.group(3)!}-'
            '${dmatch.group(2)!.padLeft(2, '0')}-'
            '${dmatch.group(1)!.padLeft(2, '0')}';
      }
    }

    // Default — today
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
