class ReceiptData {
  final double? amount;
  final String? merchant;
  final String? category;
  final DateTime? date;
  final String? imagePath;

  const ReceiptData({
    this.amount,
    this.merchant,
    this.category,
    this.date,
    this.imagePath,
  });

  static const _validCategories = [
    'Food', 'Transport', 'Entertainment',
    'Shopping', 'Education', 'Health', 'Others',
  ];

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    final rawCat = json['category'] as String?;
    final validCat =
        (_validCategories.contains(rawCat) ? rawCat : null);

    final rawAmount = json['amount'];
    final amount = rawAmount is num ? rawAmount.toDouble() : null;

    final rawDate = json['date'] as String?;
    DateTime? date;
    if (rawDate != null && rawDate.isNotEmpty) {
      date = DateTime.tryParse(rawDate);
    }

    return ReceiptData(
      amount: (amount != null && amount > 0) ? amount : null,
      merchant: _nonEmpty(json['merchant'] as String?),
      category: validCat,
      date: date,
    );
  }

  static String? _nonEmpty(String? s) =>
      (s != null && s.trim().isNotEmpty) ? s.trim() : null;

  ReceiptData copyWith({
    double? amount,
    String? merchant,
    String? category,
    DateTime? date,
    String? imagePath,
  }) =>
      ReceiptData(
        amount: amount ?? this.amount,
        merchant: merchant ?? this.merchant,
        category: category ?? this.category,
        date: date ?? this.date,
        imagePath: imagePath ?? this.imagePath,
      );
}
